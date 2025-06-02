---
applyTo: "**"
---
# VGV Architecture Layer Instructions for Copilot

## CRITICAL: Always specify which layer you're working in

### When prompting Copilot, ALWAYS include layer context:

**Data Layer** (`lib/data/`):
- "Create a DataSource for [feature] in the Data Layer with NO Flutter dependencies"
- "Implement API client for [service] - Data Layer only, raw data retrieval"

**Repository Layer** (`lib/domain/repositories/`):
- "Implement [Feature]Repository in Repository Layer, compose data sources, apply business rules, NO Flutter dependencies"

**Business Logic Layer** (`lib/presentation/bloc/`):
- "Create [Feature]Bloc for Business Logic Layer, NO Flutter SDK imports, use flutter_bloc"

**Presentation Layer** (`lib/presentation/`):
- "Build [Feature]Screen widget for Presentation Layer, NO business logic in widgets"

## Layer Dependency Rules for Copilot:
- Data & Repository Layers: NEVER import Flutter
- Business Logic Layer: NEVER import Flutter, only dart: and flutter_bloc
- Presentation Layer: Only layer that can import Flutter widgets
```