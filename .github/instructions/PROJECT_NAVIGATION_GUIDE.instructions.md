---
applyTo: 'structure'
---
# VGV Clean Architecture - Project Navigation Guide

This document provides a comprehensive navigation guide for the VGV (Very Good Ventures) clean architecture Flutter project. Use this as your primary reference to understand the project structure and quickly locate files across the 3-layer architecture.

## 📁 Project Overview

This project follows VGV's strict 3-layer clean architecture pattern with feature-based organization:

```
🏗️ 3-Layer Architecture:
├── 🎨 Presentation Layer  → UI, Widgets, BLoCs, Pages
├── 🧠 Domain Layer       → Business Logic, Entities, Use Cases
└── 💾 Data Layer         → Repositories, Data Sources, Models
```

## 🗺️ Complete Project Structure Map

### 📂 Root Level Structure
```
web-guide-generator/revision/
├── 📱 lib/                          # Main application code
├── 🧪 test/                         # Test files (mirrors lib/ structure)
├── 📖 docs/                         # Documentation
├── ⚙️ .clinerules/                   # VGV workflow rules
├── 📋 .github/                      # GitHub workflows & prompts
└── 🔧 Configuration files           # pubspec.yaml, analysis_options.yaml, etc.
```

### 📱 Main Application Structure (`lib/`)

#### 🏗️ Core Application Foundation
```
lib/
├── 🚀 main_development.dart         # Development entry point
├── 🚀 main_staging.dart             # Staging entry point  
├── 🚀 main_production.dart          # Production entry point
├── ⚙️ bootstrap.dart                # VGV bootstrap setup
├── 🔥 firebase_options.dart         # Firebase configuration
├── 🌍 l10n/                         # Internationalization
│   ├── l10n.dart                    # Main l10n exports
│   └── arb/                         # Translation files
│       ├── app_en.arb               # English translations
│       └── app_es.arb               # Spanish translations
└── 📱 app/                          # Main app widget
    ├── app.dart                     # App barrel exports
    └── view/
        └── app.dart                 # Main App widget
```

#### 🧰 Core System Components (`lib/core/`)
```
lib/core/
├── 🛠️ constants/                    # Application constants
│   ├── app_constants.dart           # General app constants
│   ├── firebase_constants.dart      # Firebase-specific constants
│   ├── environment_config.dart      # Environment configuration
│   └── constants.dart               # Core constants barrel
├── 🚫 error/                        # Error handling system
│   ├── failures.dart                # VGV failure types (NetworkFailure, AuthenticationFailure, etc.)
│   └── exceptions.dart              # Custom exceptions
├── 🔧 utils/                        # Utility functions
│   ├── validators.dart               # Input validation utilities
│   ├── result.dart                  # Result pattern implementation
│   ├── either_extensions.dart       # Either extension methods
│   └── .gitkeep
├── 🏛️ usecases/                     # Base use case interface
│   └── usecase.dart                 # Abstract UseCase<Type, Params>
├── 🔗 di/                           # Dependency injection
│   └── service_locator.dart         # GetIt service locator setup
├── 🌐 services/                     # Core services
│   ├── ai_service.dart              # AI service interface
│   ├── vertex_ai_service.dart       # Vertex AI implementation
│   ├── circuit_breaker.dart         # Circuit breaker pattern
│   └── circuit_breaker_service.dart # Circuit breaker service
├── 🌐 network/
│   └── .gitkeep
└── 🎨 widgets/
    └── .gitkeep
```

## 🎯 Feature-Based Architecture

### 🔐 Authentication Feature (`lib/features/authentication/`)

#### 🧠 Domain Layer - Business Logic (NO Flutter Dependencies)
```
lib/features/authentication/domain/
├── 📦 domain.dart                   # Barrel export file
├── 👤 entities/                     # Pure business objects
│   ├── user.dart                    # User entity with validation logic
│   └── .gitkeep
├── 📋 repositories/                 # Abstract contracts
│   ├── auth_repository.dart         # Authentication repository interface
│   └── .gitkeep
├── ⚡ usecases/                     # Business operations
│   ├── sign_in_usecase.dart         # Sign in with email/password
│   ├── sign_up_usecase.dart         # Sign up with email/password
│   ├── sign_in_with_google_usecase.dart # Google sign in
│   ├── sign_out_usecase.dart        # Sign out user
│   ├── get_current_user_usecase.dart # Get current user
│   ├── get_current_user_with_claims_usecase.dart # Get user with claims
│   ├── get_custom_claims_usecase.dart # Get custom claims
│   ├── get_auth_state_changes_usecase.dart # Auth state stream
│   ├── send_password_reset_email_usecase.dart # Password reset
│   └── .gitkeep
└── 🚫 exceptions/                   # Domain-specific exceptions
    ├── auth_exception.dart          # Base auth exception
    ├── auth_exceptions.dart         # Specific auth exceptions
    └── .gitkeep
```

#### 💾 Data Layer - Data Management (NO Flutter Dependencies)
```
lib/features/authentication/data/
├── 📦 data.dart                     # Barrel export file
├── 🏛️ repositories/                 # Repository implementations
│   ├── firebase_authentication_repository.dart # Firebase auth implementation
│   └── .gitkeep
├── 🔌 datasources/                  # External data sources
│   ├── firebase_auth_data_source.dart # Firebase auth data source
│   └── .gitkeep
└── 📊 models/                       # Data transfer objects
    ├── user_model.dart              # User model with JSON serialization
    └── .gitkeep
```

#### 🎨 Presentation Layer - UI Components (Flutter Allowed)
```
lib/features/authentication/presentation/
├── 📱 pages/                        # Route-level components
│   ├── authentication_wrapper.dart  # Auth state wrapper
│   ├── welcome_page.dart            # Welcome/landing page
│   ├── login_page.dart              # Login form page
│   └── signup_page.dart             # Signup form page
├── 🎛️ blocs/                        # State management
│   ├── authentication_bloc.dart     # Main auth state management
│   ├── authentication_event.dart    # Auth events
│   ├── authentication_state.dart    # Auth states
│   ├── login_bloc.dart              # Login form state
│   ├── login_event.dart             # Login events
│   ├── login_state.dart             # Login states
│   ├── signup_bloc.dart             # Signup form state
│   ├── signup_event.dart            # Signup events
│   └── signup_state.dart            # Signup states
├── 🧩 widgets/                      # Reusable UI components
│   ├── login_form.dart              # Login form widget
│   ├── signup_form.dart             # Signup form widget
│   └── .gitkeep
├── 👁️ view/
│   └── .gitkeep
└── 🎭 cubit/
    └── .gitkeep
```

### 🏠 Dashboard Feature (`lib/features/dashboard/`)
```
lib/features/dashboard/
├── dashboard.dart                   # Barrel export
└── view/
    └── dashboard_page.dart          # Main dashboard page
```

### 🏠 Home Feature (`lib/features/home/`)
```
lib/features/home/
├── domain/                          # Business logic (placeholder)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                            # Data layer (placeholder)
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── presentation/                    # UI layer (placeholder)
│   ├── cubit/
│   ├── view/
│   └── widgets/
└── view/
    └── home_page.dart               # Main home page
```

### 🖼️ Image Editor Feature (`lib/features/image_editor/`)
```
lib/features/image_editor/
├── domain/                          # Business logic (placeholder)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                            # Data layer (placeholder)
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/                    # UI layer (placeholder)
    ├── cubit/
    ├── view/
    └── widgets/
```

## 🧪 Test Structure (`test/`)

The test structure mirrors the `lib/` structure exactly:

```
test/
├── 🧪 helpers/                      # Test utilities
│   ├── pump_app.dart                # Widget testing helper
│   ├── test_helpers.dart            # General test helpers
│   ├── test_data_factory.dart       # Test data generation
│   ├── mocks.dart                   # Mock objects
│   ├── vgv_mocks.dart               # VGV-specific mocks
│   ├── firebase_test_helper.dart    # Firebase testing utilities
│   ├── firebase_emulator_helper.dart # Firebase emulator setup
│   ├── firebase_auth_helper.dart    # Firebase auth test helpers
│   ├── integration_test_helper.dart  # Integration test utilities
│   ├── golden_test_helper.dart      # Golden file test helpers
│   └── test_credentials_demo.dart   # Demo credentials for testing
└── 🎯 features/                     # Feature tests (mirrors lib/features/)
    ├── authentication/              # Authentication feature tests
    │   ├── domain/                  # Domain layer tests
    │   │   ├── entities/
    │   │   ├── usecases/
    │   │   └── repositories/
    │   ├── data/                    # Data layer tests
    │   │   └── repositories/
    │   └── presentation/            # Presentation layer tests
    │       └── blocs/
    └── dashboard/                   # Dashboard feature tests
        └── view/
```

## 📚 Documentation & Configuration

### 📖 Documentation (`docs/`)
```
docs/
└── VGV-Guide.md                     # VGV architecture explanation
```

### ⚙️ Development Rules (`.clinerules/`)
```
.clinerules/
├── 📋 buildplan.instructions.md     # Build plan overview
├── 🛠️ vgv-foundation.instructions.md # VGV foundation rules
├── 🔧 fixing-errors.md              # Error fixing guidelines
└── 📂 workflows/                    # Step-by-step workflows
    └── Authentication Domain Layer.md # Auth domain implementation guide
```



## 🔍 Quick Navigation Guide

### 📍 Looking for...

#### 🔐 Authentication Logic?
- **Domain**: `lib/features/authentication/domain/`
- **Implementation**: `lib/features/authentication/data/repositories/firebase_authentication_repository.dart`
- **UI**: `lib/features/authentication/presentation/`
- **Tests**: `test/features/authentication/`

#### 🚫 Error Handling?
- **Core Failures**: `lib/core/error/failures.dart`
- **Core Exceptions**: `lib/core/error/exceptions.dart`
- **Auth Exceptions**: `lib/features/authentication/domain/exceptions/`

#### ⚡ Use Cases?
- **Base Interface**: `lib/core/usecases/usecase.dart`
- **Auth Use Cases**: `lib/features/authentication/domain/usecases/`

#### 🔧 Configuration?
- **Environment Setup**: `lib/core/constants/environment_config.dart`
- **Firebase**: `lib/firebase_options.dart`
- **App Constants**: `lib/core/constants/app_constants.dart`

#### 🧪 Test Utilities?
- **All Helpers**: `test/helpers/`
- **Mock Objects**: `test/helpers/mocks.dart`
- **Test Data**: `test/helpers/test_data_factory.dart`

#### 🎨 UI Components?
- **Pages**: Look in `lib/features/[feature]/presentation/pages/`
- **Widgets**: Look in `lib/features/[feature]/presentation/widgets/`
- **State Management**: Look in `lib/features/[feature]/presentation/blocs/`

#### 💾 Data Access?
- **Repository Interfaces**: `lib/features/[feature]/domain/repositories/`
- **Repository Implementations**: `lib/features/[feature]/data/repositories/`
- **Data Sources**: `lib/features/[feature]/data/datasources/`

## 🏗️ VGV Architecture Rules

### ✅ Layer Dependencies (What can import what)
```
🎨 Presentation Layer
├── ✅ Can import: Domain, Flutter, flutter_bloc
├── ❌ Cannot import: Data layer directly
└── 📝 Note: Goes through Domain layer contracts

🧠 Domain Layer  
├── ✅ Can import: Only Dart core libraries, equatable, dartz
├── ❌ Cannot import: Flutter, Data layer, Presentation layer
└── 📝 Note: Pure business logic, no external dependencies

💾 Data Layer
├── ✅ Can import: Domain interfaces, external APIs, databases
├── ❌ Cannot import: Flutter, Presentation layer
└── 📝 Note: Implements Domain contracts, handles data
```

### 🎯 File Organization Patterns

#### 📦 Barrel Exports
Each layer has barrel export files:
- `domain/domain.dart` - Exports all domain components
- `data/data.dart` - Exports all data components
- Feature root: `authentication.dart` - Exports entire feature

#### 🏷️ Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`

#### 📁 Folder Structure Rules
- Always follow the 3-layer pattern
- Use `.gitkeep` files for empty directories
- Group related functionality in features
- Keep core utilities separate from features

## 🚀 Development Workflow

### 🔄 Adding New Features
1. **Create Domain Layer First**
   - Define entities in `domain/entities/`
   - Create repository interface in `domain/repositories/`
   - Implement use cases in `domain/usecases/`
   - Add custom exceptions in `domain/exceptions/`

2. **Implement Data Layer**
   - Create models in `data/models/`
   - Implement data sources in `data/datasources/`
   - Implement repository in `data/repositories/`

3. **Build Presentation Layer**
   - Create BLoCs/Cubits in `presentation/blocs/`
   - Build pages in `presentation/pages/`
   - Create reusable widgets in `presentation/widgets/`

### 🧪 Testing Strategy
- **Domain**: 100% test coverage (business logic)
- **Data**: 95%+ test coverage (repository implementations)
- **Presentation**: 90%+ test coverage (UI components)

### 📋 Key Files to Remember

#### 🔧 Configuration Entry Points
- `lib/bootstrap.dart` - App initialization
- `lib/core/di/service_locator.dart` - Dependency injection setup
- `lib/main_*.dart` - Environment-specific entry points

#### 🏗️ Architecture Foundation
- `lib/core/usecases/usecase.dart` - Base use case pattern
- `lib/core/error/failures.dart` - Error handling foundation
- `lib/core/utils/result.dart` - Result pattern implementation

#### 🔐 Authentication Core
- `lib/features/authentication/domain/domain.dart` - Auth domain exports
- `lib/features/authentication/data/repositories/firebase_authentication_repository.dart` - Main auth implementation

---

## 💡 Pro Tips for Navigation

1. **Use Barrel Exports**: Always import from `domain.dart`, `data.dart` files rather than individual files
2. **Follow the Layers**: When debugging, start from Domain → Data → Presentation
3. **Check Tests**: Tests mirror the structure and often provide usage examples
4. **Use Search**: Look for `.dart` files matching the pattern you need
5. **Follow VGV Patterns**: Consistent structure makes navigation predictable

## 🆘 Quick Troubleshooting

### 🔍 Can't Find a File?
1. Check the corresponding layer (domain/data/presentation)
2. Look in the test folder - structure mirrors lib/
3. Check barrel export files for references
4. Use semantic search for related concepts

### 🚫 Import Errors?
1. Verify layer dependency rules (see Architecture Rules above)
2. Use barrel exports instead of deep imports
3. Check if file exists and is properly exported

### 🧪 Test Failures?
1. Look at test helpers in `test/helpers/`
2. Check mock objects are properly set up
3. Verify test data factory provides valid data
4. Ensure tests follow the same 3-layer structure

---

**Remember**: This VGV clean architecture promotes separation of concerns, testability, and maintainability. When in doubt, follow the 3-layer rule and keep business logic in the domain layer!
