import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/services/gemini_ai_service.dart';

/// Firebase AI Logic Demo Widget with Remote Config
/// 
/// This widget demonstrates how to use Firebase AI Logic with Gemini Developer API
/// and Firebase Remote Config for dynamic parameter control.
/// 
/// Key features:
/// - Uses Firebase-managed API keys (no .env required)
/// - Dynamic configuration via Firebase Remote Config
/// - Real-time parameter updates from Firebase Console
/// - Shows both text generation and configuration debugging
/// - Ready for integration into your app features
class FirebaseAIDemoWidget extends StatefulWidget {
  const FirebaseAIDemoWidget({super.key});

  @override
  State<FirebaseAIDemoWidget> createState() => _FirebaseAIDemoWidgetState();
}

class _FirebaseAIDemoWidgetState extends State<FirebaseAIDemoWidget> {
  late final GeminiAIService _geminiService;
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  String _status = 'Ready to test Firebase AI Logic with Remote Config';
  Map<String, dynamic> _configValues = {};

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAI();
  }

  void _initializeFirebaseAI() {
    try {
      // Get the Gemini AI service from service locator
      // This service now uses Remote Config for dynamic parameter control
      _geminiService = GetIt.instance<GeminiAIService>();
      
      // Load current Remote Config values for display
      _refreshConfigValues();
      
      setState(() {
        _status = '✅ Firebase AI Logic with Remote Config initialized';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Initialization failed: $e';
      });
    }
  }

  void _refreshConfigValues() {
    setState(() {
      _configValues = _geminiService.getConfigDebugInfo();
    });
  }
      );
      
      setState(() {
        _status = '✅ Firebase AI Logic initialized successfully!';
      });
      
      debugPrint('🎯 Firebase AI Logic setup completed');
      debugPrint('🔑 API key source: Firebase Console configuration');
    } catch (e) {
      setState(() {
        _status = '❌ Initialization failed: $e';
      });
      debugPrint('❌ Firebase AI Logic initialization failed: $e');
    }
  }

  Future<void> _sendPrompt() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
      _status = 'Sending request to Gemini...';
    });

    try {
      // Step 3: Send a prompt request to the model
      // This follows the exact Firebase AI Logic documentation pattern
      final prompt = _promptController.text.trim();
      debugPrint('📝 Sending prompt: "$prompt"');
      
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        setState(() {
          _response = response.text!;
          _status = '✅ Response received successfully!';
        });
        debugPrint('✅ API call successful');
      } else {
        setState(() {
          _response = 'No response received from the model.';
          _status = '⚠️ Empty response received';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _status = '❌ Request failed';
      });
      debugPrint('❌ API call failed: $e');
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get response: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase AI Logic Demo'),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color: _status.startsWith('✅') 
                  ? Colors.green[50] 
                  : _status.startsWith('❌') 
                      ? Colors.red[50] 
                      : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Prompt input
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt',
                hintText: 'e.g., "Write a short story about a magic backpack"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Send button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendPrompt,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Sending...' : 'Send to Gemini'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Response area
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _response.isEmpty ? 'No response yet...' : _response,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Instructions
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 How this works:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Uses Firebase AI Logic with Gemini Developer API'),
                    Text('2. API key is managed by Firebase Console (not .env)'),
                    Text('3. Follows official Firebase AI Logic documentation'),
                    Text('4. Ready for integration into your app features'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
