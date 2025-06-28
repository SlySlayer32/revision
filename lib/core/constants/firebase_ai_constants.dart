/// Firebase AI Logic constants following latest best practices
class FirebaseAIConstants {
  // Model configurations following the AI pipeline flow
  static const String geminiModel =
      'gemini-2.0-flash'; // Step 3: Analyze marked area & generate removal prompt
  static const String geminiImageModel =
      'gemini-2.0-flash-preview-image-generation'; // Step 5: Generate new image using prompt

  // Legacy Imagen models (keeping for reference but using Gemini 2.0 Flash)
  static const String imagenModel = 'imagegeneration@006'; // Legacy - not used
  static const String imagenEditModel =
      'imagen-3.0-capability-001'; // Legacy - not used
  static const String imagenGenerateModel =
      'imagen-3.0-generate-002'; // Legacy - not used

  // Request limits and timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxImageSizeMB = 20; // Firebase AI Logic supports up to 20MB
  static const int maxRetries = 2;

  // Image processing constants
  static const int maxImageWidth = 3072; // Auto-scaled by Firebase AI
  static const int maxImageHeight = 3072;
  static const List<String> supportedMimeTypes = [
    'image/png',
    'image/jpeg',
    'image/webp'
  ];

  // Generation config for consistent results
  static const double temperature = 0.4; // Balanced creativity/consistency
  static const int maxOutputTokens = 1024;
  static const int topK = 40;
  static const double topP = 0.95;

  // System prompts matching the AI pipeline flow
  static const String analysisSystemPrompt = '''
You are Gemini 2.0 Flash analyzing marked objects for removal. The user has marked specific areas they want removed from their photo.

Analyze the marked regions and generate a precise removal prompt for the next AI model:

1. Identify what objects are marked for removal
2. Analyze the background texture and patterns
3. Consider lighting, shadows, and color harmony
4. Generate specific instructions for content-aware reconstruction

Provide a technical prompt that will guide the image generation model to remove the marked objects seamlessly while preserving image quality and natural appearance.
''';
  static const String editingSystemPrompt = '''
You are Gemini 2.0 Flash Preview Image Generation. You will receive an image with marked objects and a removal prompt from the analysis stage.

Your task:
1. Generate a new version of the image with the marked objects completely removed
2. Use content-aware reconstruction to fill the removed areas naturally
3. Maintain consistent lighting, shadows, and color harmony throughout
4. Preserve the original image resolution and overall composition
5. Ensure seamless blending with no visible artifacts

Generate the edited image directly with all specified objects removed and background reconstructed realistically.
''';
}
