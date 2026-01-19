import 'dart:async';
import 'dart:typed_data';

import 'package:ps12_image_overview/models/filter_criteria.dart';
import 'package:ps12_image_overview/models/image_collection.dart';
import 'package:ps12_image_overview/models/image_metadata.dart';
import 'package:ps12_image_overview/models/image_metadata_impl.dart';
import 'package:ps12_image_overview/services/image_service.dart';
import 'package:ps12_image_overview/utils/image_bytes_cache.dart';
import 'package:ps12_image_overview/utils/tiff_converter.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' show FileDocument;

/// Real implementation of ImageService using Tercen platform API.
///
/// This service fetches TIFF images from Tercen's file storage, converts them
/// to PNG format using the WASM-based TiffConverter, and provides them to the UI.
///
/// Features:
/// - Lazy loading: Fetches metadata first, downloads images on-demand
/// - Caching: Stores converted PNG bytes to avoid redundant conversions
/// - Error handling: Gracefully handles network and conversion errors
class TercenImageService implements ImageService {
  final ServiceFactory _serviceFactory;
  final ImageBytesCache _cache;
  final String? _workflowId;
  final String? _stepId;
  final String? _devZipFileId;

  /// Cached image metadata loaded on startup
  List<ImageMetadata>? _imageMetadata;

  TercenImageService(
    this._serviceFactory, {
    String? workflowId,
    String? stepId,
    String? devZipFileId,
  })  : _cache = ImageBytesCache(),
        _workflowId = workflowId ?? const String.fromEnvironment('WORKFLOW_ID'),
        _stepId = stepId ?? const String.fromEnvironment('STEP_ID'),
        _devZipFileId = devZipFileId ??
            const String.fromEnvironment(
              'DEV_ZIP_FILE_ID',
              // 🔧 DEVELOPMENT: Replace the empty string below with your zip file ID
              // Example: defaultValue: '67890abcdef1234567890abc'
              defaultValue: '', // <-- Put your zip file ID here
            );

  @override
  Future<ImageCollection> loadImages() async {
    try {
      // Get FileService from Tercen ServiceFactory
      final fileService = _serviceFactory.fileService;

      // Fetch FileDocuments from Tercen
      List<FileDocument> files;

      if (_workflowId != null && _stepId != null) {
        // Production: Query by workflow and step
        files = await fileService.findFileByWorkflowIdAndStepId(
          startKey: [_workflowId, _stepId],
          endKey: [_workflowId, _stepId, {}],
          limit: 1000,
        );
      } else if (_devZipFileId != null && _devZipFileId!.isNotEmpty) {
        // Development: Use hardcoded zip file ID
        print('🔧 DEV MODE: Using hardcoded zip file ID: $_devZipFileId');
        try {
          final zipFile = await fileService.get(_devZipFileId!);
          files = [zipFile];
          print('✓ Successfully loaded dev zip file: ${zipFile.name}');
        } catch (e) {
          print('✗ Error loading dev zip file $_devZipFileId: $e');
          print('Falling back to mock data');
          _imageMetadata = _createMockMetadata();
          return ImageCollection(images: _imageMetadata!);
        }
      } else {
        // Fallback: Use mock data
        print('⚠️  No WORKFLOW_ID/STEP_ID or DEV_ZIP_FILE_ID set, using mock data');
        _imageMetadata = _createMockMetadata();
        return ImageCollection(images: _imageMetadata!);
      }

      // Process files - handle both individual TIFF files and zip archives
      final List<ImageMetadata> allMetadata = [];

      for (final file in files) {
        if (_isZipFile(file.name)) {
          // Handle zip file - list contents and create metadata for each TIFF
          final zipEntries = await _loadImagesFromZip(file.id, fileService);
          allMetadata.addAll(zipEntries);
        } else if (_isTiffFile(file.name)) {
          // Handle individual TIFF file
          final metadata = TiffConverter.parseFilename(file.name);

          allMetadata.add(ImageMetadataImpl(
            id: file.id,
            cycle: metadata['pumpCycle'] as int? ?? 0,
            exposureTime: metadata['temperature'] as int? ?? 0,
            row: metadata['field'] as int? ?? 0,
            column: (metadata['well'] as int? ?? 1) - 1, // W1 = column 0
            imagePath: null,
            imageBytes: null, // Lazy-loaded
            timestamp: DateTime.now(),
            metadata: {
              'fileDocumentId': file.id,
              'filename': file.name,
              'isZipEntry': false,
            },
          ));
        }
      }

      _imageMetadata = allMetadata;
      print('Loaded ${_imageMetadata!.length} image metadata entries from Tercen');

      return ImageCollection(images: _imageMetadata!);
    } catch (e, stackTrace) {
      print('Error loading images from Tercen: $e');
      print(stackTrace);
      // Return empty collection on error
      return ImageCollection(images: []);
    }
  }

  @override
  Future<ImageCollection> filterImages(FilterCriteria criteria) async {
    // Ensure metadata is loaded
    if (_imageMetadata == null) {
      await loadImages();
    }

    if (_imageMetadata == null || _imageMetadata!.isEmpty) {
      return ImageCollection(images: []);
    }

    // Client-side filtering (metadata already loaded)
    final filtered = _imageMetadata!.where((image) {
      // Filter by cycle if specified
      if (criteria.cycle != null &&
          image.cycle != criteria.cycle) {
        return false;
      }

      // Filter by exposure time if specified
      if (criteria.exposureTime != null &&
          image.exposureTime != criteria.exposureTime) {
        return false;
      }

      return true;
    }).toList();

    return ImageCollection(images: filtered);
  }

  /// Fetches and converts a TIFF image to PNG bytes.
  ///
  /// This method is intended to be called by the UI layer when an image
  /// needs to be displayed. It checks the cache first, then downloads
  /// and converts the TIFF if necessary.
  ///
  /// Supports both individual files and files within zip archives.
  ///
  /// Returns null if the download or conversion fails.
  Future<Uint8List?> fetchAndConvertImage(String imageId) async {
    // Check cache first
    if (_cache.contains(imageId)) {
      return _cache.get(imageId);
    }

    try {
      // Find the image metadata to determine if it's a zip entry
      final imageMetadata = _imageMetadata?.firstWhere(
        (img) => img.id == imageId,
        orElse: () => throw StateError('Image metadata not found for $imageId'),
      );

      if (imageMetadata == null) {
        throw StateError('Image metadata not loaded');
      }

      final fileService = _serviceFactory.fileService;
      final Stream<List<int>> tiffStream;

      final isZipEntry = imageMetadata.metadata['isZipEntry'] as bool? ?? false;

      if (isZipEntry) {
        // Download from zip archive
        final zipFileId = imageMetadata.metadata['zipFileId'] as String;
        final entryPath = imageMetadata.metadata['zipEntryPath'] as String;
        tiffStream = fileService.downloadZipEntry(zipFileId, entryPath);
      } else {
        // Download regular file
        final fileDocumentId = imageMetadata.metadata['fileDocumentId'] as String;
        tiffStream = fileService.download(fileDocumentId);
      }

      // Collect stream into bytes with timeout
      final tiffBytes = await _collectStreamBytes(tiffStream)
          .timeout(const Duration(seconds: 30));

      // Convert TIFF to PNG
      final pngBytes = TiffConverter.convertToPng(tiffBytes);

      if (pngBytes != null) {
        // Cache the converted PNG
        _cache.put(imageId, pngBytes);
        print(
            'Converted and cached image $imageId (${pngBytes.length ~/ 1024} KB)');
      } else {
        print('Failed to convert TIFF to PNG for image $imageId');
      }

      return pngBytes;
    } on TimeoutException {
      print('Timeout downloading image $imageId');
      return null;
    } catch (e, stackTrace) {
      print('Error fetching image $imageId: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Collects a stream of bytes into a single Uint8List.
  Future<Uint8List> _collectStreamBytes(Stream<List<int>> stream) async {
    final chunks = await stream.toList();
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  /// Creates mock metadata for development/testing when Tercen context is unavailable.
  List<ImageMetadata> _createMockMetadata() {
    final images = <ImageMetadata>[];

    const cycles = [124, 125, 126, 127];
    const exposureTimes = [100, 150, 200, 250];
    const rows = [0, 1, 2, 3];
    const columns = [0, 1, 2];

    var id = 0;
    for (final cycle in cycles) {
      for (final exposure in exposureTimes) {
        for (final row in rows) {
          for (final column in columns) {
            // Simulate filtering: column 2 only available for exposure 250
            if (column == 2 && exposure != 250) {
              continue;
            }

            images.add(ImageMetadataImpl(
              id: 'mock_$id',
              cycle: cycle,
              exposureTime: exposure,
              row: row,
              column: column,
              imagePath: null,
              imageBytes: null,
              timestamp: DateTime.now(),
              metadata: const {'mock': true},
            ));
            id++;
          }
        }
      }
    }

    return images;
  }

  /// Returns cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_images': _cache.length,
      'current_size_mb': _cache.currentSizeMB.toStringAsFixed(2),
      'max_size_mb': _cache.maxSizeMB.toStringAsFixed(2),
      'cache_usage_percent':
          ((_cache.currentSizeMB / _cache.maxSizeMB) * 100).toStringAsFixed(1),
    };
  }

  /// Clears the image cache
  void clearCache() {
    _cache.clear();
    print('Image cache cleared');
  }

  /// Loads images from a zip archive
  Future<List<ImageMetadata>> _loadImagesFromZip(
      String zipFileId, dynamic fileService) async {
    final images = <ImageMetadata>[];

    try {
      // List all entries in the zip file
      final zipEntries = await fileService.listZipContents(zipFileId);

      print('Found ${zipEntries.length} entries in zip file $zipFileId');

      // Filter for TIFF files and create metadata
      for (final entry in zipEntries) {
        final entryName = entry.name as String;

        if (_isTiffFile(entryName)) {
          // Parse filename to extract metadata
          final metadata = TiffConverter.parseFilename(entryName);

          // Generate unique ID combining zip file ID and entry path
          final uniqueId = '${zipFileId}_${entryName.replaceAll('/', '_')}';

          images.add(ImageMetadataImpl(
            id: uniqueId,
            cycle: metadata['pumpCycle'] as int? ?? 0,
            exposureTime: metadata['temperature'] as int? ?? 0,
            row: metadata['field'] as int? ?? 0,
            column: (metadata['well'] as int? ?? 1) - 1, // W1 = column 0
            imagePath: null,
            imageBytes: null, // Lazy-loaded
            timestamp: DateTime.now(),
            metadata: {
              'zipFileId': zipFileId,
              'zipEntryPath': entryName,
              'filename': entryName,
              'isZipEntry': true,
            },
          ));
        }
      }

      print('Extracted ${images.length} TIFF files from zip');
    } catch (e, stackTrace) {
      print('Error loading images from zip $zipFileId: $e');
      print(stackTrace);
    }

    return images;
  }

  /// Checks if a filename is a zip file
  bool _isZipFile(String filename) {
    final lowerName = filename.toLowerCase();
    return lowerName.endsWith('.zip');
  }

  /// Checks if a filename is a TIFF file
  bool _isTiffFile(String filename) {
    final lowerName = filename.toLowerCase();
    return lowerName.endsWith('.tif') || lowerName.endsWith('.tiff');
  }
}
