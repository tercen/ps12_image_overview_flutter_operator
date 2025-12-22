import 'image_metadata.dart';

/// Collection of images with utility methods.
class ImageCollection {
  final List<ImageMetadata> images;

  const ImageCollection({required this.images});

  /// Returns the number of images.
  int get count => images.length;

  /// Creates a copy with updated images.
  ImageCollection copyWith({List<ImageMetadata>? images}) {
    return ImageCollection(images: images ?? this.images);
  }

  /// Groups images by row number.
  Map<int, List<ImageMetadata>> groupByRow() {
    final Map<int, List<ImageMetadata>> grouped = {};
    for (final image in images) {
      grouped.putIfAbsent(image.row, () => []).add(image);
    }
    return grouped;
  }

  /// Gets unique cycle values.
  List<int> get uniqueCycles {
    return images.map((img) => img.cycle).toSet().toList()..sort();
  }

  /// Gets unique exposure time values.
  List<int> get uniqueExposureTimes {
    return images.map((img) => img.exposureTime).toSet().toList()..sort();
  }
}
