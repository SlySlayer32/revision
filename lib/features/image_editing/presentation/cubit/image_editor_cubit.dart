import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:vgv_coffee_machine/features/image_editing/domain/entities/annotation_stroke.dart';

part 'image_editor_state.dart';

class ImageEditorCubit extends Cubit<ImageEditorState> {
  ImageEditorCubit() : super(const ImageEditorInitial());

  void startDrawing(Offset startPoint) {
    final newStroke = AnnotationStroke(points: [startPoint]);
    emit(ImageEditorDrawing(strokes: [...state.strokes, newStroke]));
  }

  void drawing(Offset point) {
    if (state is ImageEditorDrawing) {
      final currentStrokes = (state as ImageEditorDrawing).strokes;
      final currentStroke = currentStrokes.last.copyWith(
        points: [...currentStrokes.last.points, point],
      );
      final updatedStrokes = [...currentStrokes.sublist(0, currentStrokes.length - 1), currentStroke];
      emit(ImageEditorDrawing(strokes: updatedStrokes));
    }
  }

  void endDrawing() {
    emit(ImageEditorIdle(strokes: state.strokes));
  }

  void clearAnnotations() {
    emit(const ImageEditorIdle(strokes: []));
  }
}
