---
mode: 'agent'
---
Create `ImageMarker` entity with these exact properties:
```dart
class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.position,
    required this.timestamp,
    this.confidence = 1.0,
    this.metadata = const {},
  });
  
  final String id; // UUID v4
  final Offset position; // Normalized coordinates (0.0-1.0)
  final DateTime timestamp;
  final double confidence; // For AI feedback
  final Map<String, dynamic> metadata;
  
  // Must include these exact methods for AI processing
  Map<String, dynamic> toVertexAIFormat() { /* implementation */ }
  static ImageMarker fromTapPosition(Offset screenPos, Size imageSize) { /* implementation */ }
}