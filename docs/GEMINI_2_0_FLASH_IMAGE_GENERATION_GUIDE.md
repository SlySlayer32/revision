# Gemini 2.0 Flash Image Generation Model Integration Guide

## 🎯 Overview

This guide provides comprehensive instructions for properly integrating and using the `gemini-2.0-flash-preview-image-generation` model with Firebase AI SDK in the Revision app.

## ⚠️ Critical Understanding

The Gemini 2.0 Flash image generation model has unique characteristics that require specific handling:

### Response Modalities
- **Supports**: TEXT + IMAGE response modalities
- **Generates**: Both text descriptions AND image data in the same response
- **Does NOT support**: System instructions (`systemInstruction` must be `null`)

### Key Differences from Analysis Models
| Feature | Gemini 1.5 Flash (Analysis) | Gemini 2.0 Flash (Generation) |
|---------|----------------------------|--------------------------------|
| System Instructions | ✅ Supported | ❌ Not supported |
| Input | Text + Images | Text only |
| Output | Text only | Text + Images |
| Use Case | Analyze existing images | Generate new images |

## 🔧 Proper Implementation

### 1. Model Initialization

```dart
// ✅ CORRECT: No system instructions for image generation model
final isImageGenerationModel = modelName.contains('image-generation');

final model = firebaseAI.generativeModel(
  model: 'gemini-2.0-flash-preview-image-generation',
  generationConfig: GenerationConfig(
    temperature: 0.3, // Lower for more controlled generation
    maxOutputTokens: 2048,
    topK: 32,
    topP: 0.9,
  ),
  // ❌ NEVER set systemInstruction for image generation models
  systemInstruction: isImageGenerationModel ? null : Content.text(systemPrompt),
);
```

### 2. Content Creation

```dart
// ✅ CORRECT: Text-only input for image generation
final content = [
  Content.multi([
    TextPart('''
Generate a high-quality image based on this request: $prompt

Create a professional result that matches the editing intent.
Focus on realistic lighting, proper composition, and clean background.
'''),
  ]),
];
```

### 3. Response Handling

```dart
// ✅ CORRECT: Handle both text and image in response
final response = await model.generateContent(content);

// Check for image data in response parts
if (response.candidates.isNotEmpty) {
  final candidate = response.candidates.first;
  if (candidate.content.parts.isNotEmpty) {
    for (final part in candidate.content.parts) {
      if (part is InlineDataPart && part.mimeType.startsWith('image/')) {
        // Found generated image!
        final imageBytes = part.bytes;
        final mimeType = part.mimeType; // e.g., 'image/png'
        return imageBytes;
      } else if (part is TextPart) {
        // Found text description
        final description = part.text;
        log('AI Description: $description');
      }
    }
  }
}
```

## 🚨 Common Errors and Solutions

### Error: "The requested combination of response modalities is not supported"

**Cause**: Trying to use the model incorrectly or with unsupported configurations.

**Solutions**:
1. ✅ Remove `systemInstruction` for image generation models
2. ✅ Use text-only input (no image input for generation)
3. ✅ Handle both text and image in response
4. ✅ Use appropriate temperature (0.3-0.4)

### Error: "Model does not support system instructions"

**Cause**: Setting `systemInstruction` on image generation model.

**Solution**:
```dart
// ✅ CORRECT
systemInstruction: isImageGenerationModel ? null : Content.text(prompt),
```

## 📋 Implementation Checklist

### Model Configuration
- [ ] Model name: `gemini-2.0-flash-preview-image-generation`
- [ ] System instruction: `null` (not supported)
- [ ] Temperature: 0.3-0.4 (controlled generation)
- [ ] Max output tokens: 2048+ (for both text and image)

### Content Creation
- [ ] Use `Content.multi([TextPart(...)])` only
- [ ] Include detailed, specific prompts
- [ ] No image input for generation (text prompts only)

### Response Processing
- [ ] Check `response.candidates[0].content.parts[]`
- [ ] Handle both `TextPart` and `InlineDataPart`
- [ ] Extract image data from `InlineDataPart.bytes`
- [ ] Verify MIME type starts with `image/`

### Error Handling
- [ ] Graceful fallback when no image generated
- [ ] Proper timeout handling (30+ seconds)
- [ ] Return original image on failure
- [ ] Log detailed error information

## 🎨 Use Cases and Prompting

### Image Generation Prompts
```dart
// ✅ Good prompts for image generation
"Create a clean background image suitable for photo editing"
"Generate a professional headshot background with soft lighting"
"Create a natural landscape background with blue sky and green grass"

// ❌ Avoid these for generation models
"Analyze this image and tell me what's in it" // Use analysis model
"Remove the person from this photo" // Use editing workflow
```

### When to Use Each Model

| Task | Use Model | Example |
|------|-----------|---------|
| Analyze existing images | `gemini-1.5-flash-002` | "What objects are in this image?" |
| Generate new images | `gemini-2.0-flash-preview-image-generation` | "Create a sunset background" |
| Image editing guidance | `gemini-1.5-flash-002` | "How do I remove this object?" |

## 🔄 Complete Implementation Example

```dart
Future<Uint8List?> generateImageWithAI(String prompt) async {
  try {
    // Initialize model without system instructions
    final model = firebaseAI.generativeModel(
      model: 'gemini-2.0-flash-preview-image-generation',
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 2048,
        topK: 32,
        topP: 0.9,
      ),
      systemInstruction: null, // Critical: No system instructions
    );

    // Create text-only content
    final content = [
      Content.multi([
        TextPart('Generate a high-quality image: $prompt'),
      ]),
    ];

    // Generate response with timeout
    final response = await model
        .generateContent(content)
        .timeout(Duration(seconds: 30));

    // Extract image from response
    if (response.candidates.isNotEmpty) {
      for (final part in response.candidates.first.content.parts) {
        if (part is InlineDataPart && part.mimeType.startsWith('image/')) {
          return part.bytes;
        }
      }
    }

    return null; // No image generated
  } catch (e) {
    log('Image generation failed: $e');
    return null;
  }
}
```

## 📊 Performance Optimization

### Best Practices
1. **Caching**: Cache generated images when possible
2. **Timeouts**: Use 30+ second timeouts for generation
3. **Retry Logic**: Implement exponential backoff for failures
4. **Resource Management**: Dispose of large image bytes promptly
5. **User Feedback**: Show progress indicators during generation

### Monitoring
- Track generation success rates
- Monitor response times
- Log detailed error information
- Monitor memory usage with large images

## 🔐 Security Considerations

### Content Safety
- Always validate generated content
- Implement content filtering
- Monitor for inappropriate generations
- Provide user reporting mechanisms

### Privacy
- Don't log sensitive prompt data
- Secure image data in transit
- Implement proper data retention policies
- Follow GDPR compliance for generated content

## 📚 Additional Resources

- [Firebase AI Documentation](https://firebase.google.com/docs/ai)
- [Gemini API Reference](https://developers.google.com/gemini)
- [Image Generation Best Practices](https://developers.google.com/gemini/docs/image-generation)

---

This guide ensures proper implementation of the Gemini 2.0 Flash image generation model in the Revision app, avoiding common pitfalls and following best practices for production use.
