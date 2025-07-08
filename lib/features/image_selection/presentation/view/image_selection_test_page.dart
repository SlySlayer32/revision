import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:revision/features/image_selection/image_selection.dart';

/// Simple test page for image selection feature
class ImageSelectionTestPage extends StatelessWidget {
  const ImageSelectionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImageSelectionCubit(
        SelectImageUseCase(
          ImageSelectionRepositoryImpl(ImagePickerDataSource(ImagePicker())),
        ),
      ),
      child: const ImageSelectionView(),
    );
  }
}
