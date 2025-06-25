---
applyTo: 'lib/**'
---

# 19 – Permissions Handling (Cross-cutting)

**Objective**
Implement robust permission handling for camera, gallery, and storage across Android and iOS.

**Context**
- Your features require camera access (image capture), gallery access (image selection), and storage write (image save).
- You need consistent UI feedback and error handling when permissions are denied or revoked.

**Tasks**
1. Add `permission_handler` package to `pubspec.yaml` and configure platform settings:
   - Android: update `AndroidManifest.xml` with `CAMERA` and `WRITE_EXTERNAL_STORAGE` permissions.
   - iOS: add usage descriptions in `Info.plist` for `NSCameraUsageDescription` and `NSPhotoLibraryAddUsageDescription`.
2. Create `PermissionService` with methods:
   - `Future<bool> requestCameraPermission()`
   - `Future<bool> requestGalleryPermission()`
   - `Future<bool> requestStoragePermission()`
   Each method should:
     - Check current status
     - Request if not granted
     - Handle permanently denied (open app settings)
3. Integrate `PermissionService` calls in:
   - Image pick flow: request before opening camera or gallery.
   - Save flow: request storage before saving image.
4. Provide user-friendly dialogs when:
   - Permission denied: show rationale and link to settings.
   - Permanently denied: guide to app settings.

**Validation Checkpoint**
- Denying permission shows an informative dialog.
- Granting then allows the flow to proceed.
- Permanently denied navigates to app settings.
