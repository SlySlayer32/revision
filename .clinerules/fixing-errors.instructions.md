---
applyTo: '**/*.dart, **/*.yaml, **/*.md'
---

# VGV Test Implementation & Error Resolution Protocol

**Objective:** This protocol provides strict guidelines for implementing tests and resolving errors within the VGV Clean Architecture. Adherence is mandatory to maintain code quality, test coverage, and project stability.

---

## Phase 1: Foundational Test Structure & Principles

### Step 1: Internalize VGV Three-Layer Testing Approach

**Directive for AI:**

```
ASSIMILATE the VGV testing philosophy, which mirrors the three-layer architecture:

1.  **Presentation Layer Tests:**
    *   **Focus:** UI rendering, widget interactions, BLoC/Cubit state changes and logic.
    *   **Types:** Widget tests, BLoC/Cubit tests, Golden tests.
    *   **Tools:** `flutter_test`, `bloc_test`, `mocktail`.

2.  **Domain Layer Tests:**
    *   **Focus:** Business logic, use case execution, entity validation, repository contract interactions (via mocks).
    *   **Types:** Pure Dart unit tests.
    *   **Tools:** `test`, `mocktail`, `equatable`.
    *   **Coverage Mandate:** 100%.

3.  **Data Layer Tests:**
    *   **Focus:** Repository implementations, data source interactions (API, DB via mocks), model serialization/deserialization.
    *   **Types:** Unit tests (can involve some Flutter test utilities if platform channels are used by data sources, but keep minimal).
    *   **Tools:** `test` or `flutter_test`, `mocktail`.
    *   **Coverage Mandate:** 95%+.

Confirm understanding of test types and responsibilities per layer.
```

### Step 2: Implement VGV Standard Test File Structure

**Directive for AI:**

```
CONSTRUCT and MAINTAIN the test file structure in strict accordance with VGV standards:

1.  **Mirror `lib/` Directory:**
    *   The `test/` directory structure MUST be an exact mirror of the `lib/` directory structure.
    *   For every source file in `lib/`, there should be a corresponding test file in `test/` (unless it's a file not requiring tests, e.g., barrel exports).
    *   Example:
        *   `lib/features/authentication/domain/usecases/sign_in_usecase.dart`
        *   `test/features/authentication/domain/usecases/sign_in_usecase_test.dart`

2.  **File Naming Convention:**
    *   All test files MUST end with the `_test.dart` suffix.
    *   Example: `user_model_test.dart`, `auth_bloc_test.dart`.

3.  **Example Project Structure Mapping:**

    **Source (`lib/`):**
    ```
    lib/
    ├── core/
    │   └── utils/
    │       └── result.dart
    ├── features/
    │   └── authentication/
    │       ├── data/
    │       │   ├── models/
    │       │   │   └── user_model.dart
    │       │   └── repositories/
    │       │       └── auth_repository_impl.dart
    │       ├── domain/
    │       │   └── usecases/
    │       │       └── sign_in_usecase.dart
    │       └── presentation/
    │           ├── blocs/
    │           │   └── auth_bloc.dart
    │           └── widgets/
    │               └── login_form.dart
    └── main_development.dart
    ```

    **Test (`test/`):**
    ```
    test/
    ├── core/
    │   └── utils/
    │       └── result_test.dart
    ├── features/
    │   └── authentication/
    │       ├── data/
    │       │   ├── models/
    │       │   │   └── user_model_test.dart
    │       │   └── repositories/
    │       │       └── auth_repository_impl_test.dart
    │       ├── domain/
    │       │   └── usecases/
    │       │       └── sign_in_usecase_test.dart
    │       └── presentation/
    │           ├── blocs/
    │           │   └── auth_bloc_test.dart
    │           └── widgets/
    │               └── login_form_test.dart
    └── main_development_test.dart // Or app_test.dart for App widget tests
    ```

Adherence to this mirrored structure is critical for navigability and maintainability.
```

---

## Phase 2: Test Implementation by Layer

### Step 3: Execute Test Creation for Each Architectural Layer

**Directive for AI:**

```
IMPLEMENT tests based on the architectural layer of the component under test:

1.  **Data Layer Testing Protocol:**
    *   **Models (DTOs):**
        *   Action: Create unit tests in `test/[feature]/data/models/`.
        *   Focus: Serialization (`fromJson`), deserialization (`toJson`), `copyWith` logic, `Equatable` props.
    *   **Data Sources:**
        *   Action: Create unit tests in `test/[feature]/data/datasources/`.
        *   Focus: Interaction with external services (mocked APIs, DBs), error handling, data mapping.
    *   **Repository Implementations:**
        *   Action: Create unit tests in `test/[feature]/data/repositories/`.
        *   Focus: Correct implementation of domain repository contracts, interaction with data sources (mocked), error mapping from data exceptions to domain failures.

2.  **Domain Layer Testing Protocol:**
    *   **Entities:**
        *   Action: Create unit tests in `test/[feature]/domain/entities/`.
        *   Focus: Business logic within entities (if any), validation rules, `Equatable` props.
    *   **Use Cases:**
        *   Action: Create unit tests in `test/[feature]/domain/usecases/`.
        *   Focus: Core business logic execution, interaction with repository interfaces (mocked), `Result` pattern handling (success/failure paths).
    *   **Abstract Repositories (Interfaces):**
        *   Note: Interfaces themselves are not directly unit tested, but their mock implementations are crucial for testing use cases and other dependent components.

3.  **Presentation Layer Testing Protocol:**
    *   **BLoCs/Cubits:**
        *   Action: Create BLoC/Cubit tests in `test/[feature]/presentation/blocs/` (or `cubits/`).
        *   Focus: State transitions in response to events/method calls, interaction with use cases (mocked), `Equatable` for states/events. Use `bloc_test` package.
    *   **Widgets (Forms, Custom UI):**
        *   Action: Create widget tests in `test/[feature]/presentation/widgets/`.
        *   Focus: Correct rendering, user interactions (taps, input), conditional UI based on state. Use `flutter_test` and `pumpWidget`.
    *   **Pages/Views (Screens):**
        *   Action: Create widget tests in `test/[feature]/presentation/pages/` (or `view/`).
        *   Focus: Composition of widgets, BLoC/Cubit provision, navigation triggers (mocked).
    *   **Integration Tests (for Screens/Flows):**
        *   Location: Typically in a separate `integration_test/` directory at the project root.
        *   Focus: End-to-end user flows involving multiple layers (UI, BLoC, mocked UseCases/Repositories).

Ensure all mocks are provided via `test/helpers/mocks.dart` or feature-specific mock files.
```

### Step 4: Implement Golden Tests for UI Consistency

**Directive for AI:**

```
UTILIZE Golden Tests for critical UI components to ensure visual consistency across changes:

1.  **Placement of Golden Files:**
    *   Store golden image files (`.png`) in a dedicated `goldens/` subdirectory.
    *   Recommended locations:
        *   `test/presentation/widgets/goldens/my_widget.golden.png` (for specific widgets)
        *   `test/goldens/my_page.golden.png` (for pages or larger components)

2.  **Test Implementation:**
    *   Action: Write widget tests that use `matchesGoldenFile` from `flutter_test`.
    *   Example (`test/presentation/widgets/user_card_test.dart`):
        ```dart
        // ...
        testWidgets('UserCard renders correctly (Golden Test)', (tester) async {
          await tester.pumpWidget(MaterialApp(home: UserCard(/* ... */)));
          await expectLater(
            find.byType(UserCard),
            matchesGoldenFile('goldens/user_card.golden.png'), // Path relative to test file or an absolute path from project root
          );
        });
        // ...
        ```

3.  **Generating and Updating Golden Files:**
    *   Run tests with `flutter test --update-goldens` to generate or update golden files when intentional UI changes are made.

Apply golden tests judiciously to components where visual regression is a high risk.
```

---

## Phase 3: Test Organization & Best Practices

### Step 5: Adhere to VGV Testing Best Practices

**Directive for AI:**

```
ENFORCE the following VGV best practices for all test code:

1.  **Mirror Source Structure:** MANDATE that `test/` directory structure precisely mirrors `lib/`. This is non-negotiable for predictability.
2.  **Consistent Naming:** MANDATE the use of the `_test.dart` suffix for all test files.
3.  **Logical Grouping:** ORGANIZE tests within subfolders that match their layer (domain, data, presentation) and feature.
4.  **Descriptive Test Names:** WRITE clear, descriptive names for `group()` and `test()` blocks, outlining the scenario and expected outcome.
5.  **AAA Pattern (Arrange, Act, Assert):** STRUCTURE tests using the Arrange-Act-Assert pattern for clarity.
6.  **Mock Dependencies:** UTILIZE `mocktail` for creating mocks. Store common mocks in `test/helpers/mocks.dart` or `test/helpers/vgv_mocks.dart`.
7.  **Test Data Factory:** EMPLOY `test/helpers/test_data_factory.dart` for generating consistent test data.
8.  **`pumpApp` Helper:** USE `test/helpers/pump_app.dart` for widget tests to provide necessary app context (MaterialApp, BLoC providers).

These practices ensure test suites are maintainable, readable, and effective.
```

### Step 6: Reference Standard Test Structure Summary

**Directive for AI:**

```
CONSULT this summary table for quick reference on VGV test organization:

| Layer         | Test Directory Example (`test/`) | Primary Test Focus                                  | Key Test Types         |
|---------------|---------------------------------|-----------------------------------------------------|------------------------|
| Data          | `[feature]/data/`               | Models, Data Source Interactions, Repo Implementations | Unit Tests             |
| Domain        | `[feature]/domain/`             | Use Cases, Entities, Business Logic                 | Unit Tests (Pure Dart) |
| Presentation  | `[feature]/presentation/`       | Widgets, BLoCs/Cubits, UI Logic, Screen Composition | Widget, BLoC, Golden   |

**Condensed Sample Test Tree:**
```

test/
├── features/
│   └── authentication/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── sign_in_usecase_test.dart
│       └── presentation/
│           ├── blocs/
│           │   └── auth_bloc_test.dart
│           └── widgets/
│               └── login_form_test.dart
├── helpers/
│   ├── pump_app.dart
│   └── mocks.dart
└── ... (other features and core tests)

```

**Concluding Mandate:** The VGV testing approach, centered on mirroring the three-layer architecture within the `test/` directory, is paramount. Strict adherence ensures tests are organized, scalable, and easily navigable, contributing significantly to project quality and maintainability.
