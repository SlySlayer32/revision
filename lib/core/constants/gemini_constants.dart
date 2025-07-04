/// Constants for Gemini AI API operations
class GeminiConstants {
  // Private constructor to prevent instantiation
  GeminiConstants._();

  // API Configuration
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // Request Limits
  static const int maxPromptLength = 20000;
  static const int maxImageSizeBytes = 20 * 1024 * 1024; // 20MB
  static const int minApiKeyLength = 30;
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  // HTTP Status Codes
  static const int httpOk = 200;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpTooManyRequests = 429;
  
  // Model Parameters (defaults)
  static const double defaultTemperature = 0.7;
  static const double lowTemperature = 0.1; // For segmentation
  static const double imageTemperatureMultiplier = 0.75;
  static const int defaultMaxTokens = 2048;
  static const int defaultTopK = 32;
  static const double defaultTopP = 0.9;
  
  // Image Defaults
  static const int defaultImageWidth = 1024;
  static const int defaultImageHeight = 1024;
  static const String defaultImageMimeType = 'image/jpeg';
  
  // Model Names
  static const String defaultGeminiModel = 'gemini-pro';
  static const String geminiVisionModel = 'gemini-pro-vision';
  static const String gemini2_5FlashModel = 'gemini-2.5-flash';
  
  // Error Messages
  static const String apiKeyNotConfiguredError = 'GEMINI_API_KEY not configured';
  static const String promptEmptyError = 'Prompt cannot be empty';
  static const String promptTooLongError = 'Prompt too long (max $maxPromptLength characters)';
  static const String imageEmptyError = 'Image bytes cannot be empty';
  static const String imageTooLargeError = 'Image too large (max ${maxImageSizeBytes ~/ (1024 * 1024)}MB)';
  static const String invalidApiKeyFormatError = 'Invalid API key format';
  static const String connectivityTestFailedError = 'Failed to connect to Gemini API';
  
  // Response Parsing
  static const String candidatesKey = 'candidates';
  static const String contentKey = 'content';
  static const String partsKey = 'parts';
  static const String textKey = 'text';
  static const String errorKey = 'error';
  static const String messageKey = 'message';
  static const String codeKey = 'code';
  static const String finishReasonKey = 'finishReason';
  static const String safetyFinishReason = 'SAFETY';
  
  // Request Body Keys
  static const String contentsKey = 'contents';
  static const String generationConfigKey = 'generationConfig';
  static const String temperatureKey = 'temperature';
  static const String maxOutputTokensKey = 'maxOutputTokens';
  static const String topKKey = 'topK';
  static const String topPKey = 'topP';
  static const String inlineDataKey = 'inline_data';
  static const String mimeTypeKey = 'mime_type';
  static const String dataKey = 'data';
  
  // Segmentation specific
  static const String boxKey = 'box_2d';
  static const String maskKey = 'mask';
  static const String labelKey = 'label';
  static const String responseMimeTypeKey = 'response_mime_type';
  static const String applicationJsonMimeType = 'application/json';
  static const String systemInstructionKey = 'systemInstruction';
  static const String thinkingConfigKey = 'thinking_config';
  static const String thinkingBudgetKey = 'thinking_budget';
  
  // Fallback suggestions
  static const List<String> fallbackEditSuggestions = [
    'Remove any unwanted objects or distractions from the image',
    'Adjust brightness and contrast for better visual impact',
    'Enhance colors to make them more vibrant and appealing',
    'Crop or straighten the image for better composition',
    'Apply subtle sharpening to improve image clarity',
  ];
}
