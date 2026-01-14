import 'dart:typed_data';

import 'image_metadata.dart';

/// Concrete implementation of ImageMetadata.
class ImageMetadataImpl implements ImageMetadata {
  @override
  final String id;

  @override
  final int cycle;

  @override
  final int exposureTime;

  @override
  final int row;

  @override
  final int column;

  @override
  final DateTime timestamp;

  @override
  final String? imagePath;

  @override
  final Uint8List? imageBytes;

  @override
  final Map<String, dynamic> metadata;

  const ImageMetadataImpl({
    required this.id,
    required this.cycle,
    required this.exposureTime,
    required this.row,
    required this.column,
    required this.timestamp,
    this.imagePath,
    this.imageBytes,
    this.metadata = const {},
  });

  @override
  ImageMetadata copyWith({
    Map<String, dynamic>? metadata,
    String? imagePath,
    Uint8List? imageBytes,
  }) {
    return ImageMetadataImpl(
      id: id,
      cycle: cycle,
      exposureTime: exposureTime,
      row: row,
      column: column,
      timestamp: timestamp,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
