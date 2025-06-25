---
applyTo: 'lib/**/presentation/**'
---

# 12 – Minimal Image Display Widget (Presentation)

**Objective**
Implement a simple widget to preview the selected image with a loading indicator and basic memory management.

**Context**
- You just completed image selection.
- The domain and data layers have delivered a `File` or `Uint8List` representing the image.

**Tasks**
1. Create `ImagePreviewCubit` (using flutter_bloc) to handle:
   - Loading state
   - Loaded state with `File` or `Uint8List`
   - Error state if the image fails to load or decode
2. Build a `ImagePreviewView`:
   - Show a centered `CircularProgressIndicator` during loading
   - Display the image (`Image.file` or `Image.memory`) once ready
   - Present an error message if loading fails
3. Apply basic memory hints:
   - Use `Image.memory(..., gaplessPlayback: true)`
   - Constraint max display size to avoid large memory usage (e.g., `BoxFit.contain`, max width/height)

**Validation Checkpoint**
- Manually select an image and navigate to preview
- Loading indicator appears briefly then shows the image
- No crashes or OOM on large test images (up to ~10 MB)

---

*Next: Integrate AI analysis pipeline with the preview.*
