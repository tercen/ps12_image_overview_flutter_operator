import 'package:flutter/foundation.dart';
import 'package:ps12_image_overview/di/service_locator.dart';
import 'package:ps12_image_overview/models/image_collection.dart';
import 'package:ps12_image_overview/models/filter_criteria.dart';
import 'package:ps12_image_overview/services/image_service.dart';

/// Provider for managing image overview state.
class ImageOverviewProvider extends ChangeNotifier {
  final ImageService _imageService = locator<ImageService>();

  ImageCollection _images = const ImageCollection(images: []);
  ImageCollection _allImages = const ImageCollection(images: []); // Store all images for filter options
  FilterCriteria _filters = const FilterCriteria();
  bool _isLoading = false;
  String? _error;

  ImageCollection get images => _images;
  FilterCriteria get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets available cycle options from ALL images (not just filtered).
  List<int> get availableCycles => _allImages.uniqueCycles;

  /// Gets available exposure time options from ALL images (not just filtered).
  List<int> get availableExposureTimes => _allImages.uniqueExposureTimes;

  /// Loads images from the service.
  /// On initial load, defaults to highest cycle and highest exposure time.
  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allImages = await _imageService.loadImages();

      // On initial load, default to highest cycle and highest exposure time
      final cycles = _allImages.uniqueCycles;
      final exposureTimes = _allImages.uniqueExposureTimes;

      _filters = FilterCriteria(
        cycle: cycles.isNotEmpty ? cycles.last : null, // Last is highest after sort
        exposureTime: exposureTimes.isNotEmpty ? exposureTimes.last : null,
      );
      _images = await _imageService.filterImages(_filters);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Applies filters to the image collection.
  Future<void> applyFilters(FilterCriteria filters) async {
    _filters = filters;
    _isLoading = true;
    notifyListeners();

    try {
      // Always filter through service to get proper grid representation
      // Even with no filters, this returns "all cycles combined" view
      _images = await _imageService.filterImages(filters);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the cycle filter.
  Future<void> setCycleFilter(int? cycle) async {
    final newFilters = _filters.copyWith(cycle: cycle);
    await applyFilters(newFilters);
  }

  /// Updates the exposure time filter.
  Future<void> setExposureTimeFilter(int? exposureTime) async {
    final newFilters = FilterCriteria(
      cycle: _filters.cycle,
      exposureTime: exposureTime,
    );
    await applyFilters(newFilters);
  }

  /// Clears all filters.
  Future<void> clearFilters() async {
    await applyFilters(const FilterCriteria());
  }
}
