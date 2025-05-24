---
applyTo: "**/ai/**/*.dart,**/gemini/**/*.dart,**/vertex/**/*.dart"
---
# AI Integration Module Instructions

## Implementation Details

For the AI integration module, implement:

- Google Vertex AI Gemini 2.5 Pro for image analysis
- Google Vertex AI Gemini 2.0 Flash for image editing
- Firebase Vertex AI integration (e.g., using `firebase_vertexai` package or similar)
- Prompt engineering for accurate tree removal (Develop and iterate on prompts that clearly instruct the AI, considering image context, marker information, and desired output style. Document effective prompt structures.)
- Error handling and fallback mechanisms for AI processing

## Code Structure Guidelines

- Create a service layer to abstract AI API interactions
- Implement proper authentication for Vertex AI (e.g., leveraging Firebase Authentication tokens if using Firebase SDKs, or managing service account keys securely for direct API calls)
- Use repository pattern for AI-related data operations (e.g., managing cached AI responses, storing/retrieving prompt templates)
- Separate analysis and editing concerns into different services
- Cache AI results when appropriate to minimize API calls

## API Integration

```dart
// Example Vertex AI integration
Future<String> generateEditingPrompt(File image, List<Point> markedPoints) async {
  try {
    final base64Image = await _convertImageToBase64(image);
    
    final content = [
      {
        'role': 'user',
        'parts': [
          {'text': 'Analyze this image and create a prompt for removing the marked tree:'},
          {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}},
          {'text': 'Marked points: ${markedPoints.join(', ')}'}
        ]
      }
    ];
    
    final response = await _geminiProModel.generateContent(content);
    return response.text;
  } catch (e) {
    throw AIProcessingException('Failed to generate editing prompt: $e');
  }
}
```

## Performance Considerations

- Optimize image size (dimensions and quality) before sending to AI services to reduce latency and cost, while ensuring sufficient detail for analysis/editing.
- Implement proper timeout handling for API calls
- Use appropriate model parameters to balance quality and speed
- Consider implementing a queue for processing multiple images
- Add retry logic for transient failures

## User Experience Guidelines

- Show detailed progress indicators during AI processing
- Provide estimates of processing time for large images
- Allow cancellation of ongoing AI operations
- Show helpful error messages when AI processing fails
- Consider adding user-facing explanations of AI processing stages (e.g., 'Analyzing image...', 'Removing tree...', 'Finalizing edit...') to manage expectations.
