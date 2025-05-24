---
applyTo: "**/view/**/*_page.dart,**/view/**/*_view.dart"
---
# BLoC/Cubit Widget Structure Guidelines

This document outlines the recommended structure for integrating BLoC/Cubit managed state into Flutter widgets within this project. This pattern promotes separation of concerns, testability, and maintainability.

Refer also to [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) for details on BLoC/Cubit logic.

## Core Pattern: Page > View > Specialized Widgets

Flutter UI that interacts with a BLoC or Cubit should generally be structured into three levels:

1.  **Page (`*_page.dart`)**:
    *   **Responsibility**: Primarily responsible for providing the BLoC/Cubit instance to its widget subtree.
    *   It typically uses `BlocProvider` to create and provide the BLoC/Cubit.
    *   It may handle route arguments or dependencies needed by the BLoC/Cubit itself.
    *   It should contain minimal UI logic, often just instantiating the `View`.
    *   **Example**: `CounterPage` in `lib/counter/view/counter_page.dart`.

    ```dart
    // Example: feature_name_page.dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    // Assuming your BLoC and View are structured like this:
    // import 'package:your_app/features/feature_name/bloc/feature_name_bloc.dart';
    // import 'package:your_app/features/feature_name/view/feature_name_view.dart';
    // For a generic example, let's assume these paths:
    import '../bloc/feature_name_bloc.dart'; // Adjusted path
    import './feature_name_view.dart'; // Adjusted path
    // import 'package:your_app/service_locator.dart'; // Assuming get_it for dependency injection

    class FeatureNamePage extends StatelessWidget {
      const FeatureNamePage({super.key});

      static Route<void> route() {
        return MaterialPageRoute<void>(builder: (_) => const FeatureNamePage());
      }

      @override
      Widget build(BuildContext context) {
        return BlocProvider(
          // create: (_) => sl<FeatureNameBloc>(), // Or direct instantiation if no complex dependencies
          create: (_) => FeatureNameBloc(), // Simplified for example
          child: const FeatureNameView(),
        );
      }
    }
    ```

2.  **View (`*_view.dart`)**:
    *   **Responsibility**: Builds the UI based on the BLoC/Cubit state.
    *   It consumes the BLoC/Cubit provided by the `Page` using `BlocBuilder`, `BlocListener`, or `BlocConsumer`.
    *   It composes various smaller, specialized widgets to construct the overall UI for the feature.
    *   It dispatches events to the BLoC or calls methods on the Cubit in response to user interactions.
    *   **Example**: `CounterView` in `lib/counter/view/counter_page.dart`.

    ```dart
    // Example: feature_name_view.dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    // Assuming your BLoC and State are structured like this:
    // import 'package:your_app/features/feature_name/bloc/feature_name_bloc.dart';
    // import 'package:your_app/features/feature_name/bloc/feature_name_state.dart';
    // import 'package:your_app/features/feature_name/bloc/feature_name_event.dart';
    // For a generic example, let's assume these paths:
    import '../bloc/feature_name_bloc.dart'; // Adjusted path
    import '../bloc/feature_name_state.dart'; // Adjusted path
    import '../bloc/feature_name_event.dart'; // Adjusted path
    // Import specialized widgets

    class FeatureNameView extends StatelessWidget {
      const FeatureNameView({super.key});

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Feature Name')),
          body: BlocBuilder<FeatureNameBloc, FeatureNameState>(
            builder: (context, state) {
              // Adjust state checking based on your actual state classes
              if (state is FeatureNameLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              // Example for a loaded state
              // if (state is FeatureNameLoaded) {
              //   return Center(child: Text('Data: ${state.data}'));
              // }
              // Example for an error state
              // if (state is FeatureNameError) {
              //   return Center(child: Text('Error: ${state.message}'));
              // }
              // Fallback or initial state UI
              return const Center(child: Text('Feature Name View - Initial or Default State'));
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Dispatch event to BLoC
              context.read<FeatureNameBloc>().add(FeatureNameRequested());
            },
            child: const Icon(Icons.refresh),
          ),
        );
      }
    }
    ```

3.  **Specialized Widgets (`widgets/` directory within the feature)**:
    *   **Responsibility**: Represent smaller, reusable parts of the UI.
    *   These widgets might be stateless or stateful (using Flutter's `StatefulWidget` if they have local, ephemeral UI state not relevant to the BLoC).
    *   They receive data and callbacks from the `View`.
    *   If they need to interact with the BLoC directly (less common for deeply nested widgets, prefer passing callbacks), they can access it via `context.read<BlocName>()` or `context.watch<BlocName>()`.
    *   **Example**: The `FloatingActionButton`s in `CounterView` could be extracted into their own widgets if they became more complex.

## Benefits

- **Clear Separation**: `Page` handles BLoC provision, `View` handles UI construction and BLoC interaction, and specialized widgets handle specific UI elements.
- **Testability**:
    - `Page`s are simple and often don't require extensive widget testing for their own logic.
    - `View`s can be tested by providing a mock BLoC/Cubit and asserting UI changes based on different states.
    - Specialized widgets can be tested in isolation.
- **Readability & Maintainability**: Code is organized logically, making it easier to understand and modify.
- **Reusability**: Specialized widgets can be reused across different views if designed generically.

## When to Deviate

- For very simple screens, the `Page` and `View` might be combined into a single widget if the BLoC provision is straightforward and the UI is minimal. However, starting with the separated structure is generally recommended for consistency and scalability.
- Global BLoCs/Cubits (e.g., for Authentication, Theme) might be provided higher up in the widget tree (e.g., in `App` or `MaterialApp.builder`) and consumed directly by multiple Pages/Views.

Always ensure that BLoCs/Cubits are disposed of correctly by Flutter's widget lifecycle when using `BlocProvider`.
