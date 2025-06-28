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

  // System prompts for your use case
  static const String analysisSystemPrompt = '''
You are an expert image analysis AI. Analyze the provided image and marked object to create precise editing instructions.

Focus on:
1. Object identification and boundaries
2. Background reconstruction techniques  
3. Lighting and shadow analysis
4. Color harmony considerations
5. Realistic removal strategies

Provide actionable editing instructions.
''';
  static const String editingSystemPrompt = '''
You are an expert AI image editor using Gemini 2.0 Flash Preview Image Generation. Edit the provided image based on user instructions with these requirements:

1. Generate a new version of the image with the requested edits applied
2. If removing objects: use content-aware reconstruction to fill the space naturally
3. If enhancing: improve lighting, contrast, color balance, and composition
4. Maintain original image resolution and quality
5. Preserve overall composition and visual coherence
6. Apply changes seamlessly and realistically

Return the edited image directly as the output.
''';
}
