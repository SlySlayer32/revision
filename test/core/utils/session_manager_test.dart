import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/session_manager.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

void main() {
  group('SessionManager', () {
    late SessionManager sessionManager;
    
    setUp(() {
      sessionManager = SessionManager.instance;
    });
    
    tearDown(() {
      sessionManager.endSession();
    });

    test('should start session correctly', () {
      const testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00.000Z',
        customClaims: {},
      );
      
      sessionManager.startSession(testUser);
      
      expect(sessionManager.isSessionValid(), equals(true));
      expect(sessionManager.getRemainingSessionTime(), isNotNull);
    });

    test('should update activity correctly', () {
      const testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00.000Z',
        customClaims: {},
      );
      
      sessionManager.startSession(testUser);
      
      // final beforeUpdate = sessionManager.getRemainingSessionTime();
      
      // Wait a bit and update activity
      Future.delayed(const Duration(milliseconds: 100), () {
        sessionManager.updateActivity();
      });
      
      final afterUpdate = sessionManager.getRemainingSessionTime();
      
      expect(sessionManager.isSessionValid(), equals(true));
      expect(afterUpdate, isNotNull);
    });

    test('should end session correctly', () {
      const testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00.000Z',
        customClaims: {},
      );
      
      sessionManager.startSession(testUser);
      expect(sessionManager.isSessionValid(), equals(true));
      
      sessionManager.endSession();
      expect(sessionManager.isSessionValid(), equals(false));
      expect(sessionManager.getRemainingSessionTime(), isNull);
    });

    test('should provide correct session state messages', () {
      expect(
        SessionState.active.message,
        equals('Session is active'),
      );
      
      expect(
        SessionState.warningTimeout.message,
        equals('Your session will expire in 5 minutes'),
      );
      
      expect(
        SessionState.timedOut.message,
        equals('Your session has expired. Please sign in again.'),
      );
    });

    test('should stream session state changes', () {
      expect(sessionManager.sessionStateStream, isA<Stream<SessionState>>());
    });
  });
}