import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';

void main() {
  group('ImageSource', () {
    test('gallery has correct name', () {
      expect(ImageSource.gallery.name, 'gallery');
    });

    test('camera has correct name', () {
      expect(ImageSource.camera.name, 'camera');
    });

    test('values contains all sources', () {
      expect(ImageSource.values, [ImageSource.gallery, ImageSource.camera]);
    });

    test('supports value equality', () {
      expect(ImageSource.gallery, ImageSource.gallery);
      expect(ImageSource.camera, ImageSource.camera);
      expect(ImageSource.gallery == ImageSource.camera, isFalse);
    });
  });
}
