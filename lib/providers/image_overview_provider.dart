import 'package:flutter/foundation.dart';
import 'package:ps12_image_overview/di/service_locator.dart';
import 'package:ps12_image_overview/models/image_collection.dart';
import 'package:ps12_image_overview/models/filter_criteria.dart';
import 'package:ps12_image_overview/services/image_service.dart';

/// Provider for managing image overview state.
class ImageOverviewProvider extends ChangeNotifier {
  final ImageService _imageService = locator<ImageService>();

  ImageCollection _images = const ImageCollection(images: []);
  FilterCriteria _filters = const FilterCriteria();
  bool _isLoading = false;
  String? _error;

  ImageCollection get images => _images;
  FilterCriteria get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets available cycle options from loaded images.
  List<int> get availableCycles => _images.uniqueCycles;

  /// Gets available exposure time options from loaded images.
  List<int> get availableExposureTimes => _images.uniqueExposureTimes;

  /// Loads images from the service.
  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _images = await _imageService.loadImages();
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
      if (filters.hasActiveFilters) {
        _images = await _imageService.filterImages(filters);
      } else {
        // If no filters, load all images
        _images = await _imageService.loadImages();
      }
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
