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
    // Generate base grid: 4 rows (exposure times) x 3 columns (samples)
    // Each cell will have multiple cycle data
    final baseId = 710415415;
    final columns = [0, 1, 2]; // 3 columns (samples)
    final cycles = [124, 125, 126, 127];
    final exposureTimes = [100, 150, 200, 250]; // 4 rows

    int imageIndex = 0;

    // For each cell position (row/exposure x column/sample), create entries for each cycle
    for (final exposureTime in exposureTimes) {
      for (final col in columns) {
        final row = exposureTimes.indexOf(exposureTime) + 1;

        // For demonstration: Column 2 (third column) is only available for exposure time 250
        // When other exposure times are selected (100, 150, 200), only show 2 columns
        // This simulates: when filtered to lower exposure times, one sample doesn't have that exposure time data

        for (final cycle in cycles) {
          // Generate image IDs
          final imageId = baseId + imageIndex;

          final image = ImageMetadataImpl(
            id: imageId.toString(),
            cycle: cycle,
            exposureTime: exposureTime,
            row: row,
            column: col,
            timestamp: DateTime.now().subtract(Duration(hours: imageIndex)),
            metadata: {
              'label': 'Sample ${col + 1}',
              'position': 'Cycle $cycle, Exp $exposureTime, Col $col',
            },
          );

          _allImages.add(image);
          imageIndex++;
        }
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

    // Filter columns based on exposure time (demo: hide column 2 for non-250 exposure times)
    var filtered = _allImages.where((image) {
      if (criteria.exposureTime != null && criteria.exposureTime != 250) {
        // When filtering by exposure time other than 250, hide column 2 (shows 2 columns instead of 3)
        if (image.column == 2) {
          return false;
        }
      }
      return true;
    }).toList();

    // Then, select one image per cell based on cycle filter
    // Group by row and column to get unique cells
    final Map<String, ImageMetadata> uniqueCells = {};

    for (final image in filtered) {
      final cellKey = '${image.row}_${image.column}';

      // Show only the specific cycle (cycle is never null now)
      if (criteria.cycle != null) {
        if (image.cycle == criteria.cycle) {
          uniqueCells[cellKey] = image;
        }
      } else {
        // Fallback: show first cycle as representative
        if (!uniqueCells.containsKey(cellKey)) {
          uniqueCells[cellKey] = image;
        }
      }
    }

    return ImageCollection(images: uniqueCells.values.toList());
  }
}
