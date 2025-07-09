import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revision/core/services/preferences_service.dart';

void main() {
  group('PreferencesService', () {
    setUp(() {
      // Clear any existing mock data
      SharedPreferences.setMockInitialValues({});
    });

    group('initialization', () {
      test('init() initializes SharedPreferences', () async {
        await PreferencesService.init();
        // If no exception is thrown, initialization was successful
      });
    });

    group('theme preferences', () {
      test('getTheme() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getTheme(), 'system');
      });

      test('setTheme() and getTheme() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setTheme('dark');
        expect(PreferencesService.getTheme(), 'dark');
      });
    });

    group('email visibility preferences', () {
      test('getEmailVisibility() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getEmailVisibility(), true);
      });

      test('setEmailVisibility() and getEmailVisibility() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setEmailVisibility(false);
        expect(PreferencesService.getEmailVisibility(), false);
      });
    });

    group('session management', () {
      test('getLastSessionTime() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getLastSessionTime(), 0);
      });

      test('updateSessionActivity() updates last session time', () async {
        await PreferencesService.init();
        await PreferencesService.updateSessionActivity();
        expect(PreferencesService.getLastSessionTime(), greaterThan(0));
      });

      test('getSessionTimeout() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getSessionTimeout(), 30);
      });

      test('isSessionExpired() works correctly', () async {
        await PreferencesService.init();
        
        // Set a very old session time
        await PreferencesService.setLastSessionTime(
          DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000), // 1 hour ago
        );
        await PreferencesService.setSessionTimeout(30); // 30 minutes timeout
        
        expect(PreferencesService.isSessionExpired(), true);
        
        // Set a recent session time
        await PreferencesService.updateSessionActivity();
        expect(PreferencesService.isSessionExpired(), false);
      });
    });

    group('auto-save preferences', () {
      test('getAutoSave() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getAutoSave(), true);
      });

      test('setAutoSave() and getAutoSave() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setAutoSave(false);
        expect(PreferencesService.getAutoSave(), false);
      });
    });

    group('notifications preferences', () {
      test('getNotifications() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getNotifications(), true);
      });

      test('setNotifications() and getNotifications() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setNotifications(false);
        expect(PreferencesService.getNotifications(), false);
      });
    });

    group('quality preferences', () {
      test('getQualityPreference() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getQualityPreference(), 'high');
      });

      test('setQualityPreference() and getQualityPreference() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setQualityPreference('medium');
        expect(PreferencesService.getQualityPreference(), 'medium');
      });
    });

    group('language preferences', () {
      test('getLanguage() returns default value when not set', () async {
        await PreferencesService.init();
        expect(PreferencesService.getLanguage(), 'en');
      });

      test('setLanguage() and getLanguage() work correctly', () async {
        await PreferencesService.init();
        await PreferencesService.setLanguage('es');
        expect(PreferencesService.getLanguage(), 'es');
      });
    });

    group('clear preferences', () {
      test('clearAll() clears all preferences', () async {
        await PreferencesService.init();
        await PreferencesService.setTheme('dark');
        await PreferencesService.setEmailVisibility(false);
        await PreferencesService.clearAll();
        
        expect(PreferencesService.getTheme(), 'system');
        expect(PreferencesService.getEmailVisibility(), true);
      });
    });
  });
}