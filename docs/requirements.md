---
applyTo: 'mvp'
---

# 🎯 Immediate Action Plan: Build Working MVP

## STOP doing

- More architectural setup
- Complex testing infrastructure
- Documentation and planning
- Mocks

## START doing

- MVP style setup
- Mocks were necessary otherwise setup proper logic
- Focus on making it work
- Plan ahead every edit
- Validate each step before proceeding

## 🚀 Step-by-Step MVP Implementation

### 1. Image Selection Feature (Next 2-3 hours)

#### Step 1: Follow prompt files, 06-image-picker-domain.prompt.md through until 10-image-editor-presentation.prompt.md

- Create the domain layer for image selection
- Focus on core entities and use cases

**Requirements to meet:**

- [ ] Domain models compile without errors
- [ ] Core entities (Image, ImageSelection) are defined
- [ ] Use cases (SelectImage, ValidateImage) are structured
- [ ] Repository interfaces are defined
- [ ] No business logic in domain layer

#### Step 2: Implement the data layer using the `image_picker` package

- Implement data layer with image_picker package
- Add basic permission handling for camera/gallery access

**Requirements to meet:**

- [ ] `image_picker` package integrated and configured
- [ ] Repository implementation connects to image_picker
- [ ] Camera permission handling implemented
- [ ] Gallery permission handling implemented
- [ ] Permission denied scenarios handled gracefully
- [ ] Can successfully retrieve image file paths
- [ ] Basic error handling for picker failures

#### Step 3: Build the presentation layer

- Using the `flutter_bloc` package
- Implement the UI for image selection
- Add basic loading states and error messages

**Requirements to meet:**

- [ ] BLoC/Cubit for image selection state management
- [ ] UI shows "Select Image" button/option
- [ ] Loading state displays during image selection
- [ ] Error states show user-friendly messages
- [ ] Success state updates UI with selected image info
- [ ] UI handles permission request dialogs
- [ ] Navigation between gallery/camera options works

#### Step 4: Integrate the image selection feature into your app

- Ensure users can select images from their device
- Implement basic image size validation (max 10MB to prevent memory issues)

**Requirements to meet:**

- [ ] Feature integrated into main app navigation
- [ ] Image size validation (reject files > 10MB)
- [ ] File type validation (accept common image formats)
- [ ] Selected image data is accessible to other parts of app
- [ ] Memory usage stays reasonable during selection
- [ ] Works on both Android and iOS
- [ ] Handles device rotation during selection

#### Step 5: Test the image selection feature

- Ensure basic functionality works as expected
- Test permission scenarios (granted/denied)

**Requirements to meet:**

- [ ] Can select images from gallery successfully
- [ ] Can take photos with camera successfully
- [ ] Permission denied shows appropriate message
- [ ] Large files are rejected with clear message
- [ ] Invalid file types are rejected
- [ ] App doesn't crash during any selection scenario
- [ ] Selected images persist during app state changes

### 2. Minimal Image Display (Next 1 hour)

**Requirements to meet:**

- [ ] Selected image displays in UI without distortion
- [ ] Loading indicator shows while image loads
- [ ] Image fits properly in designated container
- [ ] Memory usage remains stable with large images
- [ ] Image compression works for files > 2MB
- [ ] Placeholder shown when no image selected
- [ ] Image display updates when new image selected
- [ ] No memory leaks when switching between images

### 3. One AI Feature (Next 2-3 hours)

#### Security Setup (15 minutes)

**Requirements to meet:**

- [ ] Vertex AI credentials stored in environment variables
- [ ] No hardcoded API keys in source code
- [ ] API key validation on app startup
- [ ] Request timeout set to 30 seconds maximum
- [ ] HTTPS-only communication with AI services

#### Step 3a: Image Analysis (PROMPT)

**Requirements to meet:**

- [ ] Image successfully uploads to Vertex AI
- [ ] Custom prompt instructions are applied
- [ ] API response contains image analysis
- [ ] Retry logic works (max 2 attempts)
- [ ] Network errors are caught and handled
- [ ] Loading indicator shows during processing
- [ ] Analysis results are properly parsed

#### Step 3b: Image Editing (EDIT)

**Requirements to meet:**

- [ ] Analysis prompt forwards to Imagen model
- [ ] Custom editing instructions are applied
- [ ] Edited image is received and decoded
- [ ] Progress indicator shows during long operations
- [ ] Edited image maintains reasonable quality
- [ ] Processing completes within reasonable time (< 2 minutes)
- [ ] Large image handling doesn't cause timeouts

#### Step 3c: Error Handling

**Requirements to meet:**

- [ ] Network timeout shows "Connection timeout" message
- [ ] API errors show "Service temporarily unavailable"
- [ ] Invalid responses show "Processing failed, try again"
- [ ] Retry button allows user to attempt again
- [ ] App remains stable during all error scenarios
- [ ] User can cancel long-running operations
- [ ] Error logs are captured for debugging

### 4. Save Results (Next 1 hour)

**Requirements to meet:**

- [ ] Storage permission requested and handled
- [ ] Images save to device gallery successfully
- [ ] File naming uses timestamp format (YYYYMMDD_HHMMSS)
- [ ] Success message shows "Image saved to gallery"
- [ ] Error message shows specific failure reason
- [ ] Duplicate filenames are handled automatically
- [ ] Saved images are accessible in device gallery app
- [ ] Save operation doesn't block UI thread

## 🛡️ Essential Safety Measures (Non-negotiable)

**Requirements to meet:**

- [ ] All permissions have fallback handling
- [ ] Image size limits prevent out-of-memory crashes
- [ ] API timeouts prevent indefinite hanging
- [ ] No credentials exposed in logs or UI
- [ ] All user-facing errors have clear messages

## 🚨 Rollback Strategy

If any step takes longer than planned or hits blockers:

1. **Step 1-2 issues:** Use mock images, continue with AI pipeline
2. **Step 3 issues:** Implement simple image filters instead of AI
3. **Step 4 issues:** Show success message without actual saving
4. **Overall blocker:** Pivot to simpler image gallery with basic filters

## 🎯 Your 8-Hour MVP Goal

User opens app → Logs in → Picks image → Applies AI effect → Saves result → Success!

## ✅ Final MVP Requirements

- [ ] App launches without crashes on clean install
- [ ] User can complete full flow without developer intervention
- [ ] All permissions work on first-time user experience
- [ ] AI processing completes or fails gracefully
- [ ] Results are actually saved and accessible
- [ ] App handles device interruptions (calls, notifications)
- [ ] Memory usage stays under 200MB during normal operation
- [ ] App works on both Android and iOS physical devices
- [ ] No placeholder text or "TODO" comments in user-facing areas
- [ ] Basic analytics/logging captures successful completions

## 🔄 Step Validation Rules

1. **Never proceed** if current step requirements aren't met
2. **Test on device** before marking step complete
3. **Document any requirement skipped** with reason
4. **Revert changes** if step breaks previous functionality
5. **Time-box each step** - if over time limit, implement minimal version
6. **Communicate blockers** immediately to team
7. **Use version control** to track changes and rollbacks
