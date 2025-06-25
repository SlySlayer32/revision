---
applyTo: 'lib/**/data/**'
---

# 14 – Save Image Data Layer

**Objective**
Implement the data layer responsible for saving processed or edited images into device storage or gallery with proper permissions, naming, and duplicate handling.

**Context**
- You have an image result (`File` or `Uint8List`) from AI editing pipeline.
- Next, users need to save this image permanently.

**Tasks**
1. Add `gallery_saver` (or equivalent) package in `pubspec.yaml`.
2. Create `ImageStorageRepository` interface:
   - Methods: `Future<String> saveToGallery(File image)`, `Future<bool> exists(String path)`
3. Implement `ImageStorageRepositoryImpl`:
   - Use platform-specific APIs or `gallery_saver` to store images.
   - Generate file name: `img_YYYYMMDD_HHMMSS.png`.
   - Before saving, check for existing file names to avoid duplicates (append suffix if needed).
4. Handle permissions:
   - Request storage permissions at save time.
   - If denied, throw custom `PermissionDeniedException`.

**Validation Checkpoint**
- Calling `saveToGallery` returns a valid file path on success.
- Duplicate save appends a new suffix without error.
- Permission denied triggers an explicit exception.
