---
applyTo: "**/marker/**/*.dart,**/gesture/**/*.dart,**/painting/**/*.dart,**/image_editor/presentation/widgets/**/*marker*.dart"
---
# Tree Marking Interface Instructions

This document provides guidelines for implementing the user interface that allows users to mark trees on an image for removal.

Refer also to:
- [Image Processing Module Instructions](./image-processing.instructions.md) for details on how the image is handled.
- [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) if a BLoC/Cubit is used to manage the state of markers.
- [BLoC/Cubit Widget Structure Guidelines](./bloc_widget_structure.instructions.md) for structuring the UI components.

## Implementation Details

For the tree marking interface, implement:

- **Gesture Detection**: Use `GestureDetector` to capture tap events on the image. Each tap should ideally place a marker.
- **Visual Feedback**: When a tree is marked, provide clear visual feedback. This could be a dot, a small circle, a crosshair, or a more sophisticated icon.
    - The marker should be clearly visible against various image backgrounds.
- **Multiple Markers**: Allow users to place multiple markers on the image if multiple trees or parts of a large tree need to be identified.
- **Marker Management**:
    - **Removal**: Implement a way to remove the last placed marker or a selected marker.
    - **Adjustment (Optional)**: Consider if users should be able to drag/adjust existing markers. If so, provide intuitive controls.
- **Zoom and Pan**: Integrate robust zoom and pan functionality (e.g., using `InteractiveViewer` or a custom solution) to allow users to navigate the image and place markers precisely, especially on large images or small details.

## Code Structure Guidelines

- **Custom Painting**: Use `CustomPainter` to render the markers directly onto the image widget. This provides flexibility in marker appearance.
- **Gesture Handling**: Encapsulate gesture logic within the relevant widget. Ensure that gesture coordinates are correctly translated to image coordinates, especially when zoom/pan is active.
- **State Management for Markers**:
    - The list of marker positions (and potentially other marker properties) should be managed by a dedicated BLoC/Cubit (e.g., `ImageEditorBloc` or a more specialized `MarkerBloc`).
    - Events/methods should exist for adding, removing, and potentially updating markers.
    - The state should hold the current list of markers, which the `CustomPainter` will use for rendering.
- **Marker Data**: Use immutable value objects (e.g., a simple class or record) to represent marker data (e.g., `Point`, `Offset`, or a custom `MarkerInfo` class if more attributes are needed).
- **Coordinate System**: Be explicit about the coordinate system used for markers (e.g., relative to the original image dimensions or relative to the displayed widget size). Ensure consistency, especially with zoom/pan transformations.
- **Validation**: Implement validation for marker positions if necessary (e.g., ensuring markers are within image bounds, though this might be handled by the UI constraints).

## Implementation Example

```dart
import 'dart:ui' as ui; // For ui.Image
import 'package:flutter/material.dart';
// Assuming Point is a simple class or from a library like dart:math
// For example:
// import 'dart:math';

// A more robust Point class might be needed, or use Offset.
// For simplicity, assuming Offset is used for marker positions.

class TreeMarkerPainter extends CustomPainter {
  final List<Offset> markedPoints; // Use Offset for Flutter painting
  final double markerRadius;
  final Color markerColor;
  final ui.Image? backgroundImage; // To draw markers relative to the image
  final double scale; // Current scale factor from InteractiveViewer

  TreeMarkerPainter({
    required this.markedPoints,
    this.backgroundImage,
    this.markerRadius = 10.0, // Adjusted for better visibility based on scale
    this.markerColor = Colors.redAccent,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If there's a background image, clip drawing to its bounds
    if (backgroundImage != null) {
      // Calculate the size and position of the image as displayed
      // This depends on how the image is fitted into the CustomPaint area (size)
      // For this example, assume the CustomPaint `size` is the size of the displayed image area.
    }

    final paint = Paint()
      ..color = markerColor.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale; // Make stroke width scale-invariant

    for (final point in markedPoints) {
      // The `point` should be in the coordinate system of the original image.
      // If `InteractiveViewer` is used, transformations are handled before paint.
      // The `canvas` here is already transformed by InteractiveViewer.
      // So, if `point` is in image coordinates, it will be drawn correctly.
      
      // Adjust marker radius to be somewhat consistent regardless of zoom
      final visualRadius = markerRadius / scale;

      canvas.drawCircle(
        point, // Offset already in the correct (potentially transformed) coordinate space
        visualRadius,
        paint,
      );
      canvas.drawCircle(
        point,
        visualRadius,
        outlinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreeMarkerPainter oldDelegate) =>
      markedPoints != oldDelegate.markedPoints ||
      markerRadius != oldDelegate.markerRadius ||
      markerColor != oldDelegate.markerColor ||
      backgroundImage != oldDelegate.backgroundImage ||
      scale != oldDelegate.scale;
}

// Example usage within a widget that might use InteractiveViewer and a BLoC/Cubit:
// class MarkingWidget extends StatelessWidget {
//   final ui.Image image;
//   // ... other properties ...

//   @override
//   Widget build(BuildContext context) {
//     final transformationController = TransformationController();
//     final editorBloc = context.watch<ImageEditorBloc>(); // Assuming a BLoC

//     return InteractiveViewer(
//       transformationController: transformationController,
//       // ... other InteractiveViewer properties (minScale, maxScale) ...
//       onInteractionEnd: (details) {
//         // Update scale in BLoC if needed for painter logic, or pass directly
//         // editorBloc.add(ScaleUpdated(transformationController.value.getMaxScaleOnAxis()));
//       },
//       child: GestureDetector(
//         onTapUp: (details) {
//           // Convert tap position (local to widget) to image coordinates
//           finallocalPosition = details.localPosition;
//           // The transformation from InteractiveViewer needs to be applied inversely
//           final scenePoint = transformationController.toScene(localPosition);
//           editorBloc.add(AddMarkerEvent(scenePoint));
//         },
//         child: CustomPaint(
//           size: Size(image.width.toDouble(), image.height.toDouble()), // Or size of the container
//           painter: TreeMarkerPainter(
//             markedPoints: editorBloc.state.markers, // Get markers from state
//             backgroundImage: image,
//             scale: transformationController.value.getMaxScaleOnAxis(), // Pass current scale
//           ),
//         ),
//       ),
//     );
//   }
// }

```

## User Experience Considerations

- **Clear Instructions**: Provide concise on-screen instructions or a quick tutorial hint on how to mark trees (e.g., "Tap on a tree to mark it for removal").
- **Visual Cues**: 
    - Ensure markers are easily distinguishable from the image content.
    - Consider a subtle animation when a marker is placed.
- **Undo/Redo**: Implement undo functionality for marker placement (removing the last marker). A redo is less critical but can be useful.
- **Confirmation Step**: Before sending the image and markers for AI processing, consider showing a confirmation dialog or a clear "Process" button that implies finalization of markers.
- **Haptic Feedback**: Provide haptic feedback (if available and appropriate for the platform) when markers are placed or removed, enhancing the tactile experience.
- **Performance**: Ensure that rendering markers, especially with zoom/pan, is performant and does not lag, even with a moderate number of markers.
- **Accessibility**: Consider accessibility for users with motor impairments (e.g., larger tap targets if possible, though precision is also key) or visual impairments (e.g., high contrast markers).
