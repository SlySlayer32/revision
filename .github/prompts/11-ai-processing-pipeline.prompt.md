# AI Processing Pipeline Implementation (PROMPTER + EDITOR)

## Context
Implementing the comprehensive AI processing pipeline that combines prompt engineering with image editing capabilities. This system integrates with Vertex AI to provide intelligent image processing based on user prompts and marked areas, following the PROMPTER + EDITOR architecture pattern.

## Implementation Requirements

### 1. AI Prompt Engineering Service

Create sophisticated prompt engineering for optimal AI results:

```dart
// lib/ai_processing/domain/services/prompt_engineering_service.dart
import 'dart:typed_data';
import '../entities/processing_context.dart';
import '../entities/prompt_template.dart';
import '../entities/image_analysis.dart';

abstract class PromptEngineeringService {
  Future<String> generateEnhancedPrompt({
    required String userPrompt,
    required ProcessingContext context,
    required ImageAnalysis imageAnalysis,
  });
  
  Future<List<PromptTemplate>> getTemplatesForContext(ProcessingContext context);
  
  Future<String> optimizePromptForModel({
    required String prompt,
    required String modelName,
    required Map<String, dynamic> modelCapabilities,
  });
  
  Future<ValidationResult> validatePrompt(String prompt);
}

class PromptEngineeringServiceImpl implements PromptEngineeringService {
  PromptEngineeringServiceImpl({
    required this.templateRepository,
    required this.imageAnalysisService,
  });

  final PromptTemplateRepository templateRepository;
  final ImageAnalysisService imageAnalysisService;

  @override
  Future<String> generateEnhancedPrompt({
    required String userPrompt,
    required ProcessingContext context,
    required ImageAnalysis imageAnalysis,
  }) async {
    final templates = await getTemplatesForContext(context);
    final bestTemplate = _selectBestTemplate(templates, userPrompt, imageAnalysis);
    
    final enhancedPrompt = await _buildEnhancedPrompt(
      userPrompt: userPrompt,
      template: bestTemplate,
      context: context,
      imageAnalysis: imageAnalysis,
    );
    
    return enhancedPrompt;
  }

  @override
  Future<List<PromptTemplate>> getTemplatesForContext(
    ProcessingContext context,
  ) async {
    return templateRepository.getTemplatesForType(context.processingType);
  }

  @override
  Future<String> optimizePromptForModel({
    required String prompt,
    required String modelName,
    required Map<String, dynamic> modelCapabilities,
  }) async {
    final optimizer = _getModelOptimizer(modelName);
    return optimizer.optimize(prompt, modelCapabilities);
  }

  @override
  Future<ValidationResult> validatePrompt(String prompt) async {
    final issues = <ValidationIssue>[];
    
    // Check prompt length
    if (prompt.length > 4000) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.warning,
        message: 'Prompt is very long and may be truncated',
        suggestion: 'Consider shortening the prompt',
      ));
    }
    
    // Check for potentially harmful content
    if (_containsHarmfulContent(prompt)) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.error,
        message: 'Prompt contains potentially harmful content',
        suggestion: 'Please revise the prompt to remove harmful elements',
      ));
    }
    
    // Check for unclear instructions
    if (_isVaguePrompt(prompt)) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.suggestion,
        message: 'Prompt could be more specific',
        suggestion: 'Add more details about desired outcome',
      ));
    }
    
    return ValidationResult(
      isValid: !issues.any((i) => i.type == ValidationIssueType.error),
      issues: issues,
      score: _calculatePromptScore(prompt, issues),
    );
  }

  PromptTemplate _selectBestTemplate(
    List<PromptTemplate> templates,
    String userPrompt,
    ImageAnalysis imageAnalysis,
  ) {
    if (templates.isEmpty) {
      return PromptTemplate.defaultTemplate();
    }
    
    // Score templates based on relevance
    final scoredTemplates = templates.map((template) {
      final score = _calculateTemplateScore(template, userPrompt, imageAnalysis);
      return MapEntry(template, score);
    }).toList();
    
    // Sort by score and return best
    scoredTemplates.sort((a, b) => b.value.compareTo(a.value));
    return scoredTemplates.first.key;
  }

  Future<String> _buildEnhancedPrompt({
    required String userPrompt,
    required PromptTemplate template,
    required ProcessingContext context,
    required ImageAnalysis imageAnalysis,
  }) async {
    final promptBuilder = StringBuffer();
    
    // Add system context
    promptBuilder.writeln(template.systemPrompt);
    
    // Add image analysis context
    promptBuilder.writeln(_buildImageContext(imageAnalysis));
    
    // Add marker-specific instructions
    if (context.markers.isNotEmpty) {
      promptBuilder.writeln(_buildMarkerInstructions(context.markers));
    }
    
    // Add user prompt with formatting
    promptBuilder.writeln('User Request:');
    promptBuilder.writeln(userPrompt);
    
    // Add processing guidelines
    promptBuilder.writeln(_buildProcessingGuidelines(context));
    
    // Add quality requirements
    promptBuilder.writeln(template.qualityInstructions);
    
    return promptBuilder.toString();
  }

  String _buildImageContext(ImageAnalysis analysis) {
    final context = StringBuffer();
    context.writeln('Image Analysis:');
    context.writeln('- Dimensions: ${analysis.dimensions.width}x${analysis.dimensions.height}');
    context.writeln('- Format: ${analysis.format}');
    context.writeln('- Dominant colors: ${analysis.dominantColors.join(", ")}');
    context.writeln('- Detected objects: ${analysis.detectedObjects.join(", ")}');
    context.writeln('- Scene type: ${analysis.sceneType}');
    context.writeln('- Lighting conditions: ${analysis.lightingConditions}');
    context.writeln('- Quality score: ${analysis.qualityScore}/10');
    return context.toString();
  }

  String _buildMarkerInstructions(List<ImageMarker> markers) {
    final instructions = StringBuffer();
    instructions.writeln('Marked Areas of Interest:');
    
    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      instructions.writeln('${i + 1}. ${marker.type.name} at (${marker.position.x.toStringAsFixed(2)}, ${marker.position.y.toStringAsFixed(2)})');
      
      if (marker.label != null) {
        instructions.writeln('   Label: ${marker.label}');
      }
      
      if (marker.confidence != null) {
        instructions.writeln('   Confidence: ${(marker.confidence! * 100).toStringAsFixed(1)}%');
      }
    }
    
    instructions.writeln('Pay special attention to these marked areas when processing.');
    return instructions.toString();
  }

  String _buildProcessingGuidelines(ProcessingContext context) {
    final guidelines = StringBuffer();
    guidelines.writeln('Processing Guidelines:');
    guidelines.writeln('- Processing type: ${context.processingType.name}');
    guidelines.writeln('- Quality level: ${context.qualityLevel.name}');
    guidelines.writeln('- Performance priority: ${context.performancePriority.name}');
    
    if (context.constraints.isNotEmpty) {
      guidelines.writeln('- Constraints: ${context.constraints.join(", ")}');
    }
    
    return guidelines.toString();
  }

  double _calculateTemplateScore(
    PromptTemplate template,
    String userPrompt,
    ImageAnalysis imageAnalysis,
  ) {
    double score = 0.0;
    
    // Check keyword relevance
    final keywords = userPrompt.toLowerCase().split(' ');
    final templateKeywords = template.keywords.map((k) => k.toLowerCase()).toList();
    
    for (final keyword in keywords) {
      if (templateKeywords.contains(keyword)) {
        score += 1.0;
      }
    }
    
    // Check image type compatibility
    if (template.supportedImageTypes.contains(imageAnalysis.sceneType)) {
      score += 5.0;
    }
    
    // Check processing type match
    if (template.processingTypes.any((type) => 
        userPrompt.toLowerCase().contains(type.toLowerCase()))) {
      score += 3.0;
    }
    
    return score;
  }

  double _calculatePromptScore(String prompt, List<ValidationIssue> issues) {
    double score = 10.0;
    
    for (final issue in issues) {
      switch (issue.type) {
        case ValidationIssueType.error:
          score -= 5.0;
          break;
        case ValidationIssueType.warning:
          score -= 2.0;
          break;
        case ValidationIssueType.suggestion:
          score -= 0.5;
          break;
      }
    }
    
    return (score).clamp(0.0, 10.0);
  }

  bool _containsHarmfulContent(String prompt) {
    final harmfulPatterns = [
      RegExp(r'\b(violence|violent|harm|hurt|kill|death)\b', caseSensitive: false),
      RegExp(r'\b(nude|naked|sexual|explicit)\b', caseSensitive: false),
      RegExp(r'\b(hate|racist|discriminat)\b', caseSensitive: false),
    ];
    
    return harmfulPatterns.any((pattern) => pattern.hasMatch(prompt));
  }

  bool _isVaguePrompt(String prompt) {
    final vagueWords = ['enhance', 'improve', 'make better', 'fix', 'change'];
    final promptLower = prompt.toLowerCase();
    
    // Check if prompt is too short or only contains vague terms
    return prompt.split(' ').length < 3 || 
           vagueWords.any((word) => promptLower.contains(word)) &&
           !_containsSpecificInstructions(prompt);
  }

  bool _containsSpecificInstructions(String prompt) {
    final specificPatterns = [
      RegExp(r'\b(color|brightness|contrast|saturation|hue)\b', caseSensitive: false),
      RegExp(r'\b(blur|sharpen|smooth|noise|grain)\b', caseSensitive: false),
      RegExp(r'\b(crop|resize|rotate|flip)\b', caseSensitive: false),
      RegExp(r'\b(add|remove|replace|move)\b', caseSensitive: false),
    ];
    
    return specificPatterns.any((pattern) => pattern.hasMatch(prompt));
  }

  ModelOptimizer _getModelOptimizer(String modelName) {
    return switch (modelName.toLowerCase()) {
      'gemini-1.5-flash' => GeminiOptimizer(),
      'gemini-1.5-pro' => GeminiProOptimizer(),
      'claude-3' => ClaudeOptimizer(),
      _ => DefaultOptimizer(),
    };
  }
}
```

### 2. AI Processing Orchestrator

```dart
// lib/ai_processing/domain/services/ai_processing_orchestrator.dart
import 'dart:async';
import 'dart:typed_data';
import '../entities/processing_job.dart';
import '../entities/processing_result.dart';
import '../entities/processing_context.dart';
import 'prompt_engineering_service.dart';
import 'image_analysis_service.dart';
import 'vertex_ai_service.dart';
import 'post_processing_service.dart';

class AiProcessingOrchestrator {
  AiProcessingOrchestrator({
    required this.promptService,
    required this.analysisService,
    required this.vertexAiService,
    required this.postProcessingService,
  });

  final PromptEngineeringService promptService;
  final ImageAnalysisService analysisService;
  final VertexAiService vertexAiService;
  final PostProcessingService postProcessingService;

  final Map<String, StreamController<ProcessingProgress>> _progressControllers = {};
  final Map<String, CancelToken> _cancelTokens = {};

  Future<ProcessingResult> processImage({
    required ProcessingJob job,
  }) async {
    final jobId = job.id;
    
    try {
      _initializeProgressTracking(jobId);
      
      // Phase 1: Image Analysis
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.analysis,
        progress: 0.1,
        message: 'Analyzing image...',
      ));
      
      final imageAnalysis = await analysisService.analyzeImage(job.imageData);
      _checkCancellation(jobId);
      
      // Phase 2: Prompt Engineering
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.promptEngineering,
        progress: 0.2,
        message: 'Optimizing prompt...',
      ));
      
      final enhancedPrompt = await promptService.generateEnhancedPrompt(
        userPrompt: job.userPrompt,
        context: job.context,
        imageAnalysis: imageAnalysis,
      );
      _checkCancellation(jobId);
      
      // Phase 3: Prompt Validation
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.validation,
        progress: 0.25,
        message: 'Validating prompt...',
      ));
      
      final validation = await promptService.validatePrompt(enhancedPrompt);
      if (!validation.isValid) {
        throw ProcessingException('Prompt validation failed: ${validation.issues.first.message}');
      }
      _checkCancellation(jobId);
      
      // Phase 4: AI Processing
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.aiProcessing,
        progress: 0.3,
        message: 'Processing with AI...',
      ));
      
      final aiResult = await vertexAiService.processWithAI(
        prompt: enhancedPrompt,
        imageData: job.imageData,
        context: job.context,
        progressCallback: (progress) {
          _updateProgress(jobId, ProcessingProgress(
            jobId: jobId,
            phase: ProcessingPhase.aiProcessing,
            progress: 0.3 + (progress * 0.5), // 30% to 80%
            message: 'AI processing in progress...',
          ));
        },
      );
      _checkCancellation(jobId);
      
      // Phase 5: Post-Processing
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.postProcessing,
        progress: 0.85,
        message: 'Applying final touches...',
      ));
      
      final finalResult = await postProcessingService.enhanceResult(
        aiResult: aiResult,
        originalImage: job.imageData,
        context: job.context,
        imageAnalysis: imageAnalysis,
      );
      _checkCancellation(jobId);
      
      // Phase 6: Quality Assessment
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.qualityCheck,
        progress: 0.95,
        message: 'Validating result quality...',
      ));
      
      final qualityScore = await _assessResultQuality(
        original: job.imageData,
        processed: finalResult.processedImageData,
        context: job.context,
      );
      
      // Complete
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.completed,
        progress: 1.0,
        message: 'Processing completed successfully',
      ));
      
      _cleanupProgressTracking(jobId);
      
      return ProcessingResult(
        jobId: jobId,
        originalImageData: job.imageData,
        processedImageData: finalResult.processedImageData,
        enhancedPrompt: enhancedPrompt,
        imageAnalysis: imageAnalysis,
        qualityScore: qualityScore,
        processingMetadata: ProcessingMetadata(
          processingStartTime: job.startTime,
          processingEndTime: DateTime.now(),
          processingDuration: DateTime.now().difference(job.startTime),
          aiModel: job.context.modelName,
          promptScore: validation.score,
          phases: _getCompletedPhases(jobId),
        ),
      );
      
    } catch (e) {
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.error,
        progress: 0.0,
        message: 'Processing failed: $e',
        error: e.toString(),
      ));
      
      _cleanupProgressTracking(jobId);
      rethrow;
    }
  }

  Stream<ProcessingProgress> watchProgress(String jobId) {
    if (!_progressControllers.containsKey(jobId)) {
      _progressControllers[jobId] = StreamController<ProcessingProgress>.broadcast();
    }
    return _progressControllers[jobId]!.stream;
  }

  Future<void> cancelProcessing(String jobId) async {
    final cancelToken = _cancelTokens[jobId];
    if (cancelToken != null) {
      cancelToken.cancel();
      
      _updateProgress(jobId, ProcessingProgress(
        jobId: jobId,
        phase: ProcessingPhase.cancelled,
        progress: 0.0,
        message: 'Processing cancelled by user',
      ));
      
      _cleanupProgressTracking(jobId);
    }
  }

  Future<List<ProcessingJob>> getActiveJobs() async {
    return _progressControllers.keys
        .map((jobId) => ProcessingJob.fromId(jobId))
        .toList();
  }

  void _initializeProgressTracking(String jobId) {
    _progressControllers[jobId] = StreamController<ProcessingProgress>.broadcast();
    _cancelTokens[jobId] = CancelToken();
  }

  void _updateProgress(String jobId, ProcessingProgress progress) {
    final controller = _progressControllers[jobId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  void _checkCancellation(String jobId) {
    final cancelToken = _cancelTokens[jobId];
    if (cancelToken?.isCancelled == true) {
      throw ProcessingCancelledException('Processing was cancelled');
    }
  }

  void _cleanupProgressTracking(String jobId) {
    _progressControllers[jobId]?.close();
    _progressControllers.remove(jobId);
    _cancelTokens.remove(jobId);
  }

  Future<double> _assessResultQuality(
    Uint8List original,
    Uint8List processed,
    ProcessingContext context,
  ) async {
    // Implement quality assessment logic
    // This could include:
    // - Image similarity metrics
    // - Artifact detection
    // - Color accuracy
    // - Sharpness assessment
    // - Compliance with user requirements
    
    // For now, return a placeholder score
    return 8.5;
  }

  List<ProcessingPhase> _getCompletedPhases(String jobId) {
    // Track completed phases for this job
    return [
      ProcessingPhase.analysis,
      ProcessingPhase.promptEngineering,
      ProcessingPhase.validation,
      ProcessingPhase.aiProcessing,
      ProcessingPhase.postProcessing,
      ProcessingPhase.qualityCheck,
      ProcessingPhase.completed,
    ];
  }

  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _cancelTokens.clear();
  }
}
```

### 3. Advanced Vertex AI Integration

```dart
// lib/ai_processing/data/services/vertex_ai_service_impl.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../domain/entities/processing_context.dart';
import '../../domain/entities/ai_result.dart';
import '../../domain/services/vertex_ai_service.dart';

class VertexAiServiceImpl implements VertexAiService {
  VertexAiServiceImpl({
    required this.vertexAI,
    required this.configService,
  });

  final FirebaseVertexAI vertexAI;
  final AiConfigurationService configService;

  @override
  Future<AiResult> processWithAI({
    required String prompt,
    required Uint8List imageData,
    required ProcessingContext context,
    Function(double)? progressCallback,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Get optimal model configuration
      final config = await configService.getOptimalConfiguration(context);
      
      progressCallback?.call(0.1);
      
      // Initialize the model with context-specific settings
      final model = vertexAI.generativeModel(
        model: config.modelName,
        generationConfig: GenerationConfig(
          temperature: config.temperature,
          topK: config.topK,
          topP: config.topP,
          maxOutputTokens: config.maxOutputTokens,
          candidateCount: 1,
        ),
        safetySettings: _buildSafetySettings(context),
      );
      
      progressCallback?.call(0.2);
      
      // Prepare the content with image and prompt
      final content = [
        Content.multi([
          TextPart(_buildSystemPrompt(context)),
          DataPart(_detectImageMimeType(imageData), imageData),
          TextPart(prompt),
        ])
      ];
      
      progressCallback?.call(0.3);
      
      // Process with retry logic and timeout
      final response = await _processWithRetry(
        model: model,
        content: content,
        context: context,
        progressCallback: progressCallback,
      );
      
      progressCallback?.call(0.9);
      
      // Parse and validate response
      final aiResult = await _parseResponse(
        response: response,
        originalPrompt: prompt,
        processingContext: context,
        startTime: startTime,
      );
      
      progressCallback?.call(1.0);
      
      return aiResult;
      
    } catch (e) {
      throw AiProcessingException('Vertex AI processing failed: $e');
    }
  }

  @override
  Future<List<String>> generatePromptSuggestions({
    required Uint8List imageData,
    required ProcessingContext context,
  }) async {
    try {
      final model = vertexAI.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 500,
        ),
      );
      
      final suggestionPrompt = _buildSuggestionPrompt(context);
      
      final content = [
        Content.multi([
          TextPart(suggestionPrompt),
          DataPart(_detectImageMimeType(imageData), imageData),
        ])
      ];
      
      final response = await model.generateContent(content);
      
      return _parseSuggestions(response.text ?? '');
      
    } catch (e) {
      throw AiProcessingException('Failed to generate suggestions: $e');
    }
  }

  @override
  Future<bool> validateImageCompatibility(
    Uint8List imageData,
    ProcessingContext context,
  ) async {
    try {
      // Check image format
      final mimeType = _detectImageMimeType(imageData);
      if (!_supportedFormats.contains(mimeType)) {
        return false;
      }
      
      // Check image size
      if (imageData.length > _maxImageSize) {
        return false;
      }
      
      // Check image dimensions (if needed)
      final dimensions = await _getImageDimensions(imageData);
      if (dimensions.width < 50 || dimensions.height < 50 ||
          dimensions.width > 4096 || dimensions.height > 4096) {
        return false;
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  Future<GenerateContentResponse> _processWithRetry({
    required GenerativeModel model,
    required List<Content> content,
    required ProcessingContext context,
    Function(double)? progressCallback,
  }) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Set timeout based on context
        final timeout = _calculateTimeout(context);
        
        final response = await model.generateContent(content)
            .timeout(timeout);
        
        // Update progress based on attempt
        final progressIncrement = 0.6 / maxRetries; // 60% of progress for AI processing
        progressCallback?.call(0.3 + ((attempt + 1) * progressIncrement));
        
        return response;
        
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        
        // Exponential backoff
        final delay = baseDelay * (2 << attempt);
        await Future.delayed(delay);
        
        // Log retry attempt
        print('Vertex AI retry ${attempt + 1}/$maxRetries after error: $e');
      }
    }
    
    throw AiProcessingException('Max retries exceeded');
  }

  Future<AiResult> _parseResponse({
    required GenerateContentResponse response,
    required String originalPrompt,
    required ProcessingContext processingContext,
    required DateTime startTime,
  }) async {
    if (response.text == null || response.text!.isEmpty) {
      throw AiProcessingException('Empty response from AI model');
    }
    
    final responseText = response.text!;
    
    // Try to extract structured data from response
    final structuredData = _tryParseStructuredResponse(responseText);
    
    // Extract processing instructions
    final instructions = _extractProcessingInstructions(responseText);
    
    // Calculate confidence score
    final confidence = _calculateConfidenceScore(response, processingContext);
    
    return AiResult(
      rawResponse: responseText,
      structuredData: structuredData,
      processingInstructions: instructions,
      confidence: confidence,
      model: processingContext.modelName,
      processingTime: DateTime.now().difference(startTime),
      usageMetadata: response.usageMetadata != null
          ? UsageMetadata(
              promptTokenCount: response.usageMetadata!.promptTokenCount,
              candidatesTokenCount: response.usageMetadata!.candidatesTokenCount,
              totalTokenCount: response.usageMetadata!.totalTokenCount,
            )
          : null,
    );
  }

  List<SafetySetting> _buildSafetySettings(ProcessingContext context) {
    return [
      SafetySetting(
        HarmCategory.harassment,
        HarmBlockThreshold.medium,
      ),
      SafetySetting(
        HarmCategory.hateSpeech,
        HarmBlockThreshold.medium,
      ),
      SafetySetting(
        HarmCategory.sexuallyExplicit,
        HarmBlockThreshold.medium,
      ),
      SafetySetting(
        HarmCategory.dangerousContent,
        HarmBlockThreshold.medium,
      ),
    ];
  }

  String _buildSystemPrompt(ProcessingContext context) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert image processing AI with the following capabilities:');
    buffer.writeln('- Advanced image analysis and understanding');
    buffer.writeln('- Precise editing instructions generation');
    buffer.writeln('- Quality assessment and optimization');
    buffer.writeln('');
    buffer.writeln('Processing Context:');
    buffer.writeln('- Type: ${context.processingType.name}');
    buffer.writeln('- Quality Level: ${context.qualityLevel.name}');
    buffer.writeln('- Performance Priority: ${context.performancePriority.name}');
    buffer.writeln('');
    buffer.writeln('Please provide detailed, actionable instructions for image processing.');
    buffer.writeln('Focus on the marked areas and user requirements.');
    
    return buffer.toString();
  }

  String _buildSuggestionPrompt(ProcessingContext context) {
    return '''
Analyze this image and suggest 5 specific editing improvements.
Consider the image content, quality, and potential enhancements.
Format your response as a numbered list of actionable suggestions.
Focus on practical improvements that would enhance the image quality or visual appeal.
''';
  }

  List<String> _parseSuggestions(String responseText) {
    final suggestions = <String>[];
    final lines = responseText.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && RegExp(r'^\d+\.').hasMatch(trimmed)) {
        // Remove the number prefix and add to suggestions
        final suggestion = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (suggestion.isNotEmpty) {
          suggestions.add(suggestion);
        }
      }
    }
    
    return suggestions.take(5).toList();
  }

  String _detectImageMimeType(Uint8List imageData) {
    if (imageData.length < 4) return 'image/jpeg';
    
    // Check PNG signature
    if (imageData[0] == 0x89 && imageData[1] == 0x50 && 
        imageData[2] == 0x4E && imageData[3] == 0x47) {
      return 'image/png';
    }
    
    // Check JPEG signature
    if (imageData[0] == 0xFF && imageData[1] == 0xD8) {
      return 'image/jpeg';
    }
    
    // Check WebP signature
    if (imageData.length >= 12 && 
        imageData[0] == 0x52 && imageData[1] == 0x49 && 
        imageData[2] == 0x46 && imageData[3] == 0x46 &&
        imageData[8] == 0x57 && imageData[9] == 0x45 && 
        imageData[10] == 0x42 && imageData[11] == 0x50) {
      return 'image/webp';
    }
    
    // Default to JPEG
    return 'image/jpeg';
  }

  Duration _calculateTimeout(ProcessingContext context) {
    return switch (context.performancePriority) {
      PerformancePriority.speed => const Duration(seconds: 30),
      PerformancePriority.balanced => const Duration(minutes: 2),
      PerformancePriority.quality => const Duration(minutes: 5),
    };
  }

  Map<String, dynamic>? _tryParseStructuredResponse(String responseText) {
    try {
      // Try to find JSON in the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore parsing errors, return null
    }
    return null;
  }

  List<ProcessingInstruction> _extractProcessingInstructions(String responseText) {
    final instructions = <ProcessingInstruction>[];
    final lines = responseText.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // Parse instruction patterns
        if (trimmed.toLowerCase().contains('adjust') || 
            trimmed.toLowerCase().contains('change') ||
            trimmed.toLowerCase().contains('modify')) {
          instructions.add(ProcessingInstruction(
            type: InstructionType.adjustment,
            description: trimmed,
            parameters: _extractParameters(trimmed),
          ));
        }
      }
    }
    
    return instructions;
  }

  Map<String, dynamic> _extractParameters(String instruction) {
    final parameters = <String, dynamic>{};
    
    // Extract numeric values
    final numberMatches = RegExp(r'(\w+):\s*([+-]?\d+(?:\.\d+)?)').allMatches(instruction);
    for (final match in numberMatches) {
      final key = match.group(1)!;
      final value = double.tryParse(match.group(2)!) ?? 0.0;
      parameters[key] = value;
    }
    
    return parameters;
  }

  double _calculateConfidenceScore(
    GenerateContentResponse response,
    ProcessingContext context,
  ) {
    double confidence = 0.7; // Base confidence
    
    // Increase confidence based on response length and detail
    final responseLength = response.text?.length ?? 0;
    if (responseLength > 100) confidence += 0.1;
    if (responseLength > 500) confidence += 0.1;
    
    // Increase confidence for structured responses
    if (_tryParseStructuredResponse(response.text ?? '') != null) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  Future<ImageDimensions> _getImageDimensions(Uint8List imageData) async {
    // Simplified dimension extraction
    // In production, use proper image decoding library
    return const ImageDimensions(width: 800, height: 600);
  }

  static const List<String> _supportedFormats = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB
}
```

### 4. Comprehensive Test Suite

```dart
// test/ai_processing/domain/services/prompt_engineering_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_editor/ai_processing/domain/entities/processing_context.dart';
import 'package:photo_editor/ai_processing/domain/entities/image_analysis.dart';
import 'package:photo_editor/ai_processing/domain/services/prompt_engineering_service.dart';

class MockPromptTemplateRepository extends Mock implements PromptTemplateRepository {}
class MockImageAnalysisService extends Mock implements ImageAnalysisService {}

void main() {
  late PromptEngineeringServiceImpl service;
  late MockPromptTemplateRepository mockTemplateRepository;
  late MockImageAnalysisService mockImageAnalysisService;

  setUp(() {
    mockTemplateRepository = MockPromptTemplateRepository();
    mockImageAnalysisService = MockImageAnalysisService();
    service = PromptEngineeringServiceImpl(
      templateRepository: mockTemplateRepository,
      imageAnalysisService: mockImageAnalysisService,
    );
  });

  group('PromptEngineeringService', () {
    final testContext = ProcessingContext(
      processingType: ProcessingType.enhancement,
      qualityLevel: QualityLevel.high,
      performancePriority: PerformancePriority.balanced,
      modelName: 'gemini-1.5-flash',
      markers: [],
      constraints: [],
    );

    final testImageAnalysis = ImageAnalysis(
      dimensions: const ImageDimensions(width: 800, height: 600),
      format: 'image/jpeg',
      dominantColors: ['blue', 'white', 'green'],
      detectedObjects: ['person', 'building', 'sky'],
      sceneType: 'outdoor',
      lightingConditions: 'daylight',
      qualityScore: 8.5,
    );

    test('generates enhanced prompt with context and analysis', () async {
      // Arrange
      const userPrompt = 'Make this image brighter';
      final template = PromptTemplate.defaultTemplate();
      
      when(() => mockTemplateRepository.getTemplatesForType(any()))
          .thenAnswer((_) async => [template]);

      // Act
      final result = await service.generateEnhancedPrompt(
        userPrompt: userPrompt,
        context: testContext,
        imageAnalysis: testImageAnalysis,
      );

      // Assert
      expect(result, isNotEmpty);
      expect(result, contains(userPrompt));
      expect(result, contains('Image Analysis'));
      expect(result, contains('Processing Guidelines'));
      verify(() => mockTemplateRepository.getTemplatesForType(any())).called(1);
    });

    test('validates prompt correctly', () async {
      // Test valid prompt
      const validPrompt = 'Increase brightness by 20% and enhance contrast';
      final validResult = await service.validatePrompt(validPrompt);
      
      expect(validResult.isValid, isTrue);
      expect(validResult.score, greaterThan(7.0));
      
      // Test invalid prompt (harmful content)
      const harmfulPrompt = 'Create violent imagery with blood and death';
      final harmfulResult = await service.validatePrompt(harmfulPrompt);
      
      expect(harmfulResult.isValid, isFalse);
      expect(harmfulResult.issues, isNotEmpty);
      expect(harmfulResult.issues.first.type, ValidationIssueType.error);
    });

    test('optimizes prompt for specific model', () async {
      // Arrange
      const originalPrompt = 'Enhance this image';
      const modelName = 'gemini-1.5-flash';
      final modelCapabilities = {'maxTokens': 2048, 'supportedFormats': ['image/jpeg']};

      // Act
      final optimizedPrompt = await service.optimizePromptForModel(
        prompt: originalPrompt,
        modelName: modelName,
        modelCapabilities: modelCapabilities,
      );

      // Assert
      expect(optimizedPrompt, isNotEmpty);
      expect(optimizedPrompt.length, greaterThan(originalPrompt.length));
    });

    test('handles vague prompts with suggestions', () async {
      // Arrange
      const vaguePrompt = 'improve';

      // Act
      final result = await service.validatePrompt(vaguePrompt);

      // Assert
      expect(result.issues, isNotEmpty);
      expect(result.issues.any((i) => i.type == ValidationIssueType.suggestion), isTrue);
      expect(result.issues.first.suggestion, contains('more specific'));
    });
  });
}
```

## Performance Optimizations

### 1. Caching Strategy
- Template caching for frequently used prompts
- Model response caching for similar requests
- Image analysis result caching
- Progressive loading for large images

### 2. Resource Management
- Connection pooling for Vertex AI
- Memory-efficient image processing
- Background processing for non-critical tasks
- Automatic cleanup of temporary resources

### 3. Quality Monitoring
- Response time tracking
- Error rate monitoring
- Quality score analytics
- User satisfaction metrics

## Acceptance Criteria
1. ✅ Sophisticated prompt engineering system
2. ✅ Multi-phase processing pipeline
3. ✅ Real-time progress tracking
4. ✅ Robust error handling and recovery
5. ✅ Quality assessment and validation
6. ✅ Cancellation support
7. ✅ Performance optimization
8. ✅ Comprehensive testing (>95% coverage)
9. ✅ Resource management
10. ✅ Monitoring and analytics

**Next Step:** After completion, proceed to results display and gallery implementation (11-results-display.prompt.md)

**Quality Gate:** All tests pass, processing performance under 30 seconds, memory usage optimized
