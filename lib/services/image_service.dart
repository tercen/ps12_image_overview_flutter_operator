import 'package:ps12_image_overview/models/image_collection.dart';
import 'package:ps12_image_overview/models/filter_criteria.dart';

/// Abstract interface for image service.
///
/// Provides methods to load, cache, and manage images.
abstract class ImageService {
  /// Loads a collection of images with metadata.
  ///
  /// Returns a [Future] that completes with an [ImageCollection].
  /// Throws an exception if loading fails.
  Future<ImageCollection> loadImages();

  /// Filters images based on criteria.
  ///
  /// Returns a filtered [ImageCollection] matching the criteria.
  Future<ImageCollection> filterImages(FilterCriteria criteria);
}
