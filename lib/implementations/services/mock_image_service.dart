import 'package:ps12_image_overview/models/image_collection.dart';
import 'package:ps12_image_overview/models/image_metadata.dart';
import 'package:ps12_image_overview/models/image_metadata_impl.dart';
import 'package:ps12_image_overview/models/filter_criteria.dart';
import 'package:ps12_image_overview/services/image_service.dart';

/// Mock implementation of ImageService for development and testing.
///
/// Returns predefined image data from sample sources.
class MockImageService implements ImageService {
  // Cache for loaded images
  final List<ImageMetadata> _allImages = [];

  MockImageService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate mock images matching the UI: 4 rows x 3 columns
    // Image IDs like: 710415415, 710415416, 710415419
    final baseId = 710415415;
    final cycles = [124, 125, 126, 127];
    final exposureTimes = [100, 150, 200, 250];

    int imageIndex = 0;

    // Create 4 rows of images
    for (int row = 1; row <= 4; row++) {
      // Create 3 columns of images per row
      for (int col = 0; col < 3; col++) {
        // Generate image IDs similar to the UI (710415415, 710415416, 710415419, etc.)
        final imageId = baseId + imageIndex;

        // Vary cycles and exposure times
        final cycle = cycles[row % cycles.length];
        final exposureTime = exposureTimes[(row + col) % exposureTimes.length];

        final image = ImageMetadataImpl(
          id: imageId.toString(),
          cycle: cycle,
          exposureTime: exposureTime,
          row: row,
          column: col,
          timestamp: DateTime.now().subtract(Duration(hours: imageIndex)),
          metadata: {
            'label': 'Image $imageId',
            'position': 'Row $row, Column $col',
          },
        );

        _allImages.add(image);
        imageIndex++;
      }
    }
  }

  @override
  Future<ImageCollection> loadImages() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return ImageCollection(images: List.from(_allImages));
  }

  @override
  Future<ImageCollection> filterImages(FilterCriteria criteria) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = _allImages.where((image) {
      // Apply cycle filter
      if (criteria.cycle != null) {
        if (image.cycle != criteria.cycle) {
          return false;
        }
      }

      // Apply exposure time filter
      if (criteria.exposureTime != null) {
        if (image.exposureTime != criteria.exposureTime) {
          return false;
        }
      }

      return true;
    }).toList();

    return ImageCollection(images: filtered);
  }
}
