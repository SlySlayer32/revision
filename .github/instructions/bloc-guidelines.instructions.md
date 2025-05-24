---
applyTo: "**/*bloc.dart,**/*cubit.dart,**/*state.dart,**/*event.dart"
---
# BLoC & Cubit Implementation Guidelines

## General Structure

- Use the `flutter_bloc` package for BLoC pattern implementation
- Choose between BLoC and Cubit based on complexity:
  - Use Cubit for simpler state management with fewer events
  - Use BLoC for complex flows with clear event-state transitions
- One BLoC/Cubit per feature or logical unit of functionality
- Keep BLoCs/Cubits focused on a single responsibility

## State Design

- Create immutable state classes extending `Equatable`
- Include all data needed to render the UI in the state
- Define clear, descriptive state types (e.g., `FeatureNameInitial`, `FeatureNameLoading`, `FeatureNameLoaded`, `FeatureNameError` - replace `FeatureName` with the actual feature).
- Use sealed classes or enums for state status when applicable (e.g., `SubmissionStatus.initial`, `SubmissionStatus.loading`, `SubmissionStatus.success`, `SubmissionStatus.failure`).
- Include previous state data when transitioning to new states *only if necessary* to prevent data loss for UI continuity (e.g., keeping existing list data visible while loading more items).

```dart
// Example state implementation
abstract class ImageEditorState extends Equatable {
  const ImageEditorState();
  
  @override
  List<Object?> get props => [];
}

class ImageEditorInitial extends ImageEditorState {
  const ImageEditorInitial();
}

class ImageEditorLoading extends ImageEditorState {
  const ImageEditorLoading();
}

class ImageEditorLoaded extends ImageEditorState {
  final File image;
  final List<Point> markers;
  
  const ImageEditorLoaded({required this.image, this.markers = const []});
  
  @override
  List<Object?> get props => [image, markers];
  
  ImageEditorLoaded copyWith({
    File? image,
    List<Point>? markers,
  }) {
    return ImageEditorLoaded(
      image: image ?? this.image,
      markers: markers ?? this.markers,
    );
  }
}

class ImageEditorError extends ImageEditorState {
  final String message;
  
  const ImageEditorError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

## Event Design (for BLoC)

- Create clear, descriptive event classes extending `Equatable`
- Use noun-verb naming convention for events (e.g., `LoadImageRequested`, `MarkerAddedToUi` - be specific about the action and context).
- Include all data needed to process the event
- Design events to be immutable
- Group related events in a single file

```dart
// Example event implementation
abstract class ImageEditorEvent extends Equatable {
  const ImageEditorEvent();
  
  @override
  List<Object?> get props => [];
}

class ImageSelected extends ImageEditorEvent {
  final File image;
  
  const ImageSelected(this.image);
  
  @override
  List<Object?> get props => [image];
}

class MarkerAdded extends ImageEditorEvent {
  final Point position;
  
  const MarkerAdded(this.position);
  
  @override
  List<Object?> get props => [position];
}
```

## BLoC/Cubit Implementation

- Keep methods small and focused on a single responsibility.
- Handle errors appropriately and emit corresponding error states.
- Use repository pattern for data access: BLoCs/Cubits should interact with UseCases from the Domain layer, which in turn use Repository interfaces. (Refer to [Architecture Guidelines](./architecture-guidelines.instructions.md)).
- Use dependency injection (e.g., `get_it`) for external dependencies like UseCases or Repositories.
- Document complex state transitions or business logic within the BLoC/Cubit.
- Implement proper resource disposal in `close()` method

```dart
// Example Cubit implementation
class ImageEditorCubit extends Cubit<ImageEditorState> {
  final ImageRepository _imageRepository;
  
  ImageEditorCubit({required ImageRepository imageRepository})
      : _imageRepository = imageRepository,
        super(const ImageEditorInitial());
  
  Future<void> selectImage(File image) async {
    emit(const ImageEditorLoading());
    try {
      final processedImage = await _imageRepository.processImage(image);
      emit(ImageEditorLoaded(image: processedImage));
    } catch (e) {
      emit(ImageEditorError('Failed to process image: $e'));
    }
  }
  
  void addMarker(Point position) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      final updatedMarkers = List<Point>.from(currentState.markers)..add(position);
      emit(currentState.copyWith(markers: updatedMarkers));
    }
  }
  
  @override
  Future<void> close() {
    // Clean up resources
    return super.close();
  }
}
```

## UI Integration with Page/View Pattern

- **Provider Scope**: BLoCs/Cubits should be provided at the page level using a dedicated `[FeatureName]Page` widget. This widget's primary role is to set up the `BlocProvider`.
- **UI Structure**: The `BlocProvider`'s child should be a `[FeatureName]View` widget, which handles the main layout and UI construction.
- **State Consumption**:
    - The `[FeatureName]View` widget can delegate UI rendering to smaller, specialized widgets.
    - These specialized widgets should consume state using `context.select((BlocName cubit) => cubit.state.relevantPartOfState)` for optimal performance, rebuilding only when the selected part changes.
- **Event Dispatch**: Events are dispatched or Cubit methods are called using `context.read<BlocName>()` from within the `View` or specialized widgets.
- **Detailed Structure**: For a comprehensive guide on this widget structure, refer to the `bloc_widget_structure.instructions.md` file (ensure this file exists and is correctly named). This pattern ensures a clean separation of concerns between state management logic and UI rendering.

## BLoC Testing

- Test all state transitions
- Mock dependencies using `mocktail` or `mockito`
- Test error handling
- Use `bloc_test` package for streamlined testing
- Verify that the correct events lead to the correct states

```dart
// Example BLoC test
void main() {
  late ImageEditorCubit imageEditorCubit;
  late MockImageRepository mockImageRepository;
  
  setUp(() {
    mockImageRepository = MockImageRepository();
    imageEditorCubit = ImageEditorCubit(
      imageRepository: mockImageRepository,
    );
  });
  
  tearDown(() {
    imageEditorCubit.close();
  });
  
  blocTest<ImageEditorCubit, ImageEditorState>(
    'emits [ImageEditorLoading, ImageEditorLoaded] when selectImage is called successfully',
    build: () {
      when(() => mockImageRepository.processImage(any()))
          .thenAnswer((_) async => File('path/to/processed_image.jpg'));
      return imageEditorCubit;
    },
    act: (cubit) => cubit.selectImage(File('path/to/image.jpg')),
    expect: () => [
      isA<ImageEditorLoading>(),
      isA<ImageEditorLoaded>(),
    ],
  );
}
```

## BLoC Observability

- Implement BlocObserver for debugging and logging
- Log state transitions during development
- Consider using DevTools for BLoC visualization
- Use meaningful names for events and states to make logs readable
