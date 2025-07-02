import 'package:equatable/equatable.dart';

class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];

  Map<String, dynamic> toAIMap() {
    return {
      'id': id,
      'label': label,
    };
  }
}
