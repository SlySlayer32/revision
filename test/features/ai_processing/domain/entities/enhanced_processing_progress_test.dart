import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/ai_processing/domain/entities/enhanced_processing_progress.dart';

void main() {
  group('ProcessingProgress', () {
    test('should create progress with all fields', () {
      const progress = ProcessingProgress(
        stage: ProcessingStage.analyzing,
        progress: 0.5,
        message: 'Test message',
        estimatedTimeRemaining: Duration(seconds: 30),
        currentStepIndex: 2,
        totalSteps: 5,
        canCancel: true,
        metadata: {'key': 'value'},
      );
      
      expect(progress.stage, equals(ProcessingStage.analyzing));
      expect(progress.progress, equals(0.5));
      expect(progress.message, equals('Test message'));
      expect(progress.estimatedTimeRemaining, equals(Duration(seconds: 30)));
      expect(progress.currentStepIndex, equals(2));
      expect(progress.totalSteps, equals(5));
      expect(progress.canCancel, isTrue);
      expect(progress.metadata, equals({'key': 'value'}));
    });

    test('should calculate progress percentage correctly', () {
      const progress1 = ProcessingProgress(stage: ProcessingStage.analyzing, progress: 0.0);
      const progress2 = ProcessingProgress(stage: ProcessingStage.analyzing, progress: 0.5);
      const progress3 = ProcessingProgress(stage: ProcessingStage.analyzing, progress: 1.0);
      
      expect(progress1.progressPercentage, equals(0));
      expect(progress2.progressPercentage, equals(50));
      expect(progress3.progressPercentage, equals(100));
    });

    test('should identify active states correctly', () {
      const preprocessing = ProcessingProgress(stage: ProcessingStage.preprocessing, progress: 0.5);
      const analyzing = ProcessingProgress(stage: ProcessingStage.analyzing, progress: 0.5);
      const processing = ProcessingProgress(stage: ProcessingStage.processing, progress: 0.5);
      const postProcessing = ProcessingProgress(stage: ProcessingStage.postProcessing, progress: 0.5);
      const completed = ProcessingProgress(stage: ProcessingStage.completed, progress: 1.0);
      const error = ProcessingProgress(stage: ProcessingStage.error, progress: 0.0);
      
      expect(preprocessing.isActive, isTrue);
      expect(analyzing.isActive, isTrue);
      expect(processing.isActive, isTrue);
      expect(postProcessing.isActive, isTrue);
      expect(completed.isActive, isFalse);
      expect(error.isActive, isFalse);
    });

    test('should identify complete states correctly', () {
      const processing = ProcessingProgress(stage: ProcessingStage.processing, progress: 0.5);
      const completed = ProcessingProgress(stage: ProcessingStage.completed, progress: 1.0);
      const cancelled = ProcessingProgress(stage: ProcessingStage.cancelled, progress: 0.0);
      const error = ProcessingProgress(stage: ProcessingStage.error, progress: 0.0);
      
      expect(processing.isComplete, isFalse);
      expect(completed.isComplete, isTrue);
      expect(cancelled.isComplete, isTrue);
      expect(error.isComplete, isTrue);
    });

    test('should create copy with updated fields', () {
      const original = ProcessingProgress(
        stage: ProcessingStage.analyzing,
        progress: 0.5,
        message: 'Original message',
        canCancel: true,
      );
      
      final updated = original.copyWith(
        progress: 0.8,
        message: 'Updated message',
        canCancel: false,
      );
      
      expect(updated.stage, equals(ProcessingStage.analyzing)); // unchanged
      expect(updated.progress, equals(0.8)); // changed
      expect(updated.message, equals('Updated message')); // changed
      expect(updated.canCancel, isFalse); // changed
    });

    group('Factory constructors', () {
      test('should create initializing progress', () {
        final progress = ProcessingProgress.initializing(message: 'Starting...');
        
        expect(progress.stage, equals(ProcessingStage.initializing));
        expect(progress.progress, equals(0.0));
        expect(progress.message, equals('Starting...'));
        expect(progress.canCancel, isTrue);
      });

      test('should create validating progress', () {
        final progress = ProcessingProgress.validating(message: 'Validating...');
        
        expect(progress.stage, equals(ProcessingStage.validating));
        expect(progress.progress, equals(0.1));
        expect(progress.message, equals('Validating...'));
        expect(progress.canCancel, isTrue);
      });

      test('should create preprocessing progress with scaled values', () {
        final progress = ProcessingProgress.preprocessing(
          progress: 0.5,
          message: 'Preprocessing...',
          estimatedTimeRemaining: Duration(seconds: 30),
        );
        
        expect(progress.stage, equals(ProcessingStage.preprocessing));
        expect(progress.progress, equals(0.3)); // 0.2 + (0.5 * 0.2)
        expect(progress.message, equals('Preprocessing...'));
        expect(progress.estimatedTimeRemaining, equals(Duration(seconds: 30)));
        expect(progress.canCancel, isTrue);
      });

      test('should create analyzing progress with scaled values', () {
        final progress = ProcessingProgress.analyzing(
          progress: 0.5,
          message: 'Analyzing...',
          estimatedTimeRemaining: Duration(seconds: 60),
        );
        
        expect(progress.stage, equals(ProcessingStage.analyzing));
        expect(progress.progress, equals(0.55)); // 0.4 + (0.5 * 0.3)
        expect(progress.message, equals('Analyzing...'));
        expect(progress.estimatedTimeRemaining, equals(Duration(seconds: 60)));
        expect(progress.canCancel, isTrue);
      });

      test('should create processing progress with scaled values and no cancel', () {
        final progress = ProcessingProgress.processing(
          progress: 0.5,
          message: 'Processing...',
          estimatedTimeRemaining: Duration(seconds: 45),
        );
        
        expect(progress.stage, equals(ProcessingStage.processing));
        expect(progress.progress, equals(0.8)); // 0.7 + (0.5 * 0.2)
        expect(progress.message, equals('Processing...'));
        expect(progress.estimatedTimeRemaining, equals(Duration(seconds: 45)));
        expect(progress.canCancel, isFalse);
      });

      test('should create post-processing progress with scaled values', () {
        final progress = ProcessingProgress.postProcessing(
          progress: 0.5,
          message: 'Finalizing...',
        );
        
        expect(progress.stage, equals(ProcessingStage.postProcessing));
        expect(progress.progress, equals(0.95)); // 0.9 + (0.5 * 0.1)
        expect(progress.message, equals('Finalizing...'));
        expect(progress.canCancel, isFalse);
      });

      test('should create completed progress', () {
        final progress = ProcessingProgress.completed(message: 'Done!');
        
        expect(progress.stage, equals(ProcessingStage.completed));
        expect(progress.progress, equals(1.0));
        expect(progress.message, equals('Done!'));
        expect(progress.canCancel, isFalse);
      });

      test('should create cancelled progress', () {
        final progress = ProcessingProgress.cancelled(message: 'Cancelled!');
        
        expect(progress.stage, equals(ProcessingStage.cancelled));
        expect(progress.progress, equals(0.0));
        expect(progress.message, equals('Cancelled!'));
        expect(progress.canCancel, isFalse);
      });

      test('should create error progress', () {
        final progress = ProcessingProgress.error(message: 'Error!');
        
        expect(progress.stage, equals(ProcessingStage.error));
        expect(progress.progress, equals(0.0));
        expect(progress.message, equals('Error!'));
        expect(progress.canCancel, isFalse);
      });
    });
  });

  group('ProcessingStage', () {
    test('should have correct display names', () {
      expect(ProcessingStage.initializing.displayName, equals('Initializing'));
      expect(ProcessingStage.validating.displayName, equals('Validating'));
      expect(ProcessingStage.preprocessing.displayName, equals('Preprocessing'));
      expect(ProcessingStage.analyzing.displayName, equals('Analyzing'));
      expect(ProcessingStage.processing.displayName, equals('Processing'));
      expect(ProcessingStage.postProcessing.displayName, equals('Post-processing'));
      expect(ProcessingStage.completed.displayName, equals('Completed'));
      expect(ProcessingStage.cancelled.displayName, equals('Cancelled'));
      expect(ProcessingStage.error.displayName, equals('Error'));
    });

    test('should have correct icons', () {
      expect(ProcessingStage.initializing.icon, equals('🔄'));
      expect(ProcessingStage.validating.icon, equals('✅'));
      expect(ProcessingStage.preprocessing.icon, equals('🔧'));
      expect(ProcessingStage.analyzing.icon, equals('🔍'));
      expect(ProcessingStage.processing.icon, equals('🤖'));
      expect(ProcessingStage.postProcessing.icon, equals('🎨'));
      expect(ProcessingStage.completed.icon, equals('✅'));
      expect(ProcessingStage.cancelled.icon, equals('❌'));
      expect(ProcessingStage.error.icon, equals('⚠️'));
    });
  });
}