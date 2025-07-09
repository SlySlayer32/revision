import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences and app settings
class PreferencesService {
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyAutoSave = 'auto_save';
  static const String _keyQualityPreference = 'quality_preference';
  static const String _keyNotifications = 'notifications';
  static const String _keyEmailVisibility = 'email_visibility';
  static const String _keyLastSessionTime = 'last_session_time';
  static const String _keySessionTimeout = 'session_timeout';

  static SharedPreferences? _preferences;

  /// Initialize preferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Get theme preference
  static String getTheme() {
    return _preferences?.getString(_keyTheme) ?? 'system';
  }

  /// Set theme preference
  static Future<void> setTheme(String theme) async {
    await _preferences?.setString(_keyTheme, theme);
  }

  /// Get language preference
  static String getLanguage() {
    return _preferences?.getString(_keyLanguage) ?? 'en';
  }

  /// Set language preference
  static Future<void> setLanguage(String language) async {
    await _preferences?.setString(_keyLanguage, language);
  }

  /// Get auto-save preference
  static bool getAutoSave() {
    return _preferences?.getBool(_keyAutoSave) ?? true;
  }

  /// Set auto-save preference
  static Future<void> setAutoSave(bool autoSave) async {
    await _preferences?.setBool(_keyAutoSave, autoSave);
  }

  /// Get quality preference
  static String getQualityPreference() {
    return _preferences?.getString(_keyQualityPreference) ?? 'high';
  }

  /// Set quality preference
  static Future<void> setQualityPreference(String quality) async {
    await _preferences?.setString(_keyQualityPreference, quality);
  }

  /// Get notifications preference
  static bool getNotifications() {
    return _preferences?.getBool(_keyNotifications) ?? true;
  }

  /// Set notifications preference
  static Future<void> setNotifications(bool notifications) async {
    await _preferences?.setBool(_keyNotifications, notifications);
  }

  /// Get email visibility preference
  static bool getEmailVisibility() {
    return _preferences?.getBool(_keyEmailVisibility) ?? true;
  }

  /// Set email visibility preference
  static Future<void> setEmailVisibility(bool visible) async {
    await _preferences?.setBool(_keyEmailVisibility, visible);
  }

  /// Get last session time
  static int getLastSessionTime() {
    return _preferences?.getInt(_keyLastSessionTime) ?? 0;
  }

  /// Set last session time
  static Future<void> setLastSessionTime(int timestamp) async {
    await _preferences?.setInt(_keyLastSessionTime, timestamp);
  }

  /// Get session timeout (in minutes)
  static int getSessionTimeout() {
    return _preferences?.getInt(_keySessionTimeout) ?? 30;
  }

  /// Set session timeout (in minutes)
  static Future<void> setSessionTimeout(int minutes) async {
    await _preferences?.setInt(_keySessionTimeout, minutes);
  }

  /// Check if session is expired
  static bool isSessionExpired() {
    final lastSessionTime = getLastSessionTime();
    final timeoutMinutes = getSessionTimeout();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final sessionExpiry = lastSessionTime + (timeoutMinutes * 60 * 1000);
    return currentTime > sessionExpiry;
  }

  /// Update session activity
  static Future<void> updateSessionActivity() async {
    await setLastSessionTime(DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear all preferences
  static Future<void> clearAll() async {
    await _preferences?.clear();
  }
}