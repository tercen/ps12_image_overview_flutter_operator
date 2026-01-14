import 'dart:typed_data';

/// Abstract interface for image metadata.
abstract class ImageMetadata {
  /// Unique identifier for the image.
  String get id;

  /// Cycle number associated with the image.
  int get cycle;

  /// Exposure time for the image.
  int get exposureTime;

  /// Row position in the grid.
  int get row;

  /// Column position in the grid.
  int get column;

  /// Timestamp when image was captured/created.
  DateTime get timestamp;

  /// Path to the image asset (for bundled assets).
  String? get imagePath;

  /// Raw image bytes (PNG format, for runtime-loaded images).
  /// Use this when images are fetched from API and converted at runtime.
  Uint8List? get imageBytes;

  /// Additional metadata as key-value pairs.
  Map<String, dynamic> get metadata;

  /// Creates a copy with updated fields.
  ImageMetadata copyWith({
    Map<String, dynamic>? metadata,
    Uint8List? imageBytes,
  });
}
