---
applyTo: '**'
---
## Project Context

This repository is a Flutter application architected for modular, feature-first development, with deep integration of Firebase (emulator-first), Gemini API, and automated CI/CD. The codebase is structured for maintainability, testability, and compliance with Very Good Ventures (VGV) standards.

### Architecture & Structure
- **Feature-First:** Each major feature is in its own directory under `lib/feature_name/`.
- **State Management:** Use Cubit/Bloc patterns, but business logic is under `cubit/` (not `blocs/`).
- **UI:** UI screens are in `view/` (not `pages/`).
- **Service Boundaries:**
  - Firebase logic is modularized (see `firebase/`, `integration_test/`, and `FIREBASE_SETUP.md`).
  - Remote config, authentication, and storage are separated (see `FIREBASE_REMOTE_CONFIG_*`).
- **AI Integration:**
  - Gemini API logic is in `lib/main_development.dart` and documented in `docs/GEMINI_*` and `docs/AI_*`.

### Developer Workflows
- **Build & Run:**
  - Use VS Code tasks (see `.vscode/tasks.json`) for all workflows. Example: `Flutter: Run with Gemini API` runs the app with the correct API key and flavor.
- **Testing:**
  - Use `Flutter: Test` for unit tests, `Run Firebase Integration Tests` for emulator-based integration.
  - Coverage is generated and checked via `Analyze & Commit` task.
- **Git Automation:**
  - Use auto-commit and smart commit tasks (`Auto-commit All Changes`, `Safe Auto-commit`).
  - Real-time/on-save commit automation via PowerShell scripts in `scripts/`.
- **Dependency Management:**
  - Use `Update Dependencies` and `Setup Dependabot` tasks for automated updates.

### Project-Specific Conventions
- **VGV Compliance:**
  - Directory/file naming follows VGV standards (see `Commit VGV Compliance Updates` task).
- **Environment Management:**
  - API keys and env variables are managed via `.env` and `Flutter: Setup Environment File` task.
- **Emulator Usage:**
  - Firebase emulators are required for local integration tests; start with `Start Firebase Emulators` task.
- **Documentation:**
  - Architectural/integration decisions are in `docs/` (e.g., `FIREBASE_AI_LOGIC_INTEGRATION_COMPLETE.md`).

### Integration Points
- **Firebase:**
  - Emulator-first; see `firebase.json`, `firestore.rules`, and `integration_test/`.
- **Gemini API:**
  - API keys injected via Dart defines or `.env`.
- **CI/CD:**
  - Dependabot and GitHub Actions automate dependency/workflow management.

### Examples & Patterns
- To run with Gemini API: use `Flutter: Run with Gemini API` VS Code task.
- To test Firebase integration: start emulators, then run `Run Firebase Integration Tests`.
- To update dependencies: run `Update Dependencies` or `Setup Dependabot`.
- For VGV compliance: use `Commit VGV Compliance Updates` task.

### Key Files & Directories
- `lib/feature_name/` — Feature modules
- `lib/main_development.dart` — Gemini API integration
- `firebase/`, `integration_test/` — Firebase logic and emulator tests
- `docs/` — Architectural and integration documentation
- `.vscode/tasks.json` — All major developer workflows
- `scripts/` — Git automation and workflow scripts

---
When generating code, answering questions, or reviewing changes, always:
- Follow the feature-first, VGV-compliant structure
- Use the provided VS Code tasks for builds, tests, and commits
- Reference and update documentation in `docs/` as needed
- Prefer emulator-based and modular approaches for Firebase
- Integrate Gemini API and environment variables as shown in existing patterns