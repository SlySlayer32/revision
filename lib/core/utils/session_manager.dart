import 'dart:async';

import 'package:flutter/services.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

/// Manages user session state and timeout handling
class SessionManager {
  SessionManager._();
  
  static final SessionManager _instance = SessionManager._();
  static SessionManager get instance => _instance;

  DateTime? _lastActivity;
  Timer? _sessionTimer;
  StreamController<SessionState>? _sessionStateController;

  /// Stream of session state changes
  Stream<SessionState> get sessionStateStream {
    _sessionStateController ??= StreamController<SessionState>.broadcast();
    return _sessionStateController!.stream;
  }

  /// Updates the last activity timestamp
  void updateActivity() {
    _lastActivity = DateTime.now();
    _resetSessionTimer();
  }

  /// Starts session monitoring for the given user
  void startSession(User user) {
    AuthSecurityUtils.logAuthEvent(
      'Session started',
      user: user,
    );
    
    _lastActivity = DateTime.now();
    _resetSessionTimer();
    
    // Listen for app lifecycle changes
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == 'AppLifecycleState.resumed') {
        updateActivity();
      }
      return null;
    });
  }

  /// Ends the current session
  void endSession() {
    AuthSecurityUtils.logAuthEvent('Session ended');
    
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _lastActivity = null;
    
    _sessionStateController?.add(SessionState.ended);
  }

  /// Checks if the current session is still valid
  bool isSessionValid() {
    if (_lastActivity == null) return false;
    return !AuthSecurityUtils.isSessionTimedOut(_lastActivity);
  }

  /// Gets the remaining session time
  Duration? getRemainingSessionTime() {
    if (_lastActivity == null) return null;
    
    const sessionDuration = Duration(minutes: 30);
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = sessionDuration - elapsed;
    
    return remaining.isNegative ? null : remaining;
  }

  /// Resets the session timer
  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    
    const sessionDuration = Duration(minutes: 30);
    _sessionTimer = Timer(sessionDuration, () {
      AuthSecurityUtils.logAuthEvent('Session timeout');
      _sessionStateController?.add(SessionState.timedOut);
    });
    
    // Warn user 5 minutes before timeout
    const warningTime = Duration(minutes: 25);
    Timer(warningTime, () {
      if (isSessionValid()) {
        _sessionStateController?.add(SessionState.warningTimeout);
      }
    });
  }

  /// Disposes the session manager
  void dispose() {
    _sessionTimer?.cancel();
    _sessionStateController?.close();
  }
}

/// Represents different session states
enum SessionState {
  active,
  warningTimeout,
  timedOut,
  ended;

  /// Gets user-friendly message for the session state
  String get message {
    switch (this) {
      case SessionState.active:
        return 'Session is active';
      case SessionState.warningTimeout:
        return 'Your session will expire in 5 minutes';
      case SessionState.timedOut:
        return 'Your session has expired. Please sign in again.';
      case SessionState.ended:
        return 'Session ended';
    }
  }
}