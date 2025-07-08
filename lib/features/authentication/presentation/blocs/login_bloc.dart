import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'login_event.dart';
part 'login_state.dart';

/// BLoC responsible for handling login events and states
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Creates a new [LoginBloc]
  LoginBloc({
    required SignInUseCase signIn,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SendPasswordResetEmailUseCase sendPasswordResetEmail,
  }) : _signIn = signIn,
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
    
    // Initialize biometric availability
    _initializeBiometricAvailability();
  }

  final SignInUseCase _signIn;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  // Constants for security limits
  static const int _maxFailedAttempts = 5;
  static const int _maxRateLimitAttempts = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 15);
  static const Duration _lockoutDuration = Duration(minutes: 30);

  /// Initialize biometric availability
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
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Check if account is locked
      if (await _isAccountLocked(event.email)) {
        emit(state.copyWith(
          status: LoginStatus.accountLocked,
          errorMessage: 'Account locked due to too many failed attempts. Please try again later.',
        ));
        return;
      }

      // Check rate limiting
      if (SecurityUtils.isRateLimited(
        event.email,
        maxRequests: _maxRateLimitAttempts,
        window: _rateLimitWindow,
      )) {
        emit(state.copyWith(
          status: LoginStatus.rateLimited,
          errorMessage: 'Too many login attempts. Please try again later.',
          isRateLimited: true,
        ));
        return;
      }

      // Sanitize inputs
      final sanitizedEmail = SecurityUtils.sanitizeInput(event.email);
      final sanitizedPassword = SecurityUtils.sanitizeInput(event.password);

      // Validate email format
      if (!SecurityUtils.isValidEmail(sanitizedEmail)) {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Please enter a valid email address.',
        ));
        return;
      }

      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _signIn(
        SignInParams(email: sanitizedEmail, password: sanitizedPassword),
      );
      
      result.fold(
        (failure) async {
          log('Login error', error: failure);
          
          // Increment failed attempts
          final newFailedAttempts = state.failedAttempts + 1;
          final shouldShowCaptcha = newFailedAttempts >= 3;
          
          // Check if account should be locked
          if (newFailedAttempts >= _maxFailedAttempts) {
            await _lockAccount(sanitizedEmail);
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
          // Reset failed attempts on successful login
          await _clearFailedAttempts(sanitizedEmail);
          
          // Save login state if remember me is enabled
          if (state.rememberMe) {
            await _saveLoginState(sanitizedEmail);
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
      log('Unexpected login error', error: e);
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'An unexpected error occurred',
      ));
    }
  }

  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _signInWithGoogle();
      result.fold((failure) {
        log('Google login error', error: failure);
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: failure.message,
          ),
        );
      }, (user) => emit(state.copyWith(status: LoginStatus.success)));
    } catch (e) {
      log('Unexpected Google login error', error: e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'An unexpected error occurred',
        ),
      );
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      // Sanitize email input
      final sanitizedEmail = SecurityUtils.sanitizeInput(event.email);

      final result = await _sendPasswordResetEmail(sanitizedEmail);
      result.fold(
        (failure) {
          log('Password reset error', error: failure);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        (_) {
          emit(
            state.copyWith(
              status: LoginStatus.success,
              errorMessage: 'Password reset email sent',
            ),
          );
        },
      );
    } catch (e) {
      log('Unexpected password reset error', error: e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'An unexpected error occurred',
        ),
      );
    }
  }

  /// Handle biometric login request
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
          // Use stored credentials for login
          final result = await _signIn(
            SignInParams(email: storedEmail, password: storedPassword),
          );
          
          result.fold(
            (failure) {
              log('Biometric login error', error: failure);
              emit(state.copyWith(
                status: LoginStatus.failure,
                errorMessage: failure.message,
              ));
            },
            (user) {
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
      log('Biometric authentication error', error: e);
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Biometric authentication error',
      ));
    }
  }

  /// Handle password strength check
  Future<void> _onPasswordStrengthChecked(
    PasswordStrengthChecked event,
    Emitter<LoginState> emit,
  ) async {
    final strength = SecurityUtils.validatePasswordStrength(event.password);
    emit(state.copyWith(passwordStrength: strength));
  }

  /// Helper methods for security features
  Future<bool> _isAccountLocked(String email) async {
    final lockTimestamp = await _secureStorage.read(key: 'account_lock_$email');
    if (lockTimestamp != null) {
      final lockTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lockTimestamp));
      final now = DateTime.now();
      return now.difference(lockTime) < _lockoutDuration;
    }
    return false;
  }

  Future<void> _lockAccount(String email) async {
    final lockTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'account_lock_$email', value: lockTimestamp);
  }

  Future<void> _clearFailedAttempts(String email) async {
    await _secureStorage.delete(key: 'failed_attempts_$email');
    await _secureStorage.delete(key: 'account_lock_$email');
  }

  Future<void> _saveLoginState(String email) async {
    await _secureStorage.write(key: 'stored_email', value: email);
    await _secureStorage.write(key: 'remember_me', value: 'true');
  }
}
