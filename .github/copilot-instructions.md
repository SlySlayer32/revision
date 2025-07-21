# Copilot Instructions for AI Coding Agents

## Project Overview
This project is a Flutter-based application with deep integration of Firebase services, Gemini API, and advanced automation for CI/CD and code quality. The codebase is organized for feature-first development, with a focus on modularity, testability, and compliance with Very Good Ventures (VGV) standards.

## Architecture & Structure
- **Feature-First Organization:**
  - Major features are separated into their own directories (e.g., `lib/feature_name/`).
  - Business logic is organized using Cubit/Bloc patterns (see `cubit/` instead of `blocs/`).
  - UI pages are under `view/` instead of `pages/`.
- **Service Boundaries:**
  - Firebase integration is handled via `firebase/` and `integration_test/` for emulator-based testing.
  - Remote config, authentication, and storage are modularized (see `FIREBASE_REMOTE_CONFIG_*` and `FIREBASE_SETUP.md`).
- **AI Integration:**
  - Gemini API is integrated for advanced features (see `GEMINI_API_INTEGRATION_COMPLETE.md`, `lib/main_development.dart`).
  - AI logic and enhancements are documented in `docs/AI_*` and `docs/GEMINI_*` files.

## Developer Workflows
- **Build & Run:**
  - Use VS Code tasks for all major workflows (see `.vscode/tasks.json`).
  - Example: `Flutter: Run with Gemini API` task runs the app with the correct API key and flavor.
- **Testing:**
  - Run `Flutter: Test` for unit tests, `Run Firebase Integration Tests` for emulator-based integration.
  - Coverage is generated and checked via `Analyze & Commit` task.
- **Git Automation:**
  - Multiple auto-commit and smart commit tasks are available (see `Auto-commit All Changes`, `Safe Auto-commit`).
  - Real-time and on-save commit automation is supported via PowerShell scripts in `scripts/`.
- **Dependency Management:**
  - Use `Update Dependencies` and `Setup Dependabot` tasks for automated updates.

## Project-Specific Conventions
- **VGV Compliance:**
  - Directory and file naming follows VGV standards (see `Commit VGV Compliance Updates` task and related docs).
- **Environment Management:**
  - API keys and environment variables are managed via `.env` and `Flutter: Setup Environment File` task.
- **Emulator Usage:**
  - Firebase emulators are required for local integration tests; start with `Start Firebase Emulators` task.
- **Documentation:**
  - Key architectural and integration decisions are documented in `docs/` (e.g., `FIREBASE_AI_LOGIC_INTEGRATION_COMPLETE.md`).

## Integration Points
- **Firebase:**
  - Emulator-first development; see `firebase.json`, `firestore.rules`, and `integration_test/`.
- **Gemini API:**
  - All API keys are injected via Dart defines or `.env`.
- **CI/CD:**
  - Dependabot and GitHub Actions are configured for automated dependency and workflow management.

## Examples
- To run the app with Gemini API: use the `Flutter: Run with Gemini API` VS Code task.
- To test Firebase integration: start emulators, then run `Run Firebase Integration Tests`.
- To update dependencies: run `Update Dependencies` or `Setup Dependabot`.

---

**For more details, see the `docs/` directory and VS Code tasks.**
