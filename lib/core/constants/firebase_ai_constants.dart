/// Firebase AI Logic constants following latest best practices
class FirebaseAIConstants {
  // Model configurations following the AI pipeline flow
  static const String geminiModel =
      'gemini-1.5-flash-002'; // Step 3: Analyze marked area & generate removal prompt
  static const String geminiImageModel =
      'gemini-2.0-flash-preview-image-generation'; // Step 5: Generate new image using prompt (your 2nd model)

  // Legacy Imagen models (keeping for reference but using Gemini 2.0 Flash)
  static const String imagenModel = 'imagegeneration@006'; // Legacy - not used
  static const String imagenEditModel =
      'imagen-3.0-capability-001'; // Legacy - not used
  static const String imagenGenerateModel =
      'imagen-3.0-generate-002'; // Legacy - not used

  // Request limits and timeouts - Enhanced for error resilience
  static const Duration requestTimeout = Duration(
    seconds: 45,
  ); // Increased for stability
  static const Duration quickTimeout = Duration(
    seconds: 15,
  ); // For quick operations
  static const Duration longTimeout = Duration(
    seconds: 90,
  ); // For image generation
  static const int maxImageSizeMB = 20; // Firebase AI Logic supports up to 20MB
  static const int maxRetries = 3; // Increased for better reliability

  // Error handling constants
  static const Duration retryBaseDelay = Duration(seconds: 1);
  static const Duration retryMaxDelay = Duration(seconds: 16);
  static const int circuitBreakerThreshold = 5;
  static const Duration circuitBreakerTimeout = Duration(minutes: 2);

  // Image processing constants
  static const int maxImageWidth = 3072; // Auto-scaled by Firebase AI
  static const int maxImageHeight = 3072;
  static const List<String> supportedMimeTypes = [
    'image/png',
    'image/jpeg',
    'image/webp',
  ];

  // Generation config for consistent results
  static const double temperature = 0.4; // Balanced creativity/consistency
  static const int maxOutputTokens = 1024;
  static const int topK = 40;
  static const double topP = 0.95;

  // System prompts matching the AI pipeline flow
  static const String analysisSystemPrompt = '''
You are Gemini analyzing marked objects for removal. The user has marked specific areas they want removed from their photo.

Analyze the marked regions and provide detailed editing guidance:

1. Identify what objects are marked for removal
2. Analyze the background texture and patterns
3. Consider lighting, shadows, and color harmony
4. Provide step-by-step instructions for manual editing

Provide clear, actionable editing instructions that describe how to remove the marked objects while maintaining natural appearance.
''';

  static const String editingSystemPrompt = '''
You are a photo editing assistant. You will analyze images and provide editing guidance.

Your task:
1. Describe what you see in the image
2. Identify objects that could be removed or modified
3. Suggest editing techniques and approaches
4. Provide step-by-step editing instructions
5. Recommend tools and methods for best results

Focus on providing practical editing advice rather than generating new images.
''';

  // IMPORTANT: Gemini 2.0 Flash Image Generation Model Usage Notes
  // ================================================================
  // The 'gemini-2.0-flash-preview-image-generation' model:
  // - Supports TEXT + IMAGE response modalities (generates both text and images)
  // - Does NOT support system instructions (systemInstruction should be null)
  // - Generates new images based on text prompts (not editing existing images)
  // - Returns response with both text description and image data
  // - Image data is found in response.candidates[0].content.parts[] as InlineDataPart
  // - Use lower temperature (0.3-0.4) for more controlled generation
  // - Requires careful prompt engineering for best results
  //
  // Example usage pattern:
  // 1. Create content with TextPart only (no image input for generation)
  // 2. Check response.candidates[0].content.parts[] for both text and image parts
  // 3. Extract InlineDataPart where mimeType starts with 'image/'
  // 4. Handle cases where generation fails gracefully
}
