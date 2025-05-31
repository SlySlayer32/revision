# Image Editor Presentation Layer Implementation

## Context
Building the presentation layer for the image editor feature, including the BLoC state management, custom UI components for image editing with marker system, and responsive design. This layer provides the complete user interface for editing images with AI assistance.

## Implementation Requirements

### 1. BLoC State Management

Create comprehensive state management for image editing:

```dart
// lib/image_editor/presentation/bloc/image_editor_bloc.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/edited_image.dart';
import '../../domain/entities/image_marker.dart';
import '../../domain/usecases/load_image_usecase.dart';
import '../../domain/usecases/add_marker_usecase.dart';
import '../../domain/usecases/remove_marker_usecase.dart';
import '../../domain/usecases/update_marker_usecase.dart';
import '../../domain/usecases/process_image_usecase.dart';
import '../../domain/usecases/get_all_images_usecase.dart';
import '../../domain/usecases/watch_image_usecase.dart';

part 'image_editor_event.dart';
part 'image_editor_state.dart';

class ImageEditorBloc extends Bloc<ImageEditorEvent, ImageEditorState> {
  ImageEditorBloc({
    required this.loadImageUseCase,
    required this.addMarkerUseCase,
    required this.removeMarkerUseCase,
    required this.updateMarkerUseCase,
    required this.processImageUseCase,
    required this.getAllImagesUseCase,
    required this.watchImageUseCase,
  }) : super(const ImageEditorInitial()) {
    on<LoadImageRequested>(_onLoadImageRequested);
    on<AddMarkerRequested>(_onAddMarkerRequested);
    on<RemoveMarkerRequested>(_onRemoveMarkerRequested);
    on<UpdateMarkerRequested>(_onUpdateMarkerRequested);
    on<ProcessImageRequested>(_onProcessImageRequested);
    on<CancelProcessingRequested>(_onCancelProcessingRequested);
    on<GetAllImagesRequested>(_onGetAllImagesRequested);
    on<WatchImageRequested>(_onWatchImageRequested);
    on<ImageUpdated>(_onImageUpdated);
    on<MarkerModeToggled>(_onMarkerModeToggled);
    on<MarkerTypeChanged>(_onMarkerTypeChanged);
    on<ZoomChanged>(_onZoomChanged);
    on<ImagePositionChanged>(_onImagePositionChanged);
  }

  final LoadImageUseCase loadImageUseCase;
  final AddMarkerUseCase addMarkerUseCase;
  final RemoveMarkerUseCase removeMarkerUseCase;
  final UpdateMarkerUseCase updateMarkerUseCase;
  final ProcessImageUseCase processImageUseCase;
  final GetAllImagesUseCase getAllImagesUseCase;
  final WatchImageUseCase watchImageUseCase;

  StreamSubscription<EditedImage>? _imageSubscription;

  Future<void> _onLoadImageRequested(
    LoadImageRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    emit(const ImageEditorLoading());

    final result = await loadImageUseCase(event.imagePath);
    
    result.fold(
      (failure) => emit(ImageEditorError(failure.message)),
      (image) {
        emit(ImageEditorLoaded(
          image: image,
          markerMode: false,
          selectedMarkerType: MarkerType.userDefined,
          zoomLevel: 1.0,
          imagePosition: const ImagePosition(x: 0, y: 0),
        ));
        
        // Start watching for image updates
        add(WatchImageRequested(image.id));
      },
    );
  }

  Future<void> _onAddMarkerRequested(
    AddMarkerRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ImageEditorLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await addMarkerUseCase(
      imageId: currentState.image.id,
      marker: event.marker,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (updatedImage) => emit(currentState.copyWith(
        image: updatedImage,
        isUpdating: false,
        error: null,
      )),
    );
  }

  Future<void> _onRemoveMarkerRequested(
    RemoveMarkerRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ImageEditorLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await removeMarkerUseCase(
      imageId: currentState.image.id,
      markerId: event.markerId,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (updatedImage) => emit(currentState.copyWith(
        image: updatedImage,
        isUpdating: false,
        error: null,
      )),
    );
  }

  Future<void> _onUpdateMarkerRequested(
    UpdateMarkerRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ImageEditorLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await updateMarkerUseCase(
      imageId: currentState.image.id,
      marker: event.marker,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (updatedImage) => emit(currentState.copyWith(
        image: updatedImage,
        isUpdating: false,
        error: null,
      )),
    );
  }

  Future<void> _onProcessImageRequested(
    ProcessImageRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ImageEditorLoaded) return;

    emit(currentState.copyWith(isProcessing: true));

    final result = await processImageUseCase(
      imageId: currentState.image.id,
      prompt: event.prompt,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isProcessing: false,
        error: failure.message,
      )),
      (processedImage) => emit(currentState.copyWith(
        image: processedImage,
        isProcessing: false,
        error: null,
      )),
    );
  }

  Future<void> _onCancelProcessingRequested(
    CancelProcessingRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ImageEditorLoaded) return;

    // Cancel processing logic would be implemented here
    emit(currentState.copyWith(isProcessing: false));
  }

  Future<void> _onGetAllImagesRequested(
    GetAllImagesRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    emit(const ImageEditorLoading());

    final result = await getAllImagesUseCase();
    
    result.fold(
      (failure) => emit(ImageEditorError(failure.message)),
      (images) => emit(ImageGalleryLoaded(images: images)),
    );
  }

  Future<void> _onWatchImageRequested(
    WatchImageRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    await _imageSubscription?.cancel();
    
    _imageSubscription = watchImageUseCase(event.imageId).listen(
      (updatedImage) => add(ImageUpdated(updatedImage)),
      onError: (error) => emit(ImageEditorError(error.toString())),
    );
  }

  void _onImageUpdated(
    ImageUpdated event,
    Emitter<ImageEditorState> emit,
  ) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      emit(currentState.copyWith(image: event.image));
    }
  }

  void _onMarkerModeToggled(
    MarkerModeToggled event,
    Emitter<ImageEditorState> emit,
  ) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      emit(currentState.copyWith(markerMode: !currentState.markerMode));
    }
  }

  void _onMarkerTypeChanged(
    MarkerTypeChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      emit(currentState.copyWith(selectedMarkerType: event.markerType));
    }
  }

  void _onZoomChanged(
    ZoomChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      emit(currentState.copyWith(zoomLevel: event.zoomLevel));
    }
  }

  void _onImagePositionChanged(
    ImagePositionChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final currentState = state;
    if (currentState is ImageEditorLoaded) {
      emit(currentState.copyWith(imagePosition: event.position));
    }
  }

  @override
  Future<void> close() {
    _imageSubscription?.cancel();
    return super.close();
  }
}
```

```dart
// lib/image_editor/presentation/bloc/image_editor_event.dart
part of 'image_editor_bloc.dart';

abstract class ImageEditorEvent extends Equatable {
  const ImageEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadImageRequested extends ImageEditorEvent {
  const LoadImageRequested(this.imagePath);

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

class AddMarkerRequested extends ImageEditorEvent {
  const AddMarkerRequested(this.marker);

  final ImageMarker marker;

  @override
  List<Object?> get props => [marker];
}

class RemoveMarkerRequested extends ImageEditorEvent {
  const RemoveMarkerRequested(this.markerId);

  final String markerId;

  @override
  List<Object?> get props => [markerId];
}

class UpdateMarkerRequested extends ImageEditorEvent {
  const UpdateMarkerRequested(this.marker);

  final ImageMarker marker;

  @override
  List<Object?> get props => [marker];
}

class ProcessImageRequested extends ImageEditorEvent {
  const ProcessImageRequested(this.prompt);

  final String prompt;

  @override
  List<Object?> get props => [prompt];
}

class CancelProcessingRequested extends ImageEditorEvent {
  const CancelProcessingRequested();
}

class GetAllImagesRequested extends ImageEditorEvent {
  const GetAllImagesRequested();
}

class WatchImageRequested extends ImageEditorEvent {
  const WatchImageRequested(this.imageId);

  final String imageId;

  @override
  List<Object?> get props => [imageId];
}

class ImageUpdated extends ImageEditorEvent {
  const ImageUpdated(this.image);

  final EditedImage image;

  @override
  List<Object?> get props => [image];
}

class MarkerModeToggled extends ImageEditorEvent {
  const MarkerModeToggled();
}

class MarkerTypeChanged extends ImageEditorEvent {
  const MarkerTypeChanged(this.markerType);

  final MarkerType markerType;

  @override
  List<Object?> get props => [markerType];
}

class ZoomChanged extends ImageEditorEvent {
  const ZoomChanged(this.zoomLevel);

  final double zoomLevel;

  @override
  List<Object?> get props => [zoomLevel];
}

class ImagePositionChanged extends ImageEditorEvent {
  const ImagePositionChanged(this.position);

  final ImagePosition position;

  @override
  List<Object?> get props => [position];
}
```

```dart
// lib/image_editor/presentation/bloc/image_editor_state.dart
part of 'image_editor_bloc.dart';

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
  const ImageEditorLoaded({
    required this.image,
    required this.markerMode,
    required this.selectedMarkerType,
    required this.zoomLevel,
    required this.imagePosition,
    this.isUpdating = false,
    this.isProcessing = false,
    this.error,
  });

  final EditedImage image;
  final bool markerMode;
  final MarkerType selectedMarkerType;
  final double zoomLevel;
  final ImagePosition imagePosition;
  final bool isUpdating;
  final bool isProcessing;
  final String? error;

  @override
  List<Object?> get props => [
        image,
        markerMode,
        selectedMarkerType,
        zoomLevel,
        imagePosition,
        isUpdating,
        isProcessing,
        error,
      ];

  ImageEditorLoaded copyWith({
    EditedImage? image,
    bool? markerMode,
    MarkerType? selectedMarkerType,
    double? zoomLevel,
    ImagePosition? imagePosition,
    bool? isUpdating,
    bool? isProcessing,
    String? error,
  }) {
    return ImageEditorLoaded(
      image: image ?? this.image,
      markerMode: markerMode ?? this.markerMode,
      selectedMarkerType: selectedMarkerType ?? this.selectedMarkerType,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      imagePosition: imagePosition ?? this.imagePosition,
      isUpdating: isUpdating ?? this.isUpdating,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class ImageGalleryLoaded extends ImageEditorState {
  const ImageGalleryLoaded({required this.images});

  final List<EditedImage> images;

  @override
  List<Object?> get props => [images];
}

class ImageEditorError extends ImageEditorState {
  const ImageEditorError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ImagePosition extends Equatable {
  const ImagePosition({required this.x, required this.y});

  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}
```

### 2. Main Image Editor Screen

```dart
// lib/image_editor/presentation/pages/image_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/image_editor_bloc.dart';
import '../widgets/image_editor_view.dart';
import '../widgets/marker_tools_panel.dart';
import '../widgets/processing_controls.dart';
import '../widgets/zoom_controls.dart';
import '../../domain/entities/edited_image.dart';

class ImageEditorPage extends StatelessWidget {
  const ImageEditorPage({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<ImageEditorBloc>()
        ..add(LoadImageRequested(imagePath)),
      child: const ImageEditorView(),
    );
  }
}

class ImageEditorView extends StatelessWidget {
  const ImageEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          BlocBuilder<ImageEditorBloc, ImageEditorState>(
            builder: (context, state) {
              if (state is ImageEditorLoaded) {
                return IconButton(
                  icon: Icon(
                    state.markerMode ? Icons.pan_tool : Icons.edit,
                    semanticLabel: state.markerMode 
                        ? 'Exit marker mode'
                        : 'Enter marker mode',
                  ),
                  onPressed: () {
                    context.read<ImageEditorBloc>().add(
                      const MarkerModeToggled(),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ImageEditorBloc, ImageEditorState>(
        listener: (context, state) {
          if (state is ImageEditorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          
          if (state is ImageEditorLoaded && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ImageEditorInitial() => const Center(
                child: Text('Ready to load image'),
              ),
            ImageEditorLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ImageEditorLoaded() => _buildLoadedView(context, state),
            ImageEditorError() => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            _ => const Center(child: Text('Unknown state')),
          };
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, ImageEditorLoaded state) {
    return Column(
      children: [
        // Processing controls
        if (state.isProcessing || state.image.processingStatus == ProcessingStatus.processing)
          const ProcessingControls(),
        
        // Main editor area
        Expanded(
          child: Stack(
            children: [
              // Image editor view
              InteractiveImageEditor(
                image: state.image,
                markerMode: state.markerMode,
                selectedMarkerType: state.selectedMarkerType,
                zoomLevel: state.zoomLevel,
                imagePosition: state.imagePosition,
              ),
              
              // Marker tools panel
              if (state.markerMode)
                Positioned(
                  left: 16,
                  top: 16,
                  child: MarkerToolsPanel(
                    selectedMarkerType: state.selectedMarkerType,
                    onMarkerTypeChanged: (type) {
                      context.read<ImageEditorBloc>().add(
                        MarkerTypeChanged(type),
                      );
                    },
                  ),
                ),
              
              // Zoom controls
              Positioned(
                right: 16,
                bottom: 16,
                child: ZoomControls(
                  zoomLevel: state.zoomLevel,
                  onZoomChanged: (zoom) {
                    context.read<ImageEditorBloc>().add(
                      ZoomChanged(zoom),
                    );
                  },
                ),
              ),
              
              // Loading overlay
              if (state.isUpdating)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
        
        // Bottom controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isProcessing ? null : () {
                    _showProcessingDialog(context);
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Process with AI'),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  _showImageInfo(context, state.image);
                },
                icon: const Icon(Icons.info_outline),
                tooltip: 'Image Information',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProcessingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('AI Processing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Processing Prompt',
                hintText: 'Describe what you want to do with this image...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (prompt) {
                if (prompt.trim().isNotEmpty) {
                  context.read<ImageEditorBloc>().add(
                    ProcessImageRequested(prompt),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get prompt from text field and process
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _showImageInfo(BuildContext context, EditedImage image) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${image.id}'),
            Text('Created: ${image.createdAt}'),
            Text('Markers: ${image.markers.length}'),
            Text('Status: ${image.processingStatus.name}'),
            if (image.aiPrompt != null)
              Text('Last prompt: ${image.aiPrompt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

### 3. Interactive Image Editor Widget

```dart
// lib/image_editor/presentation/widgets/interactive_image_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/edited_image.dart';
import '../../domain/entities/image_marker.dart';
import '../bloc/image_editor_bloc.dart';
import 'marker_overlay.dart';

class InteractiveImageEditor extends StatefulWidget {
  const InteractiveImageEditor({
    super.key,
    required this.image,
    required this.markerMode,
    required this.selectedMarkerType,
    required this.zoomLevel,
    required this.imagePosition,
  });

  final EditedImage image;
  final bool markerMode;
  final MarkerType selectedMarkerType;
  final double zoomLevel;
  final ImagePosition imagePosition;

  @override
  State<InteractiveImageEditor> createState() => _InteractiveImageEditorState();
}

class _InteractiveImageEditorState extends State<InteractiveImageEditor> {
  final TransformationController _transformationController = 
      TransformationController();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _updateTransformation();
  }

  @override
  void didUpdateWidget(InteractiveImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoomLevel != widget.zoomLevel ||
        oldWidget.imagePosition != widget.imagePosition) {
      _updateTransformation();
    }
  }

  void _updateTransformation() {
    final matrix = Matrix4.identity()
      ..scale(widget.zoomLevel)
      ..translate(widget.imagePosition.x, widget.imagePosition.y);
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      onInteractionUpdate: (details) {
        if (!widget.markerMode) {
          final matrix = _transformationController.value;
          final translation = matrix.getTranslation();
          final scale = matrix.getMaxScaleOnAxis();
          
          context.read<ImageEditorBloc>().add(
            ZoomChanged(scale),
          );
          context.read<ImageEditorBloc>().add(
            ImagePositionChanged(ImagePosition(
              x: translation.x,
              y: translation.y,
            )),
          );
        }
      },
      child: GestureDetector(
        onTapDown: widget.markerMode ? _handleMarkerTap : null,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[100],
          child: Stack(
            children: [
              // Main image
              Center(
                child: Image.memory(
                  widget.image.processedImageData ?? widget.image.originalImageData,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              
              // Marker overlay
              if (widget.image.markers.isNotEmpty)
                MarkerOverlay(
                  markers: widget.image.markers,
                  imageSize: _getImageSize(),
                  onMarkerTap: _handleMarkerTap,
                  onMarkerDrag: _handleMarkerDrag,
                  editMode: widget.markerMode,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Size _getImageSize() {
    // This would calculate the actual rendered image size
    // For now, return a placeholder size
    return const Size(400, 300);
  }

  void _handleMarkerTap(TapDownDetails details) {
    if (!widget.markerMode) return;

    final localPosition = details.localPosition;
    final imageSize = _getImageSize();
    
    // Convert screen coordinates to image coordinates
    final normalizedX = localPosition.dx / imageSize.width;
    final normalizedY = localPosition.dy / imageSize.height;
    
    // Check if tapping on existing marker
    final existingMarker = _findMarkerAtPosition(localPosition);
    
    if (existingMarker != null) {
      _showMarkerOptions(existingMarker);
    } else {
      // Create new marker
      final marker = ImageMarker(
        id: _uuid.v4(),
        position: MarkerPosition(x: normalizedX, y: normalizedY),
        type: widget.selectedMarkerType,
        createdAt: DateTime.now(),
      );
      
      context.read<ImageEditorBloc>().add(
        AddMarkerRequested(marker),
      );
    }
  }

  ImageMarker? _findMarkerAtPosition(Offset position) {
    const tapRadius = 20.0; // Pixels
    
    for (final marker in widget.image.markers) {
      final markerScreenPosition = _convertToScreenPosition(marker.position);
      final distance = (position - markerScreenPosition).distance;
      
      if (distance <= tapRadius) {
        return marker;
      }
    }
    
    return null;
  }

  Offset _convertToScreenPosition(MarkerPosition markerPosition) {
    final imageSize = _getImageSize();
    return Offset(
      markerPosition.x * imageSize.width,
      markerPosition.y * imageSize.height,
    );
  }

  void _handleMarkerDrag(ImageMarker marker, Offset newPosition) {
    final imageSize = _getImageSize();
    final normalizedX = newPosition.dx / imageSize.width;
    final normalizedY = newPosition.dy / imageSize.height;
    
    final updatedMarker = marker.copyWith(
      position: MarkerPosition(x: normalizedX, y: normalizedY),
    );
    
    context.read<ImageEditorBloc>().add(
      UpdateMarkerRequested(updatedMarker),
    );
  }

  void _showMarkerOptions(ImageMarker marker) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Marker Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Label'),
              onTap: () {
                Navigator.pop(context);
                _editMarkerLabel(marker);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Marker'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                context.read<ImageEditorBloc>().add(
                  RemoveMarkerRequested(marker.id),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _editMarkerLabel(ImageMarker marker) {
    showDialog<void>(
      context: context,
      builder: (context) {
        String label = marker.label ?? '';
        
        return AlertDialog(
          title: const Text('Edit Marker Label'),
          content: TextField(
            controller: TextEditingController(text: label),
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => label = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedMarker = marker.copyWith(label: label);
                context.read<ImageEditorBloc>().add(
                  UpdateMarkerRequested(updatedMarker),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
```

### 4. Marker Overlay Widget

```dart
// lib/image_editor/presentation/widgets/marker_overlay.dart
import 'package:flutter/material.dart';
import '../../domain/entities/image_marker.dart';

class MarkerOverlay extends StatelessWidget {
  const MarkerOverlay({
    super.key,
    required this.markers,
    required this.imageSize,
    required this.onMarkerTap,
    required this.onMarkerDrag,
    required this.editMode,
  });

  final List<ImageMarker> markers;
  final Size imageSize;
  final Function(ImageMarker marker, Offset position) onMarkerTap;
  final Function(ImageMarker marker, Offset position) onMarkerDrag;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: markers.map((marker) {
        return _MarkerWidget(
          marker: marker,
          imageSize: imageSize,
          onTap: onMarkerTap,
          onDrag: onMarkerDrag,
          editMode: editMode,
        );
      }).toList(),
    );
  }
}

class _MarkerWidget extends StatefulWidget {
  const _MarkerWidget({
    required this.marker,
    required this.imageSize,
    required this.onTap,
    required this.onDrag,
    required this.editMode,
  });

  final ImageMarker marker;
  final Size imageSize;
  final Function(ImageMarker marker, Offset position) onTap;
  final Function(ImageMarker marker, Offset position) onDrag;
  final bool editMode;

  @override
  State<_MarkerWidget> createState() => _MarkerWidgetState();
}

class _MarkerWidgetState extends State<_MarkerWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenPosition = Offset(
      widget.marker.position.x * widget.imageSize.width,
      widget.marker.position.y * widget.imageSize.height,
    );

    return Positioned(
      left: screenPosition.dx - 12,
      top: screenPosition.dy - 12,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.marker, screenPosition),
        onPanUpdate: widget.editMode
            ? (details) => widget.onDrag(widget.marker, details.localPosition)
            : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getMarkerColor(widget.marker.type),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _getMarkerIcon(widget.marker.type),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getMarkerColor(MarkerType type) {
    return switch (type) {
      MarkerType.userDefined => Colors.blue,
      MarkerType.aiDetected => Colors.green,
      MarkerType.objectBoundary => Colors.orange,
      MarkerType.regionOfInterest => Colors.purple,
    };
  }

  Widget _getMarkerIcon(MarkerType type) {
    final icon = switch (type) {
      MarkerType.userDefined => Icons.place,
      MarkerType.aiDetected => Icons.smart_toy,
      MarkerType.objectBoundary => Icons.crop_free,
      MarkerType.regionOfInterest => Icons.center_focus_strong,
    };

    return Icon(
      icon,
      size: 16,
      color: Colors.white,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

### 5. Comprehensive Test Coverage

```dart
// test/image_editor/presentation/bloc/image_editor_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_editor/image_editor/domain/entities/edited_image.dart';
import 'package:photo_editor/image_editor/domain/entities/image_marker.dart';
import 'package:photo_editor/image_editor/domain/exceptions/image_editor_exceptions.dart';
import 'package:photo_editor/image_editor/domain/usecases/load_image_usecase.dart';
import 'package:photo_editor/image_editor/domain/usecases/add_marker_usecase.dart';
import 'package:photo_editor/image_editor/presentation/bloc/image_editor_bloc.dart';

class MockLoadImageUseCase extends Mock implements LoadImageUseCase {}
class MockAddMarkerUseCase extends Mock implements AddMarkerUseCase {}

void main() {
  late ImageEditorBloc bloc;
  late MockLoadImageUseCase mockLoadImageUseCase;
  late MockAddMarkerUseCase mockAddMarkerUseCase;

  setUp(() {
    mockLoadImageUseCase = MockLoadImageUseCase();
    mockAddMarkerUseCase = MockAddMarkerUseCase();
    
    bloc = ImageEditorBloc(
      loadImageUseCase: mockLoadImageUseCase,
      addMarkerUseCase: mockAddMarkerUseCase,
      // ... other use cases
    );
  });

  group('ImageEditorBloc', () {
    final testImage = EditedImage(
      id: 'test-id',
      originalImageData: Uint8List.fromList([1, 2, 3]),
      originalPath: '/test/path.jpg',
      markers: const [],
      createdAt: DateTime.now(),
    );

    blocTest<ImageEditorBloc, ImageEditorState>(
      'emits loading then loaded when LoadImageRequested succeeds',
      build: () {
        when(() => mockLoadImageUseCase(any()))
            .thenAnswer((_) async => Right(testImage));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadImageRequested('/test/path.jpg')),
      expect: () => [
        const ImageEditorLoading(),
        isA<ImageEditorLoaded>()
            .having((state) => state.image.id, 'image.id', testImage.id),
      ],
      verify: (_) {
        verify(() => mockLoadImageUseCase('/test/path.jpg')).called(1);
      },
    );

    blocTest<ImageEditorBloc, ImageEditorState>(
      'emits error when LoadImageRequested fails',
      build: () {
        when(() => mockLoadImageUseCase(any()))
            .thenAnswer((_) async => const Left(ImageLoadException('Test error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadImageRequested('/test/path.jpg')),
      expect: () => [
        const ImageEditorLoading(),
        const ImageEditorError('Test error'),
      ],
    );

    blocTest<ImageEditorBloc, ImageEditorState>(
      'toggles marker mode when MarkerModeToggled is added',
      build: () => bloc,
      seed: () => ImageEditorLoaded(
        image: testImage,
        markerMode: false,
        selectedMarkerType: MarkerType.userDefined,
        zoomLevel: 1.0,
        imagePosition: const ImagePosition(x: 0, y: 0),
      ),
      act: (bloc) => bloc.add(const MarkerModeToggled()),
      expect: () => [
        isA<ImageEditorLoaded>()
            .having((state) => state.markerMode, 'markerMode', true),
      ],
    );
  });
}
```

## Quality Standards

### Accessibility
- Semantic labels for all interactive elements
- High contrast marker colors
- Keyboard navigation support
- Screen reader compatibility

### Performance
- Efficient image rendering
- Smooth zoom and pan operations
- Optimized marker rendering
- Memory management for large images

### User Experience
- Intuitive gesture controls
- Clear visual feedback
- Responsive design for all screen sizes
- Consistent interaction patterns

## Acceptance Criteria
1. ✅ BLoC manages all state transitions correctly
2. ✅ Interactive image editing with zoom/pan
3. ✅ Marker system with multiple types
4. ✅ Real-time marker manipulation
5. ✅ AI processing integration
6. ✅ Comprehensive error handling
7. ✅ Responsive design patterns
8. ✅ Accessibility compliance
9. ✅ Performance optimization
10. ✅ Complete test coverage (>95%)

**Next Step:** After completion, proceed to AI processing pipeline implementation (10-ai-processing-pipeline.prompt.md)

**Quality Gate:** All tests pass, smooth 60fps interactions, accessibility audit passes
