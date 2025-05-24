---
applyTo: "**/*.dart"
---
# Flutter AI Photo Editor - GitHub Copilot Instructions

This document provides a high-level overview of the Flutter AI Photo Editor project and references to more detailed guidelines for GitHub Copilot. Ensure you familiarize yourself with these instructions before contributing.

**Always apply the [General Coding Guidelines](./general-coding.instructions.md) to all Dart code.**

## Project Overview

This application is an intelligent photo editing app for iOS and Android built with Flutter. Users can:

1. Select an image (JPEG, PNG, or RAW formats).
2. Tap to mark one or more trees they wish to remove from the image.
3. The app then uses AI (Google Vertex AI Gemini Pro for analysis and Gemini Flash for image editing) to process the image and seamlessly remove the marked tree(s).

## Core Architecture & Technologies

- **Framework:** Flutter (initialized using the Very Good Core boilerplate for a solid foundation).
- **Architecture:** Clean Architecture. Refer to [Clean Architecture Guidelines](./architecture-guidelines.instructions.md).
- **State Management:** BLoC/Cubit pattern. See [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) and [BLoC/Cubit Widget Structure Guidelines](./bloc_widget_structure.instructions.md).
- **Dependency Injection:** `get_it` (Service Locator pattern). See [Dependency Injection in Architecture Guidelines](./architecture-guidelines.instructions.md) section on dependency injection.
- **AI Models:**
  - Google Vertex AI Gemini 2.5 Pro (for image analysis tasks, e.g., identifying object boundaries if needed beyond simple marking).
  - Google Vertex AI Gemini 2.0 Flash (for the primary image editing/inpainting task).
  - Integration details: [AI Integration Guidelines](./ai-integration.instructions.md).
- **Firebase:**
  - Firebase Authentication (Email/Password, Google Sign-In).
  - `firebase_ai` plugin for Vertex AI interaction.
  - Details: [Authentication Module Instructions](./auth.instructions.md).
- **Image Handling:**
  - `image_picker`: For selecting images from gallery or camera.
  - `flutter_libraw`: For handling RAW image formats.
  - `GestureDetector` & `CustomPaint`: For the tree marking interface.
  - Details: [Image Processing Module Instructions](./image-processing.instructions.md) and [Tree Marking Interface Instructions](./tree-marking.instructions.md).
- **Local Storage:** `path_provider` for managing temporary files or cached data if necessary.
- **Routing:** Follow standard Flutter routing, potentially enhanced by a routing package if complexity grows (e.g., `go_router`).

## General Development Principles

- **Code Style:** Adhere to Dart and Flutter linting rules defined in `analysis_options.yaml`. Follow [Dart-Specific Coding Guidelines](./dart-guidelines.instructions.md).
- **Testing:** Comprehensive testing is mandatory. Write unit, widget, and BLoC tests. Integration tests for critical flows. Refer to [Testing Guidelines](./testing-guidelines.instructions.md).
- **Error Handling:** Implement robust error handling for all external interactions (API calls, file system, AI models). Display user-friendly error messages. Log errors appropriately for debugging.
- **Performance:** Focus on performance, especially for image processing and AI interactions. Utilize asynchronous operations, show loading indicators, and optimize for mobile device constraints. Consider image compression and memory management for large files.
- **Permissions:** Handle platform-specific permissions (camera, photo gallery, storage) gracefully, providing clear explanations to the user.
- **User Experience (UX):** Strive for a clean, intuitive, and responsive UI. Provide feedback for user actions and background processes.

## Key Feature Implementation Areas & Guidelines

1. **User Authentication:**
   - Secure and straightforward login/registration.
   - Persistent sessions.
   - Refer to: [Authentication Module Instructions](./auth.instructions.md).

2. **Image Selection & Preprocessing:**
   - Gallery and camera access.
   - RAW image support with user notifications for longer processing.
   - Format validation and potential compression.
   - Refer to: [Image Processing Module Instructions](./image-processing.instructions.md).

3. **Tree Marking Interface:**
   - Intuitive tap-to-mark system with `GestureDetector`.
   - Clear visual feedback using `CustomPaint`.
   - Zoom/pan capabilities for precision.
   - Refer to: [Tree Marking Interface Instructions](./tree-marking.instructions.md).

4. **AI-Powered Image Editing:**
   - Integration with Vertex AI Gemini models via `firebase_ai`.
   - Effective prompt engineering for optimal results.
   - Handle AI model responses, including potential errors or content moderation flags.
   - Display loading states and progress indicators during AI processing.
   - Refer to: [AI Integration Guidelines](./ai-integration.instructions.md).

5. **Results Display & Handling:**
   - Side-by-side or toggle comparison of original and edited images.
   - Options to save to device gallery, share, or revert.
   - Consider metadata for saved images.
   - Refer to: [Results Handling Module Instructions](./results-handling.instructions.md).

## Workflow

1. Pick an issue or feature to work on.
2. Create a new branch from `main` or `develop` (as per project branching strategy).
3. Implement the feature, adhering to all relevant guidelines linked in this document.
4. Write necessary tests (unit, widget, BLoC).
5. Ensure all tests pass and linting rules are satisfied.
6. Open a Pull Request, detailing the changes and referencing the issue.

By following these instructions, we aim to build a high-quality, maintainable, and intelligent photo editing application.
