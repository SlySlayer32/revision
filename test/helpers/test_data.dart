import 'dart:typed_data';

/// A minimal, valid 1x1 PNG image.
///
/// This can be used in tests to provide valid image data that passes
/// basic format validation checks.
final Uint8List kTestPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
  120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 163, 29, 213, 134, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130,
]);
