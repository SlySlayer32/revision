import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:developer';

/// Debug tool to check Firebase AI Logic setup
class FirebaseSetupChecker extends StatefulWidget {
  const FirebaseSetupChecker({super.key});

  @override
  State<FirebaseSetupChecker> createState() => _FirebaseSetupCheckerState();
}

class _FirebaseSetupCheckerState extends State<FirebaseSetupChecker> {
  String _results = 'Ready to check Firebase setup...';
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Setup Checker'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase AI Logic Setup Checker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isChecking ? null : _checkSetup,
              child: const Text('Check Firebase AI Setup'),
            ),
            const SizedBox(height: 20),
            
            if (_isChecking)
              const Center(child: CircularProgressIndicator()),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _results,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkSetup() async {
    setState(() {
      _isChecking = true;
      _results = 'Starting Firebase AI Logic setup check...\n\n';
    });

    try {
      // 1. Check Firebase initialization
      _appendResult('1. CHECKING FIREBASE INITIALIZATION');
      if (Firebase.apps.isEmpty) {
        _appendResult('❌ Firebase not initialized!');
        _appendResult('   Solution: Ensure Firebase.initializeApp() is called in main()');
        return;
      }
      _appendResult('✅ Firebase is initialized');
      
      // 2. Check Firebase AI Logic availability
      _appendResult('\n2. CHECKING FIREBASE AI LOGIC AVAILABILITY');
      try {
        final firebaseAI = FirebaseAI.googleAI();
        _appendResult('✅ FirebaseAI.googleAI() created successfully');
        
        // 3. Check model creation
        _appendResult('\n3. CHECKING MODEL CREATION');
        final model = firebaseAI.generativeModel(
          model: 'gemini-1.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 100,
          ),
        );
        _appendResult('✅ Gemini model instance created');
        
        // 4. Test actual API call
        _appendResult('\n4. TESTING API CONNECTIVITY');
        _appendResult('Making test API call to Gemini...');
        
        final response = await model.generateContent([
          Content.text('Say "Hello from Firebase AI!" if you can see this.')
        ]).timeout(const Duration(seconds: 30));
        
        if (response.text != null && response.text!.isNotEmpty) {
          _appendResult('✅ SUCCESS! API call completed');
          _appendResult('📝 Response: ${response.text}');
          _appendResult('\n🎉 FIREBASE AI LOGIC IS WORKING CORRECTLY!');
        } else {
          _appendResult('❌ API call returned empty response');
          _appendResult('   This suggests an API configuration issue');
        }
        
      } catch (e) {
        _appendResult('❌ API call failed: $e');
        _analyzeError(e.toString());
      }
      
    } catch (e) {
      _appendResult('❌ Setup check failed: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _analyzeError(String error) {
    _appendResult('\n🔍 ERROR ANALYSIS:');
    
    if (error.contains('API key') || error.contains('INVALID_ARGUMENT')) {
      _appendResult('❌ ISSUE: Gemini API Key Problem');
      _appendResult('💡 SOLUTIONS:');
      _appendResult('   1. Go to Firebase Console: https://console.firebase.google.com');
      _appendResult('   2. Select project: revision-464202');
      _appendResult('   3. Go to Build > Firebase AI Logic');
      _appendResult('   4. Click "Get Started" if not already done');
      _appendResult('   5. Select "Gemini Developer API"');
      _appendResult('   6. Verify setup completion');
      _appendResult('   7. Check that APIs are enabled:');
      _appendResult('      - Gemini Developer API (generativelanguage.googleapis.com)');
      _appendResult('      - Firebase AI Logic API (firebasevertexai.googleapis.com)');
      
    } else if (error.contains('PERMISSION_DENIED')) {
      _appendResult('❌ ISSUE: Permission Denied');
      _appendResult('💡 SOLUTIONS:');
      _appendResult('   1. Ensure Firebase AI Logic is properly enabled');
      _appendResult('   2. Check that your Firebase project has correct permissions');
      _appendResult('   3. Verify that your app is properly registered in Firebase');
      
    } else if (error.contains('quota') || error.contains('RESOURCE_EXHAUSTED')) {
      _appendResult('❌ ISSUE: API Quota Exceeded');
      _appendResult('💡 SOLUTIONS:');
      _appendResult('   1. Check your Gemini API quota in Google AI Studio');
      _appendResult('   2. You may have hit the free tier limit');
      _appendResult('   3. Wait for quota reset or upgrade to paid tier');
      
    } else if (error.contains('network') || error.contains('SocketException')) {
      _appendResult('❌ ISSUE: Network connectivity');
      _appendResult('💡 SOLUTIONS:');
      _appendResult('   1. Check internet connection');
      _appendResult('   2. Try again in a few moments');
      _appendResult('   3. Check if you are behind a firewall');
      
    } else {
      _appendResult('❌ ISSUE: Unknown error');
      _appendResult('💡 SOLUTIONS:');
      _appendResult('   1. Check Firebase AI Logic setup in console');
      _appendResult('   2. Verify all required APIs are enabled');
      _appendResult('   3. Contact Firebase support if issue persists');
    }
  }

  void _appendResult(String message) {
    setState(() {
      _results += '$message\n';
    });
    log(message);
  }
}
