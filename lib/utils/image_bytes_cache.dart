import 'dart:typed_data';

/// In-memory cache for converted PNG image bytes with size limits and LRU eviction.
///
/// This cache prevents redundant TIFF downloads and conversions by storing
/// converted PNG bytes in memory. When the cache exceeds the maximum size,
/// the least recently used entries are evicted.
class ImageBytesCache {
  /// Maximum cache size in bytes (default: 50MB)
  final int maxCacheSizeBytes;

  /// Internal cache storage mapping image IDs to their PNG bytes
  final Map<String, Uint8List> _cache = {};

  /// LRU tracking - maps image ID to last access timestamp
  final Map<String, DateTime> _accessTimes = {};

  /// Current total size of cached data in bytes
  int _currentSizeBytes = 0;

  ImageBytesCache({this.maxCacheSizeBytes = 50 * 1024 * 1024}); // 50MB default

  /// Checks if an image is in the cache
  bool contains(String imageId) => _cache.containsKey(imageId);

  /// Retrieves cached PNG bytes for an image, or null if not cached
  ///
  /// Updates the access time for LRU tracking
  Uint8List? get(String imageId) {
    if (!_cache.containsKey(imageId)) {
      return null;
    }

    // Update access time for LRU
    _accessTimes[imageId] = DateTime.now();

    return _cache[imageId];
  }

  /// Stores PNG bytes in the cache
  ///
  /// If adding this entry would exceed the maximum cache size,
  /// evicts the least recently used entries first.
  void put(String imageId, Uint8List bytes) {
    // If already cached, remove old entry first
    if (_cache.containsKey(imageId)) {
      _currentSizeBytes -= _cache[imageId]!.length;
    }

    // Evict LRU entries until there's enough space
    while (_currentSizeBytes + bytes.length > maxCacheSizeBytes &&
        _cache.isNotEmpty) {
      _evictOldest();
    }

    // Don't cache if the single image is larger than max cache size
    if (bytes.length > maxCacheSizeBytes) {
      return;
    }

    // Add to cache
    _cache[imageId] = bytes;
    _accessTimes[imageId] = DateTime.now();
    _currentSizeBytes += bytes.length;
  }

  /// Evicts the least recently used entry from the cache
  void _evictOldest() {
    if (_cache.isEmpty) return;

    // Find the entry with the oldest access time
    String? oldestId;
    DateTime? oldestTime;

    for (final entry in _accessTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestId = entry.key;
      }
    }

    if (oldestId != null) {
      _currentSizeBytes -= _cache[oldestId]!.length;
      _cache.remove(oldestId);
      _accessTimes.remove(oldestId);
    }
  }

  /// Clears all entries from the cache
  void clear() {
    _cache.clear();
    _accessTimes.clear();
    _currentSizeBytes = 0;
  }

  /// Returns the current size of cached data in bytes
  int get currentSizeBytes => _currentSizeBytes;

  /// Returns the number of images currently cached
  int get length => _cache.length;

  /// Returns the current size of cached data in megabytes
  double get currentSizeMB => _currentSizeBytes / (1024 * 1024);

  /// Returns the maximum cache size in megabytes
  double get maxSizeMB => maxCacheSizeBytes / (1024 * 1024);
}
