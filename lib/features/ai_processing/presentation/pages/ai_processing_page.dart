import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/view/ai_processing_view.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Page for AI processing functionality.
///
/// This page provides the interface for users to apply AI effects to their images.
/// It follows the VGV page/view separation pattern.
class AiProcessingPage extends StatelessWidget {
  const AiProcessingPage({
    required this.selectedImage,
    this.annotatedImage,
    super.key,
  });

  final SelectedImage selectedImage;
  final AnnotatedImage? annotatedImage;

  static Route<void> route(
    SelectedImage selectedImage, {
    AnnotatedImage? annotatedImage,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => AiProcessingPage(
        selectedImage: selectedImage,
        annotatedImage: annotatedImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Processing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocProvider(
        create: (context) => getIt<GeminiPipelineCubit>(),
        child: AiProcessingView(
          image: selectedImage,
          annotatedImage: annotatedImage,
        ),
      ),
    );
  }
}
