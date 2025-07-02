part of 'image_editor_cubit.dart';

abstract class ImageEditorState extends Equatable {
  final List<AnnotationStroke> strokes;

  const ImageEditorState({this.strokes = const []});

  @override
  List<Object> get props => [strokes];
}

class ImageEditorInitial extends ImageEditorState {
  const ImageEditorInitial() : super(strokes: const []);
}

class ImageEditorIdle extends ImageEditorState {
  const ImageEditorIdle({required super.strokes});
}

class ImageEditorDrawing extends ImageEditorState {
  const ImageEditorDrawing({required super.strokes});
}
