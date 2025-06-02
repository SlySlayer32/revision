---
applyTo: '**'
---


## 1. **VGV Three-Layer Approach Overview**

- **Presentation Layer:** UI, widgets, screens, blocs/cubits, etc.
- **Domain Layer:** Business logic, use cases, entities, repositories (abstract).
- **Data Layer:** Data sources (API, database), repository implementations, models.

---

## 2. **Recommended Test File Structure**

### **A. Standard VGV Test Structure**

VGV recommends mirroring your `lib/` structure in your `test/` directory. For each layer, create a corresponding folder under `test/` and match the file/folder names and hierarchy.

**Example Project Structure:**

```
lib/
├── data/
│   ├── models/
│   ├── repositories/
│   └── data_source.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
├── presentation/
│   ├── blocs/
│   ├── screens/
│   └── widgets/
└── main_development.dart

test/
├── data/
│   ├── models/
│   ├── repositories/
│   └── data_source_test.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
├── presentation/
│   ├── blocs/
│   ├── screens/
│   └── widgets/
└── main_development-test.dart
```

### **B. Example: File Mapping**

| Source File (lib/)                             | Test File (test/)                      |
|------------------------------------------------|----------------------------------------|
| `lib/data/models/user_model.dart`              | `test/data/models/user_model_test.dart`|
| `lib/domain/use_cases/get_user.dart`           | `test/domain/use_cases/get_user_test.dart`|
| `lib/presentation/blocs/user_bloc.dart`        | `test/presentation/blocs/user_bloc_test.dart`|
| `lib/presentation/widgets/user_card.dart`      | `test/presentation/widgets/user_card_test.dart`|

---

## 3. **Test Types by Layer**

- **Data Layer:**  
  - Unit tests for models, data sources, and repository implementations.
- **Domain Layer:**  
  - Unit tests for use cases, entities, and abstract repositories.
- **Presentation Layer:**  
  - Widget tests for UI components.
  - Bloc/cubit tests for state management.
  - Integration tests for screens (sometimes in a separate `integration_test/` directory).

---

## 4. **Golden Tests**

- Place golden files in a `goldens/` directory at the root or inside `test/presentation/widgets/` as appropriate.
- Example: `test/presentation/widgets/goldens/user_card.golden.png`

---

## 5. **Summary Table**

| Layer         | Directory Example              | Test Focus                    |
|---------------|-------------------------------|-------------------------------|
| Data          | `test/data/`                  | Models, data sources, repos   |
| Domain        | `test/domain/`                | Use cases, entities           |
| Presentation  | `test/presentation/`          | Widgets, blocs, screens       |

---

## 6. **Best Practices**

- **Mirror the structure:** Always keep the test folder structure in sync with your source code for easy navigation and maintainability.
- **Naming:** Use the `_test.dart` suffix for all test files.
- **Organization:** Group related tests in subfolders matching their layer and feature.

---

## 7. **Sample Tree (Condensed)**

```
test/
├── data/
│   └── repositories/
│       └── user_repository_test.dart
├── domain/
│   └── use_cases/
│       └── get_user_test.dart
└── presentation/
    ├── blocs/
    │   └── user_bloc_test.dart
    └── widgets/
        └── user_card_test.dart
```

---

**In summary:**  
**VGV’s approach is to mirror your three-layer architecture in the `test/` directory, matching the structure and naming of your `lib/` code.** This keeps tests organized, scalable, and easy for teams to navigate and maintain.

---
Answer from Perplexity: pplx.ai/share