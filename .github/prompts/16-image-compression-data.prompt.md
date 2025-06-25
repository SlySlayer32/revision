---
applyTo: 'lib/**/data/**'
---

# 16 – Image Compression Data Layer

**Objective**
Implement image compression logic for large files before display or API upload to prevent memory issues.

**Context**
- Selected image can be up to 10MB, risk of OOM.
- Compression should use `image` package to resize and re-encode.

**Tasks**
1. Add `image` package in `pubspec.yaml` (if not present).
2. Create `ImageCompressor` class with method `Future<Uint8List> compress(Uint8List data, {int maxWidth = 1080, int quality = 80})`:
   - Decode image bytes
   - Resize maintaining aspect ratio to maxWidth
   - Encode to JPEG with given quality
3. Integrate compression in pipeline:
   - In `ImageStorageRepositoryImpl`, compress before saving
   - In `AiService`, compress before sending to API

**Validation Checkpoint**
- Compressed image byte size is significantly smaller (e.g., <2MB) for large inputs
- Visual quality acceptable on sample images
