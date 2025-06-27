import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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

  Future<void> _generateContent() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
      _status = 'Sending request to Gemini via Remote Config...';
    });

    try {
      // Use the Gemini AI service which now uses Remote Config parameters
      final prompt = _promptController.text.trim();
      
      // This call now uses the current Remote Config values for:
      // - Model selection, temperature, tokens, etc.
      // - System instructions and prompts
      // - Timeout values
      final response = await _geminiService.processTextPrompt(prompt);

      setState(() {
        _response = response;
        _status = '✅ Response received using Remote Config parameters';
        _isLoading = false;
      });
      
      // Refresh config values to show what was actually used
      _refreshConfigValues();
      
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _status = '❌ Request failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRemoteConfig() async {
    setState(() {
      _status = 'Refreshing Remote Config from Firebase Console...';
    });

    try {
      await _geminiService.refreshConfig();
      _refreshConfigValues();
      
      setState(() {
        _status = '✅ Remote Config refreshed successfully';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remote Config updated! Changes will apply to next request.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Failed to refresh Remote Config: $e';
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
        title: const Text('Firebase AI + Remote Config Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRemoteConfig,
            tooltip: 'Refresh Remote Config',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _status.contains('✅') 
                ? Colors.green.shade50 
                : _status.contains('❌') 
                  ? Colors.red.shade50 
                  : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Remote Config Values Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Current Remote Config Values',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _refreshRemoteConfig,
                          icon: const Icon(Icons.cloud_download, size: 16),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These values are controlled from Firebase Console > Remote Config',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (_configValues.isNotEmpty) ...[
                      for (final entry in _configValues.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else
                      const Text('Loading config values...'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Prompt',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your prompt here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateContent,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                        label: Text(_isLoading ? 'Generating...' : 'Generate with AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Response Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Response',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _response.isEmpty ? 'No response yet...' : _response,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Control from Firebase Console',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Go to Firebase Console > Remote Config\n'
                      '2. Update AI parameters (model, temperature, prompts, etc.)\n'
                      '3. Click "Publish changes"\n'
                      '4. Tap "Refresh" button above to load new values\n'
                      '5. Test with a new prompt to see changes!',
                    ),
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
