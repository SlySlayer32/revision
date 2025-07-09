import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required SignInUseCase signIn,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SendPasswordResetEmailUseCase sendPasswordResetEmail,
  })  : _signIn = signIn,
        _signInWithGoogle = signInWithGoogle,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        _localAuth = LocalAuthentication(),
        _secureStorage = const FlutterSecureStorage(),
        super(const LoginState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
    on<PasswordStrengthChecked>(_onPasswordStrengthChecked);

    _initializeBiometricAvailability();
  }

  final SignInUseCase _signIn;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  // Advanced Security Constants
  static const int _maxFailedAttempts = 5;
  static const int _maxRateLimitAttempts = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 15);
  static const Duration _lockoutDuration = Duration(minutes: 30);

  // Biometric
  Future<void> _initializeBiometricAvailability() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (isAvailable && isDeviceSupported) {
        final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          emit(state.copyWith(biometricAvailable: true));
        }
      }
    } catch (e) {
      log('Error checking biometric availability: $e');
    }
  }

  // LOGIN
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Advanced: Check account lock
      if (await _isAccountLocked(event.email)) {
        emit(state.copyWith(
          status: LoginStatus.accountLocked,
          errorMessage: 'Account locked due to too many failed attempts. Please try again later.',
        ));
        return;
      }

      // Advanced: Rate limiting for brute-force protection
      if (await _isRateLimited(event.email)) {
        emit(state.copyWith(
          status: LoginStatus.rateLimited,
          errorMessage: 'Too many login attempts. Please try again later.',
          isRateLimited: true,
        ));
        return;
      }

      emit(state.copyWith(status: LoginStatus.loading));

      final result = await AuthSecurityUtils.withAuthTimeout(
        _signIn(SignInParams(email: event.email, password: event.password)),
        'login',
      );

      await result.fold(
        (failure) async {
          AuthSecurityUtils.logAuthError('Login failed', failure);

          // Advanced: Increment failed attempts
          final newFailedAttempts = await _incrementFailedAttempts(event.email);
          final shouldShowCaptcha = newFailedAttempts >= 3;

          // Advanced: Lock account if needed
          if (newFailedAttempts >= _maxFailedAttempts) {
            await _lockAccount(event.email);
            emit(state.copyWith(
              status: LoginStatus.accountLocked,
              errorMessage: 'Account locked due to too many failed attempts.',
              failedAttempts: newFailedAttempts,
            ));
          } else {
            emit(state.copyWith(
              status: shouldShowCaptcha ? LoginStatus.captchaRequired : LoginStatus.failure,
              errorMessage: failure.message,
              failedAttempts: newFailedAttempts,
              showCaptcha: shouldShowCaptcha,
            ));
          }
        },
        (user) async {
          AuthSecurityUtils.logAuthEvent('Login successful', user: user);
          // Advanced: Reset failed attempts on success
          await _clearFailedAttempts(event.email);

          // Save login state if rememberMe is enabled
          if (state.rememberMe) {
            await _saveLoginState(event.email, event.password);
          }

          emit(state.copyWith(
            status: LoginStatus.success,
            failedAttempts: 0,
            showCaptcha: false,
            isRateLimited: false,
          ));
        },
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Login error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }

  // GOOGLE LOGIN
  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));
      final result = await AuthSecurityUtils.withAuthTimeout(
        _signInWithGoogle(),
        'google_login',
      );
      result.fold((failure) {
        AuthSecurityUtils.logAuthError('Google login failed', failure);
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: failure.message,
          ),
        );
      }, (user) {
        AuthSecurityUtils.logAuthEvent('Google login successful', user: user);
        emit(state.copyWith(status: LoginStatus.success));
      });
    } catch (e) {
      AuthSecurityUtils.logAuthError('Google login error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }

  // PASSWORD RESET
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Advanced: Rate limiting for password reset
      if (await _isRateLimited('password_reset_${event.email}')) {
        AuthSecurityUtils.logAuthError(
          'Password reset rate limited',
          Exception('Rate limit exceeded'),
          data: {'email': event.email},
        );
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Too many password reset attempts. Please try again later.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: LoginStatus.loading));

      final result = await AuthSecurityUtils.withAuthTimeout(
        _sendPasswordResetEmail(event.email),
        'password_reset',
      );

      result.fold(
        (failure) {
          AuthSecurityUtils.logAuthError('Password reset failed', failure);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        (_) {
          AuthSecurityUtils.logAuthEvent('Password reset sent');
          emit(
            state.copyWith(
              status: LoginStatus.success,
              errorMessage: 'Password reset email sent',
            ),
          );
        },
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Password reset error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }

  // BIOMETRIC LOGIN
  Future<void> _onBiometricLoginRequested(
    BiometricLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Retrieve stored credentials
        final storedEmail = await _secureStorage.read(key: 'stored_email');
        final storedPassword = await _secureStorage.read(key: 'stored_password');

        if (storedEmail != null && storedPassword != null) {
          final result = await AuthSecurityUtils.withAuthTimeout(
            _signIn(SignInParams(email: storedEmail, password: storedPassword)),
            'biometric_login',
          );
          result.fold(
            (failure) {
              AuthSecurityUtils.logAuthError('Biometric login failed', failure);
              emit(state.copyWith(
                status: LoginStatus.failure,
                errorMessage: failure.message,
              ));
            },
            (user) {
              AuthSecurityUtils.logAuthEvent('Biometric login successful', user: user);
              emit(state.copyWith(status: LoginStatus.success));
            },
          );
        } else {
          emit(state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'No stored credentials found. Please log in manually first.',
          ));
        }
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Biometric authentication failed',
        ));
      }
    } catch (e) {
      AuthSecurityUtils.logAuthError('Biometric authentication error', e);
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Biometric authentication error',
      ));
    }
  }

  // PASSWORD STRENGTH CHECK
  Future<void> _onPasswordStrengthChecked(
    PasswordStrengthChecked event,
    Emitter<LoginState> emit,
  ) async {
    final strength = AuthSecurityUtils.validatePasswordStrength(event.password);
    emit(state.copyWith(passwordStrength: strength));
  }

  // ==== ADVANCED SECURITY METHODS ====

  /// Check if account is currently locked
  Future<bool> _isAccountLocked(String email) async {
    final lockTimestamp = await _secureStorage.read(key: 'account_lock_$email');
    if (lockTimestamp != null) {
      final lockTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lockTimestamp));
      final now = DateTime.now();
      return now.difference(lockTime) < _lockoutDuration;
    }
    return false;
  }

  /// Lock the account
  Future<void> _lockAccount(String email) async {
    final lockTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'account_lock_$email', value: lockTimestamp);
  }

  /// Increment and get failed login attempts
  Future<int> _incrementFailedAttempts(String email) async {
    final attemptsString = await _secureStorage.read(key: 'failed_attempts_$email');
    int attempts = attemptsString != null ? int.tryParse(attemptsString) ?? 0 : 0;
    attempts++;
    await _secureStorage.write(key: 'failed_attempts_$email', value: attempts.toString());
    return attempts;
  }

  /// Clear failed attempts and unlock account
  Future<void> _clearFailedAttempts(String email) async {
    await _secureStorage.delete(key: 'failed_attempts_$email');
    await _secureStorage.delete(key: 'account_lock_$email');
  }

  /// Save login state (with password, for biometrics)
  Future<void> _saveLoginState(String email, String password) async {
    await _secureStorage.write(key: 'stored_email', value: email);
    await _secureStorage.write(key: 'stored_password', value: password);
    await _secureStorage.write(key: 'remember_me', value: 'true');
  }

  /// Rate limiting using secure storage time window
  Future<bool> _isRateLimited(String key) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowKey = 'rate_limit_window_$key';
    final countKey = 'rate_limit_count_$key';

    final windowStartString = await _secureStorage.read(key: windowKey);
    final countString = await _secureStorage.read(key: countKey);
    int count = countString != null ? int.tryParse(countString) ?? 0 : 0;
    int windowStart = windowStartString != null ? int.tryParse(windowStartString) ?? 0 : 0;

    if (windowStart == 0 || now - windowStart > _rateLimitWindow.inMilliseconds) {
      // Reset window
      await _secureStorage.write(key: windowKey, value: now.toString());
      await _secureStorage.write(key: countKey, value: '1');
      return false;
    } else {
      count++;
      await _secureStorage.write(key: countKey, value: count.toString());
      if (count > _maxRateLimitAttempts) {
        return true;
      }
      return false;
    }
  }
}