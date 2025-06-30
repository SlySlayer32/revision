import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Debug script to test Firebase Remote Config
class RemoteConfigDebugTester {
  static Future<void> testRemoteConfig() async {
    try {
      log('🔧 Starting Firebase Remote Config Debug Test...');
      
      // Test 1: Initialize Remote Config
      log('Step 1: Getting Remote Config instance...');
      final remoteConfig = FirebaseRemoteConfig.instance;
      log('✅ Remote Config instance obtained');
      
      // Test 2: Check current status
      log('Step 2: Checking Remote Config status...');
      log('Last fetch status: ${remoteConfig.lastFetchStatus}');
      log('Last fetch time: ${remoteConfig.lastFetchTime}');
      
      // Test 3: Set minimal config
      log('Step 3: Setting config settings...');
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      log('✅ Config settings applied');
      
      // Test 4: Set defaults
      log('Step 4: Setting default values...');
      await remoteConfig.setDefaults({
        'ai_gemini_model': 'gemini-1.5-flash',
        'ai_gemini_image_model': 'gemini-1.5-flash',
        'ai_temperature': 0.4,
        'ai_max_output_tokens': 1024,
      });
      log('✅ Default values set');
      
      // Test 5: Try to fetch
      log('Step 5: Attempting to fetch remote values...');
      try {
        final success = await remoteConfig.fetchAndActivate();
        log('✅ Fetch result: $success');
        
        // Test 6: Read values
        log('Step 6: Reading configuration values...');
        final geminiModel = remoteConfig.getString('ai_gemini_model');
        final geminiImageModel = remoteConfig.getString('ai_gemini_image_model');
        final temperature = remoteConfig.getDouble('ai_temperature');
        
        log('📋 Configuration Values:');
        log('   Gemini Model: $geminiModel');
        log('   Gemini Image Model: $geminiImageModel');
        log('   Temperature: $temperature');
        
        if (geminiModel.isNotEmpty && geminiImageModel.isNotEmpty) {
          log('✅ SUCCESS: Remote Config is working correctly');
        } else {
          log('⚠️ WARNING: Remote Config values are empty');
        }
        
      } catch (fetchError) {
        log('⚠️ Fetch failed, using defaults: $fetchError');
        
        // Still try to read default values
        final geminiModel = remoteConfig.getString('ai_gemini_model');
        final geminiImageModel = remoteConfig.getString('ai_gemini_image_model');
        
        log('📋 Default Values:');
        log('   Gemini Model: $geminiModel');
        log('   Gemini Image Model: $geminiImageModel');
        
        if (geminiModel.isNotEmpty && geminiImageModel.isNotEmpty) {
          log('✅ Using defaults successfully');
        } else {
          log('🚨 CRITICAL: Even defaults are not working');
        }
      }
      
    } catch (e, stackTrace) {
      log('🚨 REMOTE CONFIG TEST FAILED: $e');
      log('Error Type: ${e.runtimeType}');
      log('Stack Trace: $stackTrace');
      
      // Provide specific guidance
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') || errorString.contains('timeout')) {
        log('💡 DIAGNOSIS: Network issue - check internet connection and Firebase hosting');
      } else if (errorString.contains('permission') || errorString.contains('auth')) {
        log('💡 DIAGNOSIS: Permission issue - check Firebase project permissions');
      } else if (errorString.contains('not found') || errorString.contains('404')) {
        log('💡 DIAGNOSIS: Remote Config not set up - check Firebase Console Remote Config');
      } else {
        log('💡 DIAGNOSIS: General Remote Config issue - check Firebase project configuration');
      }
    }
  }
}
