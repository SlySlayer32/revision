# Image Editor Data Layer Implementation

## Context
Implementing the data layer for the image editor feature, including local storage, AI service integration, platform-specific image handling, and data synchronization. This layer bridges domain requirements with external data sources.

## Implementation Requirements

### 1. Data Models

Create DTOs that map between domain entities and external data:

```dart
// lib/image_editor/data/models/edited_image_model.dart
import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/edited_image.dart';
import '../../domain/entities/image_marker.dart';
import '../../domain/entities/processing_metadata.dart';
import 'image_marker_model.dart';
import 'processing_metadata_model.dart';

class EditedImageModel extends EditedImage {
  const EditedImageModel({
    required super.id,
    required super.originalImageData,
    required super.originalPath,
    required super.markers,
    super.processedImageData,
    super.processedPath,
    required super.createdAt,
    super.modifiedAt,
    super.processingStatus = ProcessingStatus.pending,
    super.aiPrompt,
    super.processingMetadata,
  });

  factory EditedImageModel.fromJson(Map<String, dynamic> json) {
    return EditedImageModel(
      id: json['id'] as String,
      originalImageData: base64Decode(json['originalImageData'] as String),
      originalPath: json['originalPath'] as String,
      markers: (json['markers'] as List<dynamic>)
          .map((e) => ImageMarkerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      processedImageData: json['processedImageData'] != null
          ? base64Decode(json['processedImageData'] as String)
          : null,
      processedPath: json['processedPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      processingStatus: ProcessingStatus.values.firstWhere(
        (e) => e.name == json['processingStatus'],
        orElse: () => ProcessingStatus.pending,
      ),
      aiPrompt: json['aiPrompt'] as String?,
      processingMetadata: json['processingMetadata'] != null
          ? ProcessingMetadataModel.fromJson(
              json['processingMetadata'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalImageData': base64Encode(originalImageData),
      'originalPath': originalPath,
      'markers': markers
          .map((e) => ImageMarkerModel.fromEntity(e).toJson())
          .toList(),
      'processedImageData': processedImageData != null
          ? base64Encode(processedImageData!)
          : null,
      'processedPath': processedPath,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'processingStatus': processingStatus.name,
      'aiPrompt': aiPrompt,
      'processingMetadata': processingMetadata != null
          ? ProcessingMetadataModel.fromEntity(processingMetadata!).toJson()
          : null,
    };
  }

  factory EditedImageModel.fromEntity(EditedImage entity) {
    return EditedImageModel(
      id: entity.id,
      originalImageData: entity.originalImageData,
      originalPath: entity.originalPath,
      markers: entity.markers,
      processedImageData: entity.processedImageData,
      processedPath: entity.processedPath,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      processingStatus: entity.processingStatus,
      aiPrompt: entity.aiPrompt,
      processingMetadata: entity.processingMetadata,
    );
  }

  EditedImage toEntity() {
    return EditedImage(
      id: id,
      originalImageData: originalImageData,
      originalPath: originalPath,
      markers: markers,
      processedImageData: processedImageData,
      processedPath: processedPath,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      processingStatus: processingStatus,
      aiPrompt: aiPrompt,
      processingMetadata: processingMetadata,
    );
  }
}
```

```dart
// lib/image_editor/data/models/image_marker_model.dart
import '../../domain/entities/image_marker.dart';

class ImageMarkerModel extends ImageMarker {
  const ImageMarkerModel({
    required super.id,
    required super.position,
    required super.type,
    required super.createdAt,
    super.label,
    super.confidence,
    super.metadata,
  });

  factory ImageMarkerModel.fromJson(Map<String, dynamic> json) {
    return ImageMarkerModel(
      id: json['id'] as String,
      position: MarkerPositionModel.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
      type: MarkerType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      label: json['label'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': MarkerPositionModel.fromEntity(position).toJson(),
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'label': label,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  factory ImageMarkerModel.fromEntity(ImageMarker entity) {
    return ImageMarkerModel(
      id: entity.id,
      position: entity.position,
      type: entity.type,
      createdAt: entity.createdAt,
      label: entity.label,
      confidence: entity.confidence,
      metadata: entity.metadata,
    );
  }
}

class MarkerPositionModel extends MarkerPosition {
  const MarkerPositionModel({
    required super.x,
    required super.y,
    super.width,
    super.height,
  });

  factory MarkerPositionModel.fromJson(Map<String, dynamic> json) {
    return MarkerPositionModel(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory MarkerPositionModel.fromEntity(MarkerPosition entity) {
    return MarkerPositionModel(
      x: entity.x,
      y: entity.y,
      width: entity.width,
      height: entity.height,
    );
  }
}
```

### 2. Local Storage Data Source

Implement persistent storage using Hive:

```dart
// lib/image_editor/data/datasources/local/image_editor_local_datasource.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../models/edited_image_model.dart';
import '../../../domain/entities/edited_image.dart';
import '../../../domain/entities/image_marker.dart';
import '../../../domain/exceptions/image_editor_exceptions.dart';

abstract class ImageEditorLocalDataSource {
  Future<void> initialize();
  Future<EditedImageModel> saveImage(EditedImageModel image);
  Future<EditedImageModel?> getImage(String id);
  Future<List<EditedImageModel>> getAllImages();
  Future<void> deleteImage(String id);
  Future<EditedImageModel> addMarker(String imageId, ImageMarker marker);
  Future<EditedImageModel> removeMarker(String imageId, String markerId);
  Future<EditedImageModel> updateMarker(String imageId, ImageMarker marker);
  Stream<EditedImageModel?> watchImage(String id);
  Stream<List<EditedImageModel>> watchAllImages();
  Future<String> saveImageFile(Uint8List imageData, String filename);
  Future<Uint8List> loadImageFile(String filepath);
  Future<void> deleteImageFile(String filepath);
}

class ImageEditorLocalDataSourceImpl implements ImageEditorLocalDataSource {
  ImageEditorLocalDataSourceImpl({
    required this.boxName,
  });

  final String boxName;
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, StreamController<EditedImageModel?>> _imageControllers = {};
  final StreamController<List<EditedImageModel>> _allImagesController =
      StreamController<List<EditedImageModel>>.broadcast();

  @override
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);
      
      // Initialize stream with current data
      final images = await getAllImages();
      _allImagesController.add(images);
    } catch (e) {
      throw ImageLoadException('Failed to initialize local storage: $e');
    }
  }

  @override
  Future<EditedImageModel> saveImage(EditedImageModel image) async {
    try {
      final box = _getBox();
      await box.put(image.id, image.toJson());
      
      // Update streams
      _notifyImageUpdate(image);
      _notifyAllImagesUpdate();
      
      return image;
    } catch (e) {
      throw ImageSaveException('Failed to save image: $e');
    }
  }

  @override
  Future<EditedImageModel?> getImage(String id) async {
    try {
      final box = _getBox();
      final data = box.get(id);
      
      if (data == null) return null;
      
      return EditedImageModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ImageLoadException('Failed to load image: $e');
    }
  }

  @override
  Future<List<EditedImageModel>> getAllImages() async {
    try {
      final box = _getBox();
      final images = <EditedImageModel>[];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          images.add(EditedImageModel.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      
      // Sort by creation date (newest first)
      images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return images;
    } catch (e) {
      throw ImageLoadException('Failed to load images: $e');
    }
  }

  @override
  Future<void> deleteImage(String id) async {
    try {
      final box = _getBox();
      final image = await getImage(id);
      
      if (image != null) {
        // Delete image files
        if (image.processedPath != null) {
          await deleteImageFile(image.processedPath!);
        }
        
        await box.delete(id);
        
        // Update streams
        _notifyImageUpdate(null, imageId: id);
        _notifyAllImagesUpdate();
      }
    } catch (e) {
      throw ImageSaveException('Failed to delete image: $e');
    }
  }

  @override
  Future<EditedImageModel> addMarker(String imageId, ImageMarker marker) async {
    final image = await getImage(imageId);
    if (image == null) {
      throw ImageLoadException('Image not found: $imageId');
    }
    
    final updatedMarkers = List<ImageMarker>.from(image.markers)..add(marker);
    final updatedImage = EditedImageModel.fromEntity(
      image.copyWith(
        markers: updatedMarkers,
        modifiedAt: DateTime.now(),
      ),
    );
    
    return saveImage(updatedImage);
  }

  @override
  Future<EditedImageModel> removeMarker(String imageId, String markerId) async {
    final image = await getImage(imageId);
    if (image == null) {
      throw ImageLoadException('Image not found: $imageId');
    }
    
    final updatedMarkers = image.markers
        .where((marker) => marker.id != markerId)
        .toList();
    
    final updatedImage = EditedImageModel.fromEntity(
      image.copyWith(
        markers: updatedMarkers,
        modifiedAt: DateTime.now(),
      ),
    );
    
    return saveImage(updatedImage);
  }

  @override
  Future<EditedImageModel> updateMarker(String imageId, ImageMarker marker) async {
    final image = await getImage(imageId);
    if (image == null) {
      throw ImageLoadException('Image not found: $imageId');
    }
    
    final updatedMarkers = image.markers.map((m) {
      return m.id == marker.id ? marker : m;
    }).toList();
    
    final updatedImage = EditedImageModel.fromEntity(
      image.copyWith(
        markers: updatedMarkers,
        modifiedAt: DateTime.now(),
      ),
    );
    
    return saveImage(updatedImage);
  }

  @override
  Stream<EditedImageModel?> watchImage(String id) {
    if (!_imageControllers.containsKey(id)) {
      _imageControllers[id] = StreamController<EditedImageModel?>.broadcast();
      
      // Initialize with current value
      getImage(id).then((image) {
        if (_imageControllers.containsKey(id)) {
          _imageControllers[id]!.add(image);
        }
      });
    }
    
    return _imageControllers[id]!.stream;
  }

  @override
  Stream<List<EditedImageModel>> watchAllImages() {
    return _allImagesController.stream;
  }

  @override
  Future<String> saveImageFile(Uint8List imageData, String filename) async {
    try {
      final directory = await _getImagesDirectory();
      final file = File(path.join(directory.path, filename));
      await file.writeAsBytes(imageData);
      return file.path;
    } catch (e) {
      throw ImageSaveException('Failed to save image file: $e');
    }
  }

  @override
  Future<Uint8List> loadImageFile(String filepath) async {
    try {
      final file = File(filepath);
      if (!await file.exists()) {
        throw ImageLoadException('Image file not found: $filepath');
      }
      return await file.readAsBytes();
    } catch (e) {
      throw ImageLoadException('Failed to load image file: $e');
    }
  }

  @override
  Future<void> deleteImageFile(String filepath) async {
    try {
      final file = File(filepath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ImageSaveException('Failed to delete image file: $e');
    }
  }

  Box<Map<dynamic, dynamic>> _getBox() {
    if (_box == null || !_box!.isOpen) {
      throw ImageLoadException('Local storage not initialized');
    }
    return _box!;
  }

  Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  void _notifyImageUpdate(EditedImageModel? image, {String? imageId}) {
    final id = imageId ?? image?.id;
    if (id != null && _imageControllers.containsKey(id)) {
      _imageControllers[id]!.add(image);
    }
  }

  void _notifyAllImagesUpdate() {
    getAllImages().then((images) {
      _allImagesController.add(images);
    });
  }

  void dispose() {
    for (final controller in _imageControllers.values) {
      controller.close();
    }
    _imageControllers.clear();
    _allImagesController.close();
    _box?.close();
  }
}
```

### 3. AI Service Data Source

Implement Vertex AI integration:

```dart
// lib/image_editor/data/datasources/remote/ai_service_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../models/edited_image_model.dart';
import '../../models/processing_metadata_model.dart';
import '../../../domain/entities/edited_image.dart';
import '../../../domain/exceptions/image_editor_exceptions.dart';

abstract class AiServiceDataSource {
  Future<ProcessingResult> processImage({
    required String imageId,
    required Uint8List imageData,
    required String prompt,
    required List<Map<String, dynamic>> markers,
  });
  
  Future<void> cancelProcessing(String requestId);
  
  Stream<ProcessingProgress> watchProcessingProgress(String requestId);
}

class ProcessingResult {
  const ProcessingResult({
    required this.processedImageData,
    required this.metadata,
  });

  final Uint8List processedImageData;
  final ProcessingMetadataModel metadata;
}

class ProcessingProgress {
  const ProcessingProgress({
    required this.requestId,
    required this.status,
    required this.progress,
    this.estimatedTimeRemaining,
    this.error,
  });

  final String requestId;
  final ProcessingStatus status;
  final double progress; // 0.0 to 1.0
  final Duration? estimatedTimeRemaining;
  final String? error;
}

class AiServiceDataSourceImpl implements AiServiceDataSource {
  AiServiceDataSourceImpl({
    required this.vertexAI,
  });

  final FirebaseVertexAI vertexAI;
  final Map<String, StreamController<ProcessingProgress>> _progressControllers = {};
  final Map<String, Completer<void>> _cancellationTokens = {};

  @override
  Future<ProcessingResult> processImage({
    required String imageId,
    required Uint8List imageData,
    required String prompt,
    required List<Map<String, dynamic>> markers,
  }) async {
    final requestId = '${imageId}_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();
    
    try {
      // Initialize progress tracking
      _initializeProgressTracking(requestId);
      
      // Update progress: Starting
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.processing,
        progress: 0.0,
      ));

      // Prepare the model
      final model = vertexAI.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 32,
          topP: 1.0,
          maxOutputTokens: 2048,
        ),
      );

      // Create the enhanced prompt with marker information
      final enhancedPrompt = _buildEnhancedPrompt(prompt, markers);
      
      // Update progress: Processing
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.processing,
        progress: 0.3,
        estimatedTimeRemaining: const Duration(seconds: 30),
      ));

      // Check for cancellation
      if (_cancellationTokens.containsKey(requestId)) {
        throw ProcessingException('Processing cancelled');
      }

      // Process the image with AI
      final content = [
        Content.multi([
          TextPart(enhancedPrompt),
          DataPart('image/jpeg', imageData),
        ])
      ];

      final response = await model.generateContent(content);
      
      // Update progress: Post-processing
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.processing,
        progress: 0.8,
        estimatedTimeRemaining: const Duration(seconds: 5),
      ));

      // Extract the processed image from response
      final processedImageData = await _extractProcessedImage(response);
      
      // Create processing metadata
      final endTime = DateTime.now();
      final metadata = ProcessingMetadataModel(
        processingStartTime: startTime,
        processingEndTime: endTime,
        processingDuration: endTime.difference(startTime),
        aiModel: 'gemini-1.5-flash',
        parameters: {
          'prompt': prompt,
          'markers_count': markers.length,
          'temperature': 0.7,
          'top_k': 32,
          'top_p': 1.0,
        },
        performance: ProcessingPerformanceModel(
          memoryUsed: imageData.length.toDouble(),
          processingTime: endTime.difference(startTime),
        ),
      );

      // Update progress: Completed
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.completed,
        progress: 1.0,
      ));

      _cleanupProgressTracking(requestId);

      return ProcessingResult(
        processedImageData: processedImageData,
        metadata: metadata,
      );

    } catch (e) {
      final error = e.toString();
      
      // Update progress: Failed
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.failed,
        progress: 0.0,
        error: error,
      ));

      _cleanupProgressTracking(requestId);

      if (e is ProcessingException) {
        rethrow;
      }
      
      throw ProcessingException('AI processing failed: $error');
    }
  }

  @override
  Future<void> cancelProcessing(String requestId) async {
    if (_cancellationTokens.containsKey(requestId)) {
      _cancellationTokens[requestId]!.complete();
      
      _updateProgress(requestId, ProcessingProgress(
        requestId: requestId,
        status: ProcessingStatus.cancelled,
        progress: 0.0,
      ));
      
      _cleanupProgressTracking(requestId);
    }
  }

  @override
  Stream<ProcessingProgress> watchProcessingProgress(String requestId) {
    if (!_progressControllers.containsKey(requestId)) {
      _progressControllers[requestId] = StreamController<ProcessingProgress>.broadcast();
    }
    
    return _progressControllers[requestId]!.stream;
  }

  String _buildEnhancedPrompt(String basePrompt, List<Map<String, dynamic>> markers) {
    final buffer = StringBuffer();
    buffer.writeln('Image editing request:');
    buffer.writeln(basePrompt);
    
    if (markers.isNotEmpty) {
      buffer.writeln('\nMarked areas of interest:');
      for (int i = 0; i < markers.length; i++) {
        final marker = markers[i];
        buffer.writeln('${i + 1}. Position: (${marker['x']}, ${marker['y']})');
        if (marker['label'] != null) {
          buffer.writeln('   Label: ${marker['label']}');
        }
        if (marker['type'] != null) {
          buffer.writeln('   Type: ${marker['type']}');
        }
      }
    }
    
    buffer.writeln('\nPlease process this image according to the request and marked areas.');
    
    return buffer.toString();
  }

  Future<Uint8List> _extractProcessedImage(GenerateContentResponse response) async {
    // This is a simplified implementation
    // In a real scenario, you would need to handle the specific response format
    // from your AI service and extract the processed image data
    
    if (response.text == null) {
      throw ProcessingException('No response from AI service');
    }
    
    // For now, return a placeholder
    // In production, implement proper image extraction logic
    throw ProcessingException('Image extraction not yet implemented');
  }

  void _initializeProgressTracking(String requestId) {
    _progressControllers[requestId] = StreamController<ProcessingProgress>.broadcast();
    _cancellationTokens[requestId] = Completer<void>();
  }

  void _updateProgress(String requestId, ProcessingProgress progress) {
    if (_progressControllers.containsKey(requestId)) {
      _progressControllers[requestId]!.add(progress);
    }
  }

  void _cleanupProgressTracking(String requestId) {
    _progressControllers[requestId]?.close();
    _progressControllers.remove(requestId);
    _cancellationTokens.remove(requestId);
  }

  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _cancellationTokens.clear();
  }
}
```

### 4. Repository Implementation

```dart
// lib/image_editor/data/repositories/image_editor_repository_impl.dart
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/edited_image.dart';
import '../../domain/entities/image_marker.dart';
import '../../domain/exceptions/image_editor_exceptions.dart';
import '../../domain/repositories/image_editor_repository.dart';
import '../datasources/local/image_editor_local_datasource.dart';
import '../datasources/remote/ai_service_datasource.dart';
import '../models/edited_image_model.dart';
import '../models/image_marker_model.dart';

class ImageEditorRepositoryImpl implements ImageEditorRepository {
  ImageEditorRepositoryImpl({
    required this.localDataSource,
    required this.aiServiceDataSource,
  });

  final ImageEditorLocalDataSource localDataSource;
  final AiServiceDataSource aiServiceDataSource;
  final Uuid _uuid = const Uuid();

  @override
  Future<Either<ImageEditorException, EditedImage>> loadImage(String path) async {
    try {
      // Load image data from file
      final imageData = await localDataSource.loadImageFile(path);
      
      // Create new edited image entity
      final editedImage = EditedImageModel(
        id: _uuid.v4(),
        originalImageData: imageData,
        originalPath: path,
        markers: const [],
        createdAt: DateTime.now(),
      );
      
      // Save to local storage
      final savedImage = await localDataSource.saveImage(editedImage);
      
      return Right(savedImage.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ImageLoadException('Failed to load image: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> saveImage(EditedImage image) async {
    try {
      final imageModel = EditedImageModel.fromEntity(image);
      final savedImage = await localDataSource.saveImage(imageModel);
      return Right(savedImage.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ImageSaveException('Failed to save image: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, List<EditedImage>>> getAllImages() async {
    try {
      final images = await localDataSource.getAllImages();
      return Right(images.map((e) => e.toEntity()).toList());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ImageLoadException('Failed to load images: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> getImageById(String id) async {
    try {
      final image = await localDataSource.getImage(id);
      if (image == null) {
        return Left(ImageLoadException('Image not found: $id'));
      }
      return Right(image.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ImageLoadException('Failed to load image: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, void>> deleteImage(String id) async {
    try {
      await localDataSource.deleteImage(id);
      return const Right(null);
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ImageSaveException('Failed to delete image: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> addMarker(
    String imageId,
    ImageMarker marker,
  ) async {
    try {
      final updatedImage = await localDataSource.addMarker(imageId, marker);
      return Right(updatedImage.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(MarkerException('Failed to add marker: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> removeMarker(
    String imageId,
    String markerId,
  ) async {
    try {
      final updatedImage = await localDataSource.removeMarker(imageId, markerId);
      return Right(updatedImage.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(MarkerException('Failed to remove marker: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> updateMarker(
    String imageId,
    ImageMarker marker,
  ) async {
    try {
      final updatedImage = await localDataSource.updateMarker(imageId, marker);
      return Right(updatedImage.toEntity());
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(MarkerException('Failed to update marker: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, EditedImage>> processImage(
    String imageId,
    String prompt,
  ) async {
    try {
      // Get the image from local storage
      final image = await localDataSource.getImage(imageId);
      if (image == null) {
        return Left(ImageLoadException('Image not found: $imageId'));
      }

      // Update status to processing
      final processingImage = EditedImageModel.fromEntity(
        image.copyWith(
          processingStatus: ProcessingStatus.processing,
          aiPrompt: prompt,
          modifiedAt: DateTime.now(),
        ),
      );
      await localDataSource.saveImage(processingImage);

      // Prepare markers data for AI service
      final markersData = image.markers.map((marker) {
        return ImageMarkerModel.fromEntity(marker).toJson();
      }).toList();

      // Process with AI service
      final result = await aiServiceDataSource.processImage(
        imageId: imageId,
        imageData: image.originalImageData,
        prompt: prompt,
        markers: markersData,
      );

      // Save processed image file
      final filename = 'processed_${imageId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedPath = await localDataSource.saveImageFile(
        result.processedImageData,
        filename,
      );

      // Update image with processed result
      final completedImage = EditedImageModel.fromEntity(
        image.copyWith(
          processedImageData: result.processedImageData,
          processedPath: processedPath,
          processingStatus: ProcessingStatus.completed,
          modifiedAt: DateTime.now(),
          processingMetadata: result.metadata.toEntity(),
        ),
      );

      final savedImage = await localDataSource.saveImage(completedImage);
      return Right(savedImage.toEntity());

    } on ImageEditorException catch (e) {
      // Update status to failed
      try {
        final image = await localDataSource.getImage(imageId);
        if (image != null) {
          final failedImage = EditedImageModel.fromEntity(
            image.copyWith(
              processingStatus: ProcessingStatus.failed,
              modifiedAt: DateTime.now(),
            ),
          );
          await localDataSource.saveImage(failedImage);
        }
      } catch (_) {
        // Ignore save errors when already in error state
      }
      
      return Left(e);
    } catch (e) {
      return Left(ProcessingException('Failed to process image: $e'));
    }
  }

  @override
  Future<Either<ImageEditorException, void>> cancelProcessing(String imageId) async {
    try {
      await aiServiceDataSource.cancelProcessing(imageId);
      
      // Update image status
      final image = await localDataSource.getImage(imageId);
      if (image != null) {
        final cancelledImage = EditedImageModel.fromEntity(
          image.copyWith(
            processingStatus: ProcessingStatus.cancelled,
            modifiedAt: DateTime.now(),
          ),
        );
        await localDataSource.saveImage(cancelledImage);
      }
      
      return const Right(null);
    } on ImageEditorException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ProcessingException('Failed to cancel processing: $e'));
    }
  }

  @override
  Stream<EditedImage> watchImage(String imageId) {
    return localDataSource.watchImage(imageId).map((image) {
      if (image == null) {
        throw ImageLoadException('Image not found: $imageId');
      }
      return image.toEntity();
    });
  }

  @override
  Stream<List<EditedImage>> watchAllImages() {
    return localDataSource.watchAllImages().map((images) {
      return images.map((e) => e.toEntity()).toList();
    });
  }
}
```

### 5. Comprehensive Tests

```dart
// test/image_editor/data/repositories/image_editor_repository_impl_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_editor/image_editor/data/datasources/local/image_editor_local_datasource.dart';
import 'package:photo_editor/image_editor/data/datasources/remote/ai_service_datasource.dart';
import 'package:photo_editor/image_editor/data/models/edited_image_model.dart';
import 'package:photo_editor/image_editor/data/repositories/image_editor_repository_impl.dart';
import 'package:photo_editor/image_editor/domain/entities/edited_image.dart';
import 'package:photo_editor/image_editor/domain/exceptions/image_editor_exceptions.dart';

class MockImageEditorLocalDataSource extends Mock implements ImageEditorLocalDataSource {}
class MockAiServiceDataSource extends Mock implements AiServiceDataSource {}

void main() {
  late ImageEditorRepositoryImpl repository;
  late MockImageEditorLocalDataSource mockLocalDataSource;
  late MockAiServiceDataSource mockAiServiceDataSource;

  setUp(() {
    mockLocalDataSource = MockImageEditorLocalDataSource();
    mockAiServiceDataSource = MockAiServiceDataSource();
    repository = ImageEditorRepositoryImpl(
      localDataSource: mockLocalDataSource,
      aiServiceDataSource: mockAiServiceDataSource,
    );
  });

  group('ImageEditorRepositoryImpl', () {
    group('loadImage', () {
      const testPath = '/test/image.jpg';
      final testImageData = Uint8List.fromList([1, 2, 3, 4]);

      test('returns success when loading image succeeds', () async {
        // Arrange
        final expectedImage = EditedImageModel(
          id: 'test-id',
          originalImageData: testImageData,
          originalPath: testPath,
          markers: const [],
          createdAt: DateTime.now(),
        );

        when(() => mockLocalDataSource.loadImageFile(testPath))
            .thenAnswer((_) async => testImageData);
        when(() => mockLocalDataSource.saveImage(any()))
            .thenAnswer((_) async => expectedImage);

        // Act
        final result = await repository.loadImage(testPath);

        // Assert
        expect(result, isA<Right<ImageEditorException, EditedImage>>());
        verify(() => mockLocalDataSource.loadImageFile(testPath)).called(1);
        verify(() => mockLocalDataSource.saveImage(any())).called(1);
      });

      test('returns failure when loading image file fails', () async {
        // Arrange
        when(() => mockLocalDataSource.loadImageFile(testPath))
            .thenThrow(const ImageLoadException('File not found'));

        // Act
        final result = await repository.loadImage(testPath);

        // Assert
        expect(result, isA<Left<ImageEditorException, EditedImage>>());
        expect(
          result.fold((l) => l, (r) => null),
          isA<ImageLoadException>(),
        );
        verifyNever(() => mockLocalDataSource.saveImage(any()));
      });
    });

    group('processImage', () {
      const imageId = 'test-id';
      const prompt = 'Make it brighter';
      final testImageData = Uint8List.fromList([1, 2, 3, 4]);
      final processedImageData = Uint8List.fromList([5, 6, 7, 8]);

      test('returns success when processing succeeds', () async {
        // Arrange
        final originalImage = EditedImageModel(
          id: imageId,
          originalImageData: testImageData,
          originalPath: '/test/path.jpg',
          markers: const [],
          createdAt: DateTime.now(),
        );

        final processedImage = EditedImageModel.fromEntity(
          originalImage.copyWith(
            processedImageData: processedImageData,
            processedPath: '/test/processed.jpg',
            processingStatus: ProcessingStatus.completed,
          ),
        );

        when(() => mockLocalDataSource.getImage(imageId))
            .thenAnswer((_) async => originalImage);
        when(() => mockLocalDataSource.saveImage(any()))
            .thenAnswer((_) async => processedImage);
        when(() => mockAiServiceDataSource.processImage(
              imageId: imageId,
              imageData: testImageData,
              prompt: prompt,
              markers: any(named: 'markers'),
            )).thenAnswer((_) async => ProcessingResult(
              processedImageData: processedImageData,
              metadata: ProcessingMetadataModel(
                processingStartTime: DateTime.now(),
                processingEndTime: DateTime.now(),
                processingDuration: const Duration(seconds: 5),
                aiModel: 'test-model',
              ),
            ));
        when(() => mockLocalDataSource.saveImageFile(any(), any()))
            .thenAnswer((_) async => '/test/processed.jpg');

        // Act
        final result = await repository.processImage(imageId, prompt);

        // Assert
        expect(result, isA<Right<ImageEditorException, EditedImage>>());
        verify(() => mockLocalDataSource.getImage(imageId)).called(1);
        verify(() => mockAiServiceDataSource.processImage(
              imageId: imageId,
              imageData: testImageData,
              prompt: prompt,
              markers: any(named: 'markers'),
            )).called(1);
      });

      test('returns failure when image not found', () async {
        // Arrange
        when(() => mockLocalDataSource.getImage(imageId))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.processImage(imageId, prompt);

        // Assert
        expect(result, isA<Left<ImageEditorException, EditedImage>>());
        expect(
          result.fold((l) => l.message, (r) => null),
          contains('Image not found'),
        );
        verifyNever(() => mockAiServiceDataSource.processImage(
              imageId: any(named: 'imageId'),
              imageData: any(named: 'imageData'),
              prompt: any(named: 'prompt'),
              markers: any(named: 'markers'),
            ));
      });
    });
  });
}
```

## Quality Standards

### Error Handling
- Comprehensive exception mapping between layers
- Graceful degradation for network failures
- Retry logic with exponential backoff
- Proper cleanup on cancellation

### Performance
- Efficient image data handling
- Streaming for large operations
- Background processing capabilities
- Memory optimization for large images

### Data Integrity
- Atomic operations for critical updates
- Data validation at boundaries
- Consistent state management
- Recovery from corruption

## Acceptance Criteria
1. ✅ Local storage handles all CRUD operations
2. ✅ AI service integration processes images correctly
3. ✅ Repository implements proper error handling
4. ✅ Comprehensive test coverage (>95%)
5. ✅ Efficient memory management
6. ✅ Real-time data synchronization
7. ✅ Proper data model mapping
8. ✅ Cancellation support for long operations
9. ✅ Progress tracking for AI processing
10. ✅ File system operations are secure

**Next Step:** After completion, proceed to image editor presentation layer (09-image-editor-presentation.prompt.md)

**Quality Gate:** All tests pass, performance benchmarks met, zero memory leaks
