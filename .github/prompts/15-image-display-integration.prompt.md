---
applyTo: 'lib/**/presentation/**'
---

# 15 – Integrate Image Selection & Display (Presentation)

**Objective**
Wire up the selected image flow: from selection to preview screen, ensuring navigation and state propagation.

**Context**
- You have `ImagePickerBloc` (or similar) and `ImagePreviewCubit` in place.
- Next step is connecting selection output to the preview screen.

**Tasks**
1. In `ImageSelectionView`, add a button to navigate when an image is selected:
   - Listen to selection state
   - On `Loaded`, push `ImagePreviewView(image: selectedImage)`
2. Pass the selected image data (File or bytes) to `ImagePreviewView` constructor.
3. In routing (e.g., `AppRouter`), define a route for `ImagePreviewView`.
4. Ensure `ImagePreviewCubit` receives the image on appear:
   - Initialize with passed data
   - Emit `ImagePreviewLoaded`

**Validation Checkpoint**
- After picking an image, tapping “Preview” navigates correctly.
- Preview screen shows loading indicator then image.
- Back navigation returns to selector without errors.
