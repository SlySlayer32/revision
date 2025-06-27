---
applyTo: 'project'
---

# 🧭 Enhanced Project Navigation - Complete Development Guide

## 📁 Master Project Architecture Overview

This comprehensive guide provides complete navigation through the Revision Flutter project, built on VGV Clean Architecture principles. Use this as your primary reference for understanding, locating, and implementing features across the entire codebase.

## 🗺️ Complete Directory Structure Map

### 📂 Root Level Organization
```
revision/
├── 📱 lib/                          # Main Flutter application code
├── 🧪 test/                         # Test files (mirrors lib/ structure exactly)
├── 🤖 integration_test/             # End-to-end integration tests
├── 📖 docs/                         # Project documentation
├── ⚙️ .github/                      # GitHub workflows, actions, and issue templates
│   ├── workflows/                   # CI/CD GitHub Actions
│   ├── ISSUE_TEMPLATE/              # Issue templates
│   ├── PULL_REQUEST_TEMPLATE.md     # PR template
│   └── instructions/                # AI-assistant instruction files
├── 🔧 android/                      # Android-specific configuration
├── 🍎 ios/                          # iOS-specific configuration
├── 🌐 web/                          # Web-specific configuration
├── ☁️ functions/                    # Firebase Cloud Functions
├── 📋 scripts/                      # Build and utility scripts
├── 🏗️ build/                        # Generated build files (git-ignored)
├── 📦 .dart_tool/                   # Dart tooling files (git-ignored)
└── 🔧 Configuration Files           # pubspec.yaml, analysis_options.yaml, etc.
```

### 📱 Core Application Structure (`lib/`)

```
lib/
├── 🚀 Entry Points
│   ├── main.dart                    # Production entry point
│   ├── main_development.dart        # Development environment entry
│   ├── main_staging.dart            # Staging environment entry
│   └── main_production.dart         # Production environment entry
├── ⚙️ bootstrap.dart                # App initialization and bootstrap logic
├── 🔥 Firebase Configuration
│   ├── firebase_options.dart        # Main Firebase options
│   ├── firebase_options_dev.dart    # Development Firebase config
│   ├── firebase_options_staging.dart # Staging Firebase config
│   └── firebase_options_prod.dart   # Production Firebase config
├── 🌍 l10n/                         # Internationalization
│   ├── l10n.dart                    # Localization exports
│   └── arb/                         # Application Resource Bundle files
│       ├── app_en.arb               # English translations
│       ├── app_es.arb               # Spanish translations
│       └── app_*.arb                # Additional language files
├── 📱 app/                          # Main app widget and configuration
│   ├── app.dart                     # Main app widget
│   ├── view/                        # App-level views
│   └── app_bloc_observer.dart       # Global BLoC observer
├── 🧰 core/                         # Core system components (detailed below)
└── 🎯 features/                     # Feature-based modules (detailed below)
```

## 🧰 Core System Components Deep Dive (`lib/core/`)

### Complete Core Architecture
```
lib/core/
├── 🛠️ constants/                    # Application-wide constants
│   ├── app_constants.dart           # General app constants
│   ├── firebase_constants.dart      # Firebase-specific constants
│   ├── ai_constants.dart            # AI/ML related constants
│   ├── environment_config.dart      # Environment configuration
│   ├── route_constants.dart         # Navigation route constants
│   ├── api_constants.dart           # API endpoints and configuration
│   └── constants.dart               # Core constants barrel export
├── 🚫 error/                        # Comprehensive error handling
│   ├── failures.dart                # VGV failure types
│   │   ├── NetworkFailure           # Network-related failures
│   │   ├── AuthenticationFailure    # Authentication failures
│   │   ├── ValidationFailure        # Input validation failures
│   │   ├── ServerFailure            # Server/API failures
│   │   ├── CacheFailure             # Local storage failures
│   │   ├── PermissionFailure        # Device permission failures
│   │   └── AIProcessingFailure      # AI/ML processing failures
│   ├── exceptions.dart              # Custom exceptions
│   └── error_handler.dart           # Global error handling
├── 🔧 utils/                        # Utility functions and helpers
│   ├── validators.dart               # Input validation utilities
│   ├── formatters.dart              # Text formatters
│   ├── image_utils.dart             # Image processing utilities
│   ├── date_utils.dart              # Date/time utilities
│   ├── crypto_utils.dart            # Encryption/hashing utilities
│   ├── file_utils.dart              # File handling utilities
│   ├── network_utils.dart           # Network utilities
│   ├── permission_utils.dart        # Permission handling
│   ├── result.dart                  # Result pattern implementation
│   ├── either_extensions.dart       # Either extension methods
│   ├── string_extensions.dart       # String extensions
│   ├── context_extensions.dart      # BuildContext extensions
│   └── logger.dart                  # Logging utilities
├── 🏛️ usecases/                     # Base use case interfaces
│   ├── usecase.dart                 # Abstract UseCase<Type, Params>
│   ├── stream_usecase.dart          # Stream-based use cases
│   └── future_usecase.dart          # Future-based use cases
├── 🔗 di/                           # Dependency injection
│   ├── service_locator.dart         # GetIt service locator setup
│   ├── injection_container.dart     # Main DI container
│   ├── feature_injections/          # Feature-specific injections
│   │   ├── auth_injection.dart      # Authentication DI
│   │   ├── image_editor_injection.dart # Image editing DI
│   │   └── ai_processing_injection.dart # AI processing DI
│   └── external_injections.dart     # External service injections
├── 🌐 services/                     # Core services
│   ├── ai_service.dart              # AI service interface
│   ├── vertex_ai_service.dart       # Vertex AI implementation
│   ├── image_service.dart           # Image processing service
│   ├── storage_service.dart         # Local storage service
│   ├── notification_service.dart    # Push notification service
│   ├── analytics_service.dart       # Analytics service
│   ├── crash_reporting_service.dart # Crash reporting service
│   ├── performance_service.dart     # Performance monitoring
│   ├── circuit_breaker.dart         # Circuit breaker pattern
│   └── circuit_breaker_service.dart # Circuit breaker service
├── 🌐 network/                      # Network layer
│   ├── network_info.dart            # Network connectivity info
│   ├── api_client.dart              # HTTP client wrapper
│   ├── interceptors/                # HTTP interceptors
│   │   ├── auth_interceptor.dart    # Authentication interceptor
│   │   ├── logging_interceptor.dart # Request/response logging
│   │   └── retry_interceptor.dart   # Automatic retry logic
│   └── endpoints.dart               # API endpoint definitions
├── 💾 local_storage/                # Local data persistence
│   ├── shared_preferences_service.dart # Shared preferences wrapper
│   ├── secure_storage_service.dart  # Secure storage wrapper
│   ├── cache_service.dart           # Caching service
│   └── database_service.dart        # Local database service
├── 🎨 widgets/                      # Core reusable widgets
│   ├── custom_app_bar.dart          # Custom app bar widget
│   ├── loading_overlay.dart         # Loading overlay widget
│   ├── error_widget.dart            # Error display widget
│   ├── empty_state_widget.dart      # Empty state widget
│   ├── custom_button.dart           # Custom button widget
│   ├── custom_text_field.dart       # Custom text input widget
│   ├── image_picker_widget.dart     # Image picker widget
│   ├── confirmation_dialog.dart     # Confirmation dialog
│   └── snackbar_helper.dart         # Snackbar utilities
├── 🎨 theme/                        # App theming and styling
│   ├── app_theme.dart               # Main theme configuration
│   ├── colors.dart                  # Color palette
│   ├── typography.dart              # Text styles
│   ├── spacing.dart                 # Spacing constants
│   ├── shadows.dart                 # Shadow definitions
│   └── animations.dart              # Animation configurations
├── 🧭 navigation/                   # Navigation system
│   ├── app_router.dart              # Main router configuration
│   ├── route_generator.dart         # Route generation logic
│   ├── navigation_service.dart      # Navigation service
│   └── route_guards.dart            # Route protection logic
├── 🔐 security/                     # Security utilities
│   ├── encryption_service.dart      # Data encryption
│   ├── key_management.dart          # Secure key management
│   └── biometric_auth.dart          # Biometric authentication
└── 📊 monitoring/                   # App monitoring and telemetry
    ├── analytics_tracker.dart       # Analytics tracking
    ├── performance_monitor.dart     # Performance monitoring
    ├── crash_reporter.dart          # Crash reporting
    └── logger_config.dart           # Logging configuration
```

## 🎯 Feature-Based Architecture Deep Dive

### 🔐 Authentication Feature (`lib/features/authentication/`)

#### Complete Authentication Architecture
```
lib/features/authentication/
├── 📦 authentication.dart           # Main barrel export
├── 🧠 domain/                       # Business logic layer
│   ├── 📦 domain.dart               # Domain barrel export
│   ├── 👤 entities/                 # Pure business objects
│   │   ├── user.dart                # User entity
│   │   ├── auth_credentials.dart    # Authentication credentials
│   │   ├── auth_token.dart          # Authentication token
│   │   ├── user_profile.dart        # Extended user profile
│   │   └── auth_session.dart        # Authentication session
│   ├── 📋 repositories/             # Abstract contracts
│   │   ├── auth_repository.dart     # Authentication repository interface
│   │   └── user_repository.dart     # User data repository interface
│   ├── ⚡ usecases/                 # Business operations
│   │   ├── sign_in_with_email_usecase.dart      # Email/password sign in
│   │   ├── sign_up_with_email_usecase.dart      # Email/password sign up
│   │   ├── sign_in_with_google_usecase.dart     # Google sign in
│   │   ├── sign_in_with_apple_usecase.dart      # Apple sign in
│   │   ├── sign_out_usecase.dart                # Sign out user
│   │   ├── get_current_user_usecase.dart        # Get current user
│   │   ├── update_user_profile_usecase.dart     # Update user profile
│   │   ├── delete_account_usecase.dart          # Delete user account
│   │   ├── verify_email_usecase.dart            # Email verification
│   │   ├── reset_password_usecase.dart          # Password reset
│   │   ├── change_password_usecase.dart         # Change password
│   │   ├── refresh_token_usecase.dart           # Refresh auth token
│   │   ├── get_auth_state_changes_usecase.dart  # Auth state stream
│   │   └── validate_token_usecase.dart          # Token validation
│   └── 🚫 exceptions/               # Domain-specific exceptions
│       ├── auth_exceptions.dart     # Authentication exceptions
│       └── user_exceptions.dart     # User-related exceptions
├── 💾 data/                         # Data management layer
│   ├── 📦 data.dart                 # Data barrel export
│   ├── 🏛️ repositories/             # Repository implementations
│   │   ├── firebase_auth_repository.dart        # Firebase auth implementation
│   │   └── user_repository_impl.dart            # User repository implementation
│   ├── 🔌 datasources/              # External data sources
│   │   ├── remote/                  # Remote data sources
│   │   │   ├── firebase_auth_data_source.dart   # Firebase auth API
│   │   │   ├── google_auth_data_source.dart     # Google auth API
│   │   │   └── apple_auth_data_source.dart      # Apple auth API
│   │   └── local/                   # Local data sources
│   │       ├── auth_local_data_source.dart      # Local auth storage
│   │       └── user_local_data_source.dart      # Local user storage
│   └── 📊 models/                   # Data transfer objects
│       ├── user_model.dart          # User data model
│       ├── auth_response_model.dart # Auth response model
│       ├── token_model.dart         # Token data model
│       └── profile_model.dart       # Profile data model
└── 🎨 presentation/                 # UI and user interaction layer
    ├── 📱 pages/                    # Route-level components
    │   ├── authentication_wrapper.dart          # Auth state wrapper
    │   ├── welcome_page.dart                    # Welcome/landing page
    │   ├── login_page.dart                      # Login form page
    │   ├── signup_page.dart                     # Signup form page
    │   ├── forgot_password_page.dart            # Password reset page
    │   ├── email_verification_page.dart         # Email verification page
    │   ├── profile_page.dart                    # User profile page
    │   └── account_settings_page.dart           # Account settings page
    ├── 🎛️ blocs/                    # State management
    │   ├── authentication/          # Main authentication state
    │   │   ├── authentication_bloc.dart         # Main auth BLoC
    │   │   ├── authentication_event.dart        # Auth events
    │   │   └── authentication_state.dart        # Auth states
    │   ├── login/                   # Login form state
    │   │   ├── login_bloc.dart                  # Login form BLoC
    │   │   ├── login_event.dart                 # Login events
    │   │   └── login_state.dart                 # Login states
    │   ├── signup/                  # Signup form state
    │   │   ├── signup_bloc.dart                 # Signup form BLoC
    │   │   ├── signup_event.dart                # Signup events
    │   │   └── signup_state.dart                # Signup states
    │   └── profile/                 # Profile management state
    │       ├── profile_bloc.dart                # Profile BLoC
    │       ├── profile_event.dart               # Profile events
    │       └── profile_state.dart               # Profile states
    └── 🧩 widgets/                  # Reusable UI components
        ├── auth_text_field.dart                 # Custom auth text fields
        ├── social_login_button.dart             # Social login buttons
        ├── password_strength_indicator.dart     # Password strength widget
        ├── email_verification_widget.dart       # Email verification UI
        ├── profile_avatar_widget.dart           # Profile avatar display
        ├── auth_error_widget.dart               # Authentication error display
        └── loading_auth_button.dart             # Loading button state
```

### 🖼️ Image Editor Feature (`lib/features/image_editor/`)

#### Complete Image Editor Architecture
```
lib/features/image_editor/
├── 📦 image_editor.dart             # Main barrel export
├── 🧠 domain/                       # Business logic layer
│   ├── 📦 domain.dart               # Domain barrel export
│   ├── 🖼️ entities/                 # Pure business objects
│   │   ├── processed_image.dart     # Main processed image entity
│   │   ├── image_metadata.dart      # Image metadata
│   │   ├── editing_session.dart     # Editing session data
│   │   ├── mask_data.dart           # Mask information
│   │   ├── drawing_point.dart       # Drawing point data
│   │   ├── editing_tool.dart        # Editing tool configuration
│   │   └── image_transformation.dart # Image transformation data
│   ├── 📋 repositories/             # Abstract contracts
│   │   ├── image_repository.dart    # Image handling repository
│   │   ├── mask_repository.dart     # Mask data repository
│   │   └── editing_repository.dart  # Editing session repository
│   ├── ⚡ usecases/                 # Business operations
│   │   ├── image_selection/         # Image selection use cases
│   │   │   ├── pick_image_from_gallery_usecase.dart
│   │   │   ├── take_photo_usecase.dart
│   │   │   └── validate_image_usecase.dart
│   │   ├── image_processing/        # Image processing use cases
│   │   │   ├── resize_image_usecase.dart
│   │   │   ├── compress_image_usecase.dart
│   │   │   ├── rotate_image_usecase.dart
│   │   │   └── crop_image_usecase.dart
│   │   ├── mask_creation/           # Mask creation use cases
│   │   │   ├── create_mask_usecase.dart
│   │   │   ├── edit_mask_usecase.dart
│   │   │   ├── clear_mask_usecase.dart
│   │   │   └── validate_mask_usecase.dart
│   │   ├── image_storage/           # Image storage use cases
│   │   │   ├── save_image_usecase.dart
│   │   │   ├── delete_image_usecase.dart
│   │   │   ├── upload_image_usecase.dart
│   │   │   └── download_image_usecase.dart
│   │   └── editing_session/         # Session management use cases
│   │       ├── start_editing_session_usecase.dart
│   │       ├── save_editing_session_usecase.dart
│   │       ├── load_editing_session_usecase.dart
│   │       └── end_editing_session_usecase.dart
│   └── 🚫 exceptions/               # Domain-specific exceptions
│       ├── image_exceptions.dart    # Image-related exceptions
│       ├── mask_exceptions.dart     # Mask-related exceptions
│       └── editing_exceptions.dart  # Editing-related exceptions
├── 💾 data/                         # Data management layer
│   ├── 📦 data.dart                 # Data barrel export
│   ├── 🏛️ repositories/             # Repository implementations
│   │   ├── image_repository_impl.dart           # Image repository impl
│   │   ├── mask_repository_impl.dart            # Mask repository impl
│   │   └── editing_repository_impl.dart         # Editing repository impl
│   ├── 🔌 datasources/              # External data sources
│   │   ├── remote/                  # Remote data sources
│   │   │   ├── firebase_storage_data_source.dart    # Firebase storage API
│   │   │   ├── firestore_data_source.dart           # Firestore API
│   │   │   └── cloud_functions_data_source.dart     # Cloud Functions API
│   │   └── local/                   # Local data sources
│   │       ├── image_picker_data_source.dart        # Device image picker
│   │       ├── file_storage_data_source.dart        # Local file storage
│   │       └── cache_data_source.dart               # Local cache
│   └── 📊 models/                   # Data transfer objects
│       ├── processed_image_model.dart           # Processed image model
│       ├── image_metadata_model.dart            # Image metadata model
│       ├── editing_session_model.dart           # Editing session model
│       ├── mask_data_model.dart                 # Mask data model
│       └── drawing_point_model.dart             # Drawing point model
└── 🎨 presentation/                 # UI and user interaction layer
    ├── 📱 pages/                    # Route-level components
    │   ├── image_editor_page.dart               # Main editor page
    │   ├── image_selection_page.dart            # Image selection page
    │   ├── gallery_page.dart                    # Image gallery page
    │   ├── image_preview_page.dart              # Image preview page
    │   └── editing_history_page.dart            # Editing history page
    ├── 🎛️ blocs/                    # State management
    │   ├── image_editor/            # Main editor state
    │   │   ├── image_editor_bloc.dart           # Main editor BLoC
    │   │   ├── image_editor_event.dart          # Editor events
    │   │   └── image_editor_state.dart          # Editor states
    │   ├── image_selection/         # Image selection state
    │   │   ├── image_selection_bloc.dart        # Selection BLoC
    │   │   ├── image_selection_event.dart       # Selection events
    │   │   └── image_selection_state.dart       # Selection states
    │   ├── mask_creation/           # Mask creation state
    │   │   ├── mask_creation_bloc.dart          # Mask BLoC
    │   │   ├── mask_creation_event.dart         # Mask events
    │   │   └── mask_creation_state.dart         # Mask states
    │   └── gallery/                 # Gallery state
    │       ├── gallery_bloc.dart                # Gallery BLoC
    │       ├── gallery_event.dart               # Gallery events
    │       └── gallery_state.dart               # Gallery states
    └── 🧩 widgets/                  # Reusable UI components
        ├── drawing_canvas.dart                  # Custom drawing canvas
        ├── image_viewer.dart                    # Image display widget
        ├── tool_palette.dart                    # Editing tools palette
        ├── mask_overlay.dart                    # Mask overlay widget
        ├── zoom_controls.dart                   # Zoom control widget
        ├── undo_redo_controls.dart              # Undo/redo buttons
        ├── export_options_widget.dart           # Export options
        ├── image_thumbnail.dart                 # Thumbnail widget
        └── progress_indicator_widget.dart       # Processing progress
```

### 🤖 AI Processing Feature (`lib/features/ai_processing/`)

#### Complete AI Processing Architecture
```
lib/features/ai_processing/
├── 📦 ai_processing.dart            # Main barrel export
├── 🧠 domain/                       # Business logic layer
│   ├── 📦 domain.dart               # Domain barrel export
│   ├── 🤖 entities/                 # Pure business objects
│   │   ├── ai_processing_request.dart       # AI processing request
│   │   ├── ai_processing_result.dart        # AI processing result
│   │   ├── image_analysis.dart              # Image analysis data
│   │   ├── generated_content.dart           # Generated content data
│   │   ├── processing_status.dart           # Processing status
│   │   ├── ai_model_config.dart             # AI model configuration
│   │   └── content_generation_params.dart   # Generation parameters
│   ├── 📋 repositories/             # Abstract contracts
│   │   ├── ai_repository.dart       # AI processing repository
│   │   ├── model_repository.dart    # Model management repository
│   │   └── prompt_repository.dart   # Prompt management repository
│   ├── ⚡ usecases/                 # Business operations
│   │   ├── image_analysis/          # Image analysis use cases
│   │   │   ├── analyze_image_usecase.dart
│   │   │   ├── detect_objects_usecase.dart
│   │   │   ├── generate_description_usecase.dart
│   │   │   └── extract_metadata_usecase.dart
│   │   ├── content_generation/      # Content generation use cases
│   │   │   ├── generate_image_usecase.dart
│   │   │   ├── inpaint_image_usecase.dart
│   │   │   ├── remove_objects_usecase.dart
│   │   │   └── enhance_image_usecase.dart
│   │   ├── prompt_engineering/      # Prompt engineering use cases
│   │   │   ├── create_prompt_usecase.dart
│   │   │   ├── optimize_prompt_usecase.dart
│   │   │   └── validate_prompt_usecase.dart
│   │   └── model_management/        # Model management use cases
│   │       ├── load_model_usecase.dart
│   │       ├── switch_model_usecase.dart
│   │       └── get_model_info_usecase.dart
│   └── 🚫 exceptions/               # Domain-specific exceptions
│       ├── ai_processing_exceptions.dart    # AI processing exceptions
│       ├── model_exceptions.dart            # Model-related exceptions
│       └── prompt_exceptions.dart           # Prompt-related exceptions
├── 💾 data/                         # Data management layer
│   ├── 📦 data.dart                 # Data barrel export
│   ├── 🏛️ repositories/             # Repository implementations
│   │   ├── vertex_ai_repository.dart           # Vertex AI implementation
│   │   ├── gemini_repository.dart              # Gemini AI implementation
│   │   └── prompt_repository_impl.dart         # Prompt repository impl
│   ├── 🔌 datasources/              # External data sources
│   │   ├── remote/                  # Remote data sources
│   │   │   ├── vertex_ai_data_source.dart      # Vertex AI API
│   │   │   ├── gemini_data_source.dart         # Gemini AI API
│   │   │   └── cloud_functions_ai_source.dart  # Cloud Functions AI API
│   │   └── local/                   # Local data sources
│   │       ├── model_cache_data_source.dart    # Model caching
│   │       └── prompt_cache_data_source.dart   # Prompt caching
│   └── 📊 models/                   # Data transfer objects
│       ├── ai_request_model.dart               # AI request model
│       ├── ai_response_model.dart              # AI response model
│       ├── image_analysis_model.dart           # Image analysis model
│       ├── generation_result_model.dart        # Generation result model
│       └── model_config_model.dart             # Model config model
└── 🎨 presentation/                 # UI and user interaction layer
    ├── 📱 pages/                    # Route-level components
    │   ├── ai_processing_page.dart              # Main AI processing page
    │   ├── image_analysis_page.dart             # Image analysis page
    │   ├── content_generation_page.dart         # Content generation page
    │   ├── prompt_editor_page.dart              # Prompt editing page
    │   └── processing_results_page.dart         # Results display page
    ├── 🎛️ blocs/                    # State management
    │   ├── ai_processing/           # Main AI processing state
    │   │   ├── ai_processing_bloc.dart          # Main AI BLoC
    │   │   ├── ai_processing_event.dart         # AI events
    │   │   └── ai_processing_state.dart         # AI states
    │   ├── image_analysis/          # Image analysis state
    │   │   ├── image_analysis_bloc.dart         # Analysis BLoC
    │   │   ├── image_analysis_event.dart        # Analysis events
    │   │   └── image_analysis_state.dart        # Analysis states
    │   └── content_generation/      # Content generation state
    │       ├── content_generation_bloc.dart     # Generation BLoC
    │       ├── content_generation_event.dart    # Generation events
    │       └── content_generation_state.dart    # Generation states
    └── 🧩 widgets/                  # Reusable UI components
        ├── ai_processing_widget.dart            # Main processing widget
        ├── analysis_results_widget.dart         # Analysis results display
        ├── generation_preview_widget.dart       # Generation preview
        ├── prompt_input_widget.dart             # Prompt input field
        ├── model_selector_widget.dart           # Model selection
        ├── processing_progress_widget.dart      # Processing progress
        └── ai_error_widget.dart                 # AI error display
```

## 🧪 Testing Architecture (`test/`)

### Complete Test Structure
```
test/
├── 🧪 unit/                         # Unit tests
│   ├── core/                        # Core component tests
│   │   ├── constants/               # Constants tests
│   │   ├── error/                   # Error handling tests
│   │   ├── utils/                   # Utility function tests
│   │   ├── services/                # Service tests
│   │   └── usecases/                # Base usecase tests
│   └── features/                    # Feature unit tests
│       ├── authentication/          # Authentication tests
│       │   ├── domain/              # Domain layer tests
│       │   │   ├── entities/        # Entity tests
│       │   │   ├── repositories/    # Repository interface tests
│       │   │   └── usecases/        # Use case tests
│       │   ├── data/                # Data layer tests
│       │   │   ├── datasources/     # Data source tests
│       │   │   ├── models/          # Model tests
│       │   │   └── repositories/    # Repository implementation tests
│       │   └── presentation/        # Presentation layer tests
│       │       ├── blocs/           # BLoC tests
│       │       └── widgets/         # Widget unit tests
│       ├── image_editor/            # Image editor tests
│       └── ai_processing/           # AI processing tests
├── 🎨 widget/                       # Widget tests
│   ├── authentication/              # Authentication widget tests
│   ├── image_editor/                # Image editor widget tests
│   └── ai_processing/               # AI processing widget tests
├── 🔗 integration/                  # Integration tests
│   ├── firebase_integration_test.dart       # Firebase integration
│   ├── ai_integration_test.dart             # AI service integration
│   ├── authentication_flow_test.dart       # Auth flow integration
│   └── image_processing_flow_test.dart     # Image processing flow
├── 📚 helpers/                      # Test utilities and helpers
│   ├── mocks/                       # Mock objects
│   │   ├── mock_repositories.dart   # Repository mocks
│   │   ├── mock_services.dart       # Service mocks
│   │   ├── mock_data_sources.dart   # Data source mocks
│   │   └── mock_firebase.dart       # Firebase mocks
│   ├── test_data/                   # Test data factories
│   │   ├── test_users.dart          # User test data
│   │   ├── test_images.dart         # Image test data
│   │   └── test_ai_responses.dart   # AI response test data
│   ├── factories/                   # Object factories
│   │   ├── entity_factory.dart      # Entity factories
│   │   ├── model_factory.dart       # Model factories
│   │   └── response_factory.dart    # Response factories
│   ├── matchers/                    # Custom matchers
│   │   ├── custom_matchers.dart     # Custom test matchers
│   │   └── bloc_matchers.dart       # BLoC-specific matchers
│   └── utilities/                   # Test utilities
│       ├── pump_app.dart            # Widget pump helper
│       ├── test_environment.dart    # Test environment setup
│       └── golden_test_helper.dart  # Golden test utilities
└── ⚙️ fixtures/                     # Static test data
    ├── images/                      # Test images
    │   ├── test_image_1.jpg         # Sample test image
    │   ├── test_image_2.png         # Sample test image
    │   └── test_mask.png             # Sample mask image
    ├── json/                        # JSON test data
    │   ├── user_response.json        # User API response
    │   ├── ai_analysis_response.json # AI analysis response
    │   └── error_responses.json      # Error response samples
    └── configurations/              # Configuration files
        ├── test_firebase_config.json # Test Firebase config
        └── test_environment_config.json # Test environment config
```

## 🤖 Integration Testing (`integration_test/`)

### Integration Test Structure
```
integration_test/
├── driver.dart                      # Integration test driver
├── 🔗 authentication/               # Authentication integration tests
│   ├── email_auth_test.dart         # Email authentication flow
│   ├── google_auth_test.dart        # Google authentication flow
│   └── auth_state_test.dart         # Authentication state tests
├── 🖼️ image_processing/             # Image processing integration tests
│   ├── image_selection_test.dart    # Image selection flow
│   ├── mask_creation_test.dart      # Mask creation flow
│   └── image_export_test.dart       # Image export flow
├── 🤖 ai_processing/                # AI processing integration tests
│   ├── image_analysis_test.dart     # Image analysis flow
│   ├── content_generation_test.dart # Content generation flow
│   └── prompt_processing_test.dart  # Prompt processing flow
├── 🔥 firebase/                     # Firebase integration tests
│   ├── firestore_test.dart          # Firestore operations
│   ├── storage_test.dart            # Firebase Storage operations
│   └── functions_test.dart          # Cloud Functions tests
└── 🌊 user_journeys/                # Complete user journey tests
    ├── complete_editing_flow_test.dart      # End-to-end editing flow
    ├── onboarding_flow_test.dart            # User onboarding flow
    └── account_management_flow_test.dart    # Account management flow
```

## 📖 Documentation (`docs/`)

### Documentation Structure
```
docs/
├── 📋 README.md                     # Main project documentation
├── 🏗️ architecture/                 # Architecture documentation
│   ├── clean_architecture.md       # Clean architecture guide
│   ├── dependency_injection.md     # DI implementation guide
│   ├── state_management.md         # State management guide
│   └── error_handling.md           # Error handling strategy
├── 🔥 firebase/                     # Firebase documentation
│   ├── setup.md                    # Firebase setup guide
│   ├── authentication.md           # Authentication configuration
│   ├── firestore.md                # Firestore usage guide
│   ├── storage.md                  # Storage configuration
│   └── functions.md                # Cloud Functions guide
├── 🤖 ai/                           # AI integration documentation
│   ├── vertex_ai_setup.md          # Vertex AI setup
│   ├── gemini_integration.md       # Gemini API integration
│   ├── prompt_engineering.md       # Prompt engineering guide
│   └── model_management.md         # AI model management
├── 🚀 deployment/                   # Deployment documentation
│   ├── build_process.md            # Build process guide
│   ├── ci_cd.md                    # CI/CD pipeline setup
│   ├── environment_setup.md        # Environment configuration
│   └── release_process.md          # Release process guide
├── 🧪 testing/                      # Testing documentation
│   ├── testing_strategy.md         # Testing strategy overview
│   ├── unit_testing.md             # Unit testing guide
│   ├── widget_testing.md           # Widget testing guide
│   └── integration_testing.md      # Integration testing guide
├── 📱 platform_specific/            # Platform-specific guides
│   ├── android_setup.md            # Android configuration
│   ├── ios_setup.md                # iOS configuration
│   └── web_setup.md                # Web configuration
└── 🔧 development/                  # Development guides
    ├── getting_started.md           # Getting started guide
    ├── coding_standards.md          # Coding standards
    ├── contribution_guide.md        # Contribution guidelines
    └── troubleshooting.md           # Troubleshooting guide
```

## 🎯 Quick Navigation Commands

### VS Code Navigation Tips
```json
// .vscode/settings.json - Quick navigation settings
{
  "files.associations": {
    "*.dart": "dart"
  },
  "search.exclude": {
    "**/build/**": true,
    "**/.dart_tool/**": true,
    "**/android/.gradle/**": true,
    "**/ios/Pods/**": true
  },
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.enableSdkFormatter": true,
  "dart.lineLength": 80
}
```

### File Search Patterns
```bash
# Search for specific file types
**/*.dart                     # All Dart files
**/domain/**/*.dart          # All domain layer files
**/presentation/blocs/**     # All BLoC files
**/test/**/*_test.dart       # All test files
**/lib/features/**           # All feature files

# Search for specific patterns
**/usecase*.dart             # All use case files
**/repository*.dart          # All repository files
**/model*.dart               # All model files
**/bloc*.dart                # All BLoC files
```

### Quick Access Shortcuts
```
Ctrl+P (Cmd+P on Mac) + type:
- main.dart                  → Main application entry
- bootstrap.dart             → App bootstrap
- service_locator.dart       → Dependency injection
- app_router.dart            → Navigation configuration
- auth_bloc.dart             → Authentication state
- image_editor_bloc.dart     → Image editor state
- ai_processing_bloc.dart    → AI processing state
```

## 🔍 Feature Location Guide

### Finding Specific Components

#### Authentication Components
```
🔐 Authentication:
├── Entities: lib/features/authentication/domain/entities/
├── Use Cases: lib/features/authentication/domain/usecases/
├── Repository: lib/features/authentication/domain/repositories/
├── Data Sources: lib/features/authentication/data/datasources/
├── Models: lib/features/authentication/data/models/
├── BLoCs: lib/features/authentication/presentation/blocs/
├── Pages: lib/features/authentication/presentation/pages/
└── Widgets: lib/features/authentication/presentation/widgets/
```

#### Image Editor Components
```
🖼️ Image Editor:
├── Entities: lib/features/image_editor/domain/entities/
├── Use Cases: lib/features/image_editor/domain/usecases/
├── Repository: lib/features/image_editor/domain/repositories/
├── Data Sources: lib/features/image_editor/data/datasources/
├── Models: lib/features/image_editor/data/models/
├── BLoCs: lib/features/image_editor/presentation/blocs/
├── Pages: lib/features/image_editor/presentation/pages/
└── Widgets: lib/features/image_editor/presentation/widgets/
```

#### AI Processing Components
```
🤖 AI Processing:
├── Entities: lib/features/ai_processing/domain/entities/
├── Use Cases: lib/features/ai_processing/domain/usecases/
├── Repository: lib/features/ai_processing/domain/repositories/
├── Data Sources: lib/features/ai_processing/data/datasources/
├── Models: lib/features/ai_processing/data/models/
├── BLoCs: lib/features/ai_processing/presentation/blocs/
├── Pages: lib/features/ai_processing/presentation/pages/
└── Widgets: lib/features/ai_processing/presentation/widgets/
```

This comprehensive navigation guide provides complete visibility into the Revision project structure, enabling efficient development, maintenance, and feature implementation across the entire codebase.
