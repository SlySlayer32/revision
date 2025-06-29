import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:developer';

/// Debug tool to check Firebase AI configuration specifically
class FirebaseAIConfigChecker extends StatefulWidget {
  const FirebaseAIConfigChecker({super.key});

  @override
  State<FirebaseAIConfigChecker> createState() => _FirebaseAIConfigCheckerState();
}

class _FirebaseAIConfigCheckerState extends State<FirebaseAIConfigChecker> {
  String _results = 'Ready to check Firebase AI configuration...';
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase AI Config Checker'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase AI Configuration Checker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isChecking ? null : _checkConfiguration,
              child: const Text('Check Firebase AI Configuration'),
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

  Future<void> _checkConfiguration() async {
    setState(() {
      _isChecking = true;
      _results = 'Checking Firebase AI configuration step by step...\n\n';
    });

    try {
      // Step 1: Try to create Firebase AI instance
      _appendResult('1. TESTING FIREBASE AI INSTANCE CREATION');
      try {
        final firebaseAI = FirebaseAI.googleAI();
        _appendResult('✅ FirebaseAI.googleAI() created successfully');
        
        // Step 2: Try to create model WITHOUT calling any APIs
        _appendResult('\n2. TESTING MODEL CREATION (NO API CALLS)');
        try {
          final model = firebaseAI.generativeModel(
            model: 'gemini-1.5-flash',
            generationConfig: GenerationConfig(
              temperature: 0.4,
              maxOutputTokens: 50,
            ),
          );
          _appendResult('✅ Model instance created successfully');
          _appendResult('   Model: ${model.toString()}');
          
          // Step 3: Try a minimal API call to test connectivity
          _appendResult('\n3. TESTING MINIMAL API CALL');
          _appendResult('Making the smallest possible API call...');
          
          try {
            final response = await model.generateContent([
              Content.text('Hi')
            ]).timeout(const Duration(seconds: 15));
            
            if (response.text != null && response.text!.isNotEmpty) {
              _appendResult('✅ SUCCESS! API call worked');
              _appendResult('Response: ${response.text}');
              _appendResult('\n🎉 FIREBASE AI IS WORKING CORRECTLY!');
            } else {
              _appendResult('❌ API call returned empty response');
              _appendResult('This suggests API key or configuration issue');
            }
            
          } catch (apiError) {
            _appendResult('❌ API call failed: $apiError');
            _analyzeAPIError(apiError.toString());
          }
          
        } catch (modelError) {
          _appendResult('❌ Model creation failed: $modelError');
          _appendResult('This suggests Firebase AI service configuration issue');
        }
        
      } catch (instanceError) {
        _appendResult('❌ Firebase AI instance creation failed: $instanceError');
        _appendResult('This suggests fundamental Firebase setup issue');
      }
      
    } catch (e) {
      _appendResult('❌ Configuration check failed: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _analyzeAPIError(String error) {
    _appendResult('\n🔍 API ERROR ANALYSIS:');
    
    if (error.contains('API key') || 
        error.contains('INVALID_ARGUMENT') || 
        error.contains('invalid') ||
        error.contains('unauthorized')) {
      _appendResult('❌ ISSUE: API Key Problem');
      _appendResult('💡 SOLUTION:');
      _appendResult('   1. In Google Cloud Console → APIs & Services → Credentials');
      _appendResult('   2. Find "Gemini Developer API key (auto created by Firebase)"');
      _appendResult('   3. Edit the key and set API restrictions to:');
      _appendResult('      - Restrict key: YES');
      _appendResult('      - Select only: Generative Language API');
      _appendResult('   4. Save the key');
      _appendResult('   5. Wait 2-3 minutes for changes to propagate');
      
    } else if (error.contains('PERMISSION_DENIED')) {
      _appendResult('❌ ISSUE: Permission Denied');
      _appendResult('💡 SOLUTION:');
      _appendResult('   1. Check Firebase AI Logic is enabled in Firebase Console');
      _appendResult('   2. Verify APIs are enabled:');
      _appendResult('      - Generative Language API');
      _appendResult('      - Firebase AI Logic API');
      
    } else if (error.contains('quota') || error.contains('RESOURCE_EXHAUSTED')) {
      _appendResult('❌ ISSUE: Quota Exceeded');
      _appendResult('💡 SOLUTION:');
      _appendResult('   1. Check your API quota in Google AI Studio');
      _appendResult('   2. Wait for quota reset or upgrade plan');
      
    } else if (error.contains('FAILED_PRECONDITION')) {
      _appendResult('❌ ISSUE: Service Not Properly Configured');
      _appendResult('💡 SOLUTION:');
      _appendResult('   1. Go to Firebase Console → Firebase AI Logic');
      _appendResult('   2. Re-run the setup process');
      _appendResult('   3. Ensure Gemini Developer API is selected');
      
    } else {
      _appendResult('❌ ISSUE: Unknown API Error');
      _appendResult('💡 SOLUTION:');
      _appendResult('   1. Check Firebase AI Logic setup in console');
      _appendResult('   2. Verify API key restrictions are correct');
      _appendResult('   3. Wait a few minutes and try again');
    }
  }

  void _appendResult(String message) {
    setState(() {
      _results += '$message\n';
    });
    log(message);
  }
}
