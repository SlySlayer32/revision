# Gemini 2.5 Segmentation Integration Guide

## Overview

This document outlines the integration of Gemini 2.5's advanced segmentation capabilities into the Revision AI photo editor. The update brings mask-based object segmentation, enhanced object detection, and improved accuracy for object marking workflows.

## 🆕 What's New

### Gemini 2.5 Segmentation Features

1. **Precise Object Segmentation**: Generate contour masks for accurate object boundaries
2. **Base64 PNG Masks**: Probability maps with values 0-255 for fine-grained control
3. **Enhanced Object Detection**: Normalized bounding boxes (0-1000 scale) with improved accuracy
4. **Targeted Segmentation**: Specify particular objects to segment (e.g., "wooden and glass items")

### Key Improvements Over Previous Approach

| Feature | Old Approach | New Gemini 2.5 Approach |
|---------|-------------|-------------------------|
| Object Detection | Basic bounding boxes | Normalized coordinates + confidence scores |
| Segmentation | Manual markers only | AI-generated contour masks |
| Accuracy | Manual selection errors | 90%+ AI accuracy with confidence scores |
| Workflow | User-driven marking | AI-assisted + user refinement |

## 🏗️ Architecture Updates

### New Entities

#### `SegmentationMask`
```dart
class SegmentationMask {
  final BoundingBox2D boundingBox;     // Normalized coordinates [y0, x0, y1, x1]
  final String label;                  // Descriptive object label
  final Uint8List maskData;           // Base64 decoded PNG mask
  final double confidence;             // AI confidence score (0.0-1.0)
}
```

#### `SegmentationResult`
```dart
class SegmentationResult {
  final List<SegmentationMask> masks; // All detected masks
  final int processingTimeMs;          // Performance metrics
  final int imageWidth, imageHeight;   // Original image dimensions
  final SegmentationStats stats;       // Summary statistics
}
```

#### Enhanced `ImageMarker`
```dart
enum MarkerType {
  userDefined,      // User-placed markers
  aiDetection,      // AI object detection
  aiSegmentation,   // AI segmentation masks
}

class ImageMarker {
  final MarkerType markerType;
  final SegmentationMask? segmentationMask; // For AI segmentation
  final BoundingBox2D? boundingBox;          // For AI detection
  final (double x, double y)? coordinates;   // For user markers
}
```

### Updated Services

#### `GeminiAIService` Enhancements
```dart
// New segmentation method using Gemini 2.5
Future<SegmentationResult> generateSegmentationMasks({
  required Uint8List imageBytes,
  String? targetObjects,
  double confidenceThreshold = 0.5,
});

// Enhanced object detection using Gemini 2.0+
Future<List<Map<String, dynamic>>> detectObjectsWithBoundingBoxes({
  required Uint8List imageBytes,
  String? targetObjects,
});
```

### New Use Cases

#### `GenerateSegmentationMasksUseCase`
```dart
Future<Result<SegmentationResult>> call(
  Uint8List imageData, {
  String? targetObjects,
  double confidenceThreshold = 0.5,
});
```

#### `DetectObjectsWithBoundingBoxesUseCase`
```dart
Future<Result<List<Map<String, dynamic>>>> call(
  Uint8List imageData, {
  String? targetObjects,
});
```

## 🚀 Usage Examples

### 1. Basic Segmentation

```dart
// Initialize use case
final segmentationUseCase = GenerateSegmentationMasksUseCase(geminiService);

// Segment all prominent objects
final result = await segmentationUseCase(imageBytes);

result.when(
  success: (segmentationResult) {
    print('Found ${segmentationResult.masks.length} objects');
    for (final mask in segmentationResult.masks) {
      print('- ${mask.label} (confidence: ${mask.confidence})');
    }
  },
  failure: (error) => print('Segmentation failed: $error'),
);
```

### 2. Targeted Segmentation

```dart
// Segment specific objects
final result = await segmentationUseCase(
  imageBytes,
  targetObjects: 'wooden and glass items',
  confidenceThreshold: 0.8,
);
```

### 3. Processing Context Integration

```dart
// Create segmentation context
final context = ProcessingContext.segmentation(
  targetObjects: 'furniture and decorative items',
  confidenceThreshold: 0.7,
);

// Use in processing pipeline
final markers = context.markers; // AI-generated markers
```

### 4. Converting to UI Markers

```dart
// Convert segmentation masks to UI markers
final markers = segmentationResult.masks.map((mask) => 
  ImageMarker.fromSegmentation(
    id: 'seg_${mask.label.replaceAll(' ', '_')}',
    segmentationMask: mask,
  )
).toList();

// Use markers in UI for selection and editing
for (final marker in markers) {
  final contains = marker.containsPoint(x, y, imageWidth, imageHeight);
  if (contains) {
    // Handle object selection
  }
}
```

## 🔧 Integration Steps

### 1. Update GeminiAIService

The `GeminiAIService` has been enhanced with new methods:

- `generateSegmentationMasks()` - Uses Gemini 2.5 for segmentation
- `detectObjectsWithBoundingBoxes()` - Uses Gemini 2.0+ for object detection
- `_makeSegmentationRequest()` - Optimized API calls with proper configuration

### 2. Create New Entities

New domain entities have been added:

- `SegmentationMask` - Represents individual masks
- `SegmentationResult` - Contains all segmentation data
- Enhanced `ImageMarker` - Supports multiple marker types
- Updated `ProcessingContext` - Includes segmentation workflows

### 3. Add Use Cases

New use cases for segmentation workflows:

- `GenerateSegmentationMasksUseCase` - Main segmentation logic
- `DetectObjectsWithBoundingBoxesUseCase` - Object detection logic

### 4. Update UI Components

UI components should be updated to:

- Display segmentation masks as overlays
- Handle different marker types (user vs AI)
- Show confidence scores and labels
- Support mask refinement and editing

## 📊 Performance Considerations

### API Optimization

```dart
// Optimized configuration for segmentation
'generationConfig': {
  'temperature': 0.1,              // Low temperature for consistency
  'response_mime_type': 'application/json',
  'thinking_config': {
    'thinking_budget': 0           // Disable thinking for better results
  }
}
```

### Image Size Recommendations

- **Optimal**: 1024x1024 pixels or smaller
- **Maximum**: 10MB per image
- **Format**: JPEG preferred for API calls

### Processing Times

| Operation | Estimated Time | Quality Level |
|-----------|---------------|---------------|
| Object Detection | 8 seconds | Standard |
| Segmentation | 12 seconds | High |
| Targeted Segmentation | 10 seconds | High |

## 🧪 Testing Strategy

### Unit Tests

```dart
test('should generate segmentation masks', () async {
  final result = await segmentationUseCase(testImageBytes);
  expect(result.isSuccess, true);
  // Verify mask properties
});
```

### Integration Tests

- Test with real Gemini API
- Verify mask accuracy and quality
- Test error handling and fallbacks

### UI Tests

- Test marker display and interaction
- Verify coordinate conversion
- Test mask overlay rendering

## 🔒 Security and Privacy

### API Key Management

- Gemini API key stored securely in `.env`
- Fallback to `--dart-define` for CI/CD
- No API keys in source code

### Data Handling

- Images processed via HTTPS
- No persistent storage of processed images
- Confidence scores for transparency

## 🚨 Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|--------|----------|
| `NotInitializedError` | Service not initialized | Call `waitForInitialization()` |
| `Invalid confidence threshold` | Value outside 0.0-1.0 | Validate input parameters |
| `Empty segmentation response` | API parsing error | Check prompt format and image quality |

### Fallback Strategies

1. **API Failure**: Return empty mask list, log error
2. **Invalid Response**: Parse what's possible, flag as low confidence
3. **Network Issues**: Retry with exponential backoff

## 📈 Future Enhancements

### Planned Features

1. **Mask Refinement**: User editing of AI-generated masks
2. **Batch Processing**: Multiple objects in single request
3. **Custom Models**: Fine-tuned models for specific domains
4. **Real-time Preview**: Live segmentation feedback

### Performance Optimizations

1. **Caching**: Store frequently used masks
2. **Compression**: Optimize mask data transfer
3. **Streaming**: Progressive mask generation
4. **Edge Computing**: Local segmentation for privacy

## 🔗 Related Documentation

- [Gemini API Segmentation Guide](https://ai.google.dev/gemini-api/docs/image-understanding#segmentation)
- [Project Architecture](./PROJECT_ARCHITECTURE.md)
- [AI Integration Instructions](../.github/instructions/04-AI-INTEGRATION.instructions.md)
- [Testing Strategy](./TESTING_STRATEGY.md)

---

This integration brings state-of-the-art AI segmentation capabilities to the Revision photo editor, enabling precise object selection and editing workflows that were previously only possible with manual annotation.
