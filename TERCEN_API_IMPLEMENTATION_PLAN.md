# Implementation Plan: Tercen Platform API Integration

## Overview

Replace the mock `ImageService` implementation with a real integration to the Tercen platform API. The app will fetch image metadata and TIFF files from Tercen, convert TIFF to PNG client-side using the existing WASM converter, and display images in the grid.

## Architecture

**Data Flow:**
```
Tercen Platform
    ↓ (ServiceFactory initialized with token)
sci_tercen_client (FileService, WorkflowService, etc.)
    ↓ (fetch FileDocuments and binary data)
TercenImageService
    ↓ (convert TIFF → PNG)
TiffConverter (existing)
    ↓ (ImageMetadata with imageBytes)
UI (ImageOverviewProvider)
```

**Key Design Decisions:**

- **Tercen Client:** Use official `sci_tercen_client` Dart package (official Tercen API client)
- **Authentication:** Use `createServiceFactoryForWebApp()` with TERCEN_TOKEN and SERVICE_URI
- **File Download:** Use `FileService.download(fileDocumentId)` to get TIFF binary data as Stream of bytes
- **Architecture:** Use Tercen ServiceFactory pattern - access services via factory.fileService, factory.workflowService, etc.
- **Image Loading:** Lazy-load strategy - fetch metadata first, load/convert images on-demand
- **Caching:** In-memory cache for converted PNG bytes with size limits (50MB max)
- **Metadata:** Extract from Tercen workflow/step context and FileDocument metadata

---

## Files to Create

### 1. `/lib/implementations/services/tercen_image_service.dart`
Business logic layer implementing `ImageService` interface using sci_tercen_client.

**Responsibilities:**

- Use Tercen ServiceFactory to access FileService and WorkflowService
- Implement `loadImages()` - fetch FileDocuments from Tercen workflow/step
- Implement `filterImages()` - filter by cycle and exposure time
- Lazy-load images - download TIFF files and convert to PNG on first display
- Cache converted PNG bytes in memory
- Handle errors gracefully (return empty collections, log details)

**Key Pattern:**
```dart
class TercenImageService implements ImageService {
  final ServiceFactory _serviceFactory;
  final ImageBytesCache _cache;

  TercenImageService(this._serviceFactory) : _cache = ImageBytesCache();

  @override
  Future<ImageCollection> loadImages() async {
    // Get FileService from factory
    final fileService = _serviceFactory.fileService;

    // Find files by workflow/step context
    final files = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
    );

    // Parse filenames to extract metadata (cycle, exposure, row, column)
    final images = files.map((file) {
      final metadata = TiffConverter.parseFilename(file.name);
      return ImageMetadata(
        id: file.id,
        cycle: metadata['pumpCycle'],
        exposureTime: metadata['temperature'],
        row: metadata['field'],
        column: metadata['well'] - 1,  // W1 = column 0
        imagePath: null,  // Using imageBytes instead
        imageBytes: null,  // Lazy-loaded
        timestamp: DateTime.now(),
        metadata: {'fileDocumentId': file.id},
      );
    }).toList();

    return ImageCollection(images: images);
  }

  // Lazy-load helper - download TIFF and convert to PNG
  Future<Uint8List?> fetchAndConvertImage(String fileDocumentId) async {
    if (_cache.contains(fileDocumentId)) {
      return _cache.get(fileDocumentId);
    }

    try {
      // Download TIFF file from Tercen
      final fileService = _serviceFactory.fileService;
      final tiffStream = fileService.download(fileDocumentId);

      // Collect stream into bytes
      final tiffBytes = await _collectStreamBytes(tiffStream);

      // Convert TIFF to PNG
      final pngBytes = TiffConverter.convertToPng(tiffBytes);

      if (pngBytes != null) {
        _cache.put(fileDocumentId, pngBytes);
      }

      return pngBytes;
    } catch (e) {
      print('Error fetching image $fileDocumentId: $e');
      return null;
    }
  }

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
}
```

### 2. `/lib/utils/image_bytes_cache.dart`
In-memory cache for converted PNG bytes with size limits.

**Features:**
- Maximum cache size (50MB)
- LRU eviction when full
- Track current size

---

## Files to Modify

### 1. `/pubspec.yaml`
Add sci_tercen_client dependency.

**Changes:**

```yaml
dependencies:
  # Add Tercen client library (v1.7.0)
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.7.0
      path: sci_tercen_client
```

**Note:** Using version 1.7.0 for stability. This is a Git dependency referencing a specific tag.

### 2. `/lib/di/service_locator.dart`
Register real services using Tercen ServiceFactory when `useMocks: false`.

**Changes:**

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:ps12_image_overview/implementations/services/tercen_image_service.dart';

void setupServiceLocator({bool useMocks = true, ServiceFactory? tercenFactory}) {
  if (useMocks) {
    locator.registerSingleton<ImageService>(MockImageService());
  } else {
    if (tercenFactory == null) {
      throw StateError('Tercen ServiceFactory required when useMocks=false');
    }

    // Register Tercen ServiceFactory
    locator.registerSingleton<ServiceFactory>(tercenFactory);

    // Register real image service
    locator.registerSingleton<ImageService>(
      TercenImageService(tercenFactory),
    );
  }
}
```

### 3. `/lib/main.dart`
Initialize Tercen ServiceFactory and pass to service locator.

**Changes:**

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: true,  // Default to mocks for development
  );

  if (useMocks) {
    setupServiceLocator(useMocks: true);
  } else {
    // Create Tercen ServiceFactory with token and URI from environment
    final tercenFactory = await createServiceFactoryForWebApp();
    setupServiceLocator(useMocks: false, tercenFactory: tercenFactory);
  }

  runApp(const MyApp());
}
```

**Note:** To run with real Tercen API:

```bash
flutter run -d chrome --dart-define=USE_MOCKS=false --dart-define=TERCEN_TOKEN=<token> --dart-define=SERVICE_URI=https://tercen.example.com
```

---

## Implementation Sequence

### Phase 1: Dependencies

1. Add `sci_tercen_client` Git dependency to `pubspec.yaml`
2. Run `flutter pub get` to download dependencies
3. Verify sci_tercen_client imports work

### Phase 2: Cache Implementation

1. Create `ImageBytesCache` utility for in-memory caching with size limits
2. Add unit tests for cache (put, get, eviction)

### Phase 3: Service Implementation

1. Create `TercenImageService` implementing `ImageService`
2. Implement `loadImages()` - fetch FileDocuments using ServiceFactory
3. Implement `filterImages()` - client-side filtering by cycle and exposure
4. Implement `fetchAndConvertImage()` - download TIFF and convert to PNG
5. Add error handling (network errors, invalid TIFF, parsing errors)

### Phase 4: Integration

1. Update `service_locator.dart` to accept and register Tercen ServiceFactory
2. Update `main.dart` to call `createServiceFactoryForWebApp()` when not using mocks
3. Test initialization with TERCEN_TOKEN and SERVICE_URI environment variables

### Phase 5: Testing & Verification

1. Unit tests for `TercenImageService` with mocked ServiceFactory
2. Integration test with real Tercen API (requires live workflow/step with TIFF files)
3. Manual testing checklist (see below)

---

## Error Handling Strategy

### Network Errors
- Timeout: Catch `TimeoutException`, display error message
- HTTP errors (500, 404): Log details, return empty collection
- Connection issues: Display "offline" indicator

### Data Parsing Errors
- Malformed JSON: Log and skip invalid images
- Missing required fields: Provide defaults (e.g., timestamp = now)

### Image Conversion Errors
- Invalid TIFF: `TiffConverter.convertToPng()` returns null → display placeholder
- Out of memory: Limit cache size, evict oldest entries

### Logging
Create structured logs:
```
[INFO] TercenApiClient: GET /api/images (status: 200, duration: 245ms)
[DEBUG] TiffConverter: Converting image 641070616 (size: 4.2MB, success: true)
[ERROR] TercenImageService: Failed to load images - timeout
```

---

## Caching Strategy

### Metadata Cache
- Load once on app startup (`loadImages()`)
- Keep in memory throughout session
- No eviction (metadata is small)

### Image Bytes Cache
- Cache converted PNG bytes (not TIFF)
- Max size: 50MB
- LRU eviction when full
- Key: image ID
- Invalidation: None (session-based)

---

## Testing & Verification

### Unit Tests
**Files to create:**
- `/test/implementations/api/tercen_api_client_test.dart`
- `/test/implementations/services/tercen_image_service_test.dart`
- `/test/utils/tercen_response_parser_test.dart`

**Test scenarios:**
- API client handles 200, 404, 500 responses correctly
- Service lazy-loads images on demand
- Cache limits enforced (max 50MB)
- Parser handles valid and malformed JSON

### Integration Test
**File:** `/test/integration/tercen_integration_test.dart`

Connect to staging Tercen API, fetch real data, verify grid structure.

### Manual Testing Checklist
1. ✓ App starts with `USE_MOCKS=false`, connects to Tercen API
2. ✓ Grid displays with correct cycles, exposure times, rows, columns
3. ✓ Images load and display correctly after TIFF conversion
4. ✓ Cycle filter updates grid correctly
5. ✓ Exposure time filter updates grid correctly
6. ✓ Network error displays user-friendly message
7. ✓ App responds within 2 seconds for filtering (metadata cached)
8. ✓ Memory usage stays reasonable (no leaks from image loading)

---

## Critical Files

**New files:**

- [lib/implementations/services/tercen_image_service.dart](lib/implementations/services/tercen_image_service.dart) - Business logic implementing ImageService using sci_tercen_client
- [lib/utils/image_bytes_cache.dart](lib/utils/image_bytes_cache.dart) - In-memory cache with size limits and LRU eviction

**Modified files:**

- [pubspec.yaml](pubspec.yaml) - Add `sci_tercen_client` Git dependency
- [lib/di/service_locator.dart](lib/di/service_locator.dart:26-34) - Accept Tercen ServiceFactory and register TercenImageService
- [lib/main.dart](lib/main.dart:10) - Call `createServiceFactoryForWebApp()` when not using mocks

**Existing (no changes needed):**

- [lib/services/image_service.dart](lib/services/image_service.dart) - Interface already defined
- [lib/utils/tiff_converter.dart](lib/utils/tiff_converter.dart) - TIFF conversion ready to use (including filename parsing)
- [lib/models/image_metadata.dart](lib/models/image_metadata.dart) - Supports both asset paths and runtime bytes

---

## Environment Variables

```bash
# Enable real Tercen integration (default: true for mocks)
USE_MOCKS=false

# Tercen authentication token (required when USE_MOCKS=false)
TERCEN_TOKEN=<your_tercen_jwt_token>

# Tercen service URI (required when USE_MOCKS=false)
SERVICE_URI=https://tercen.example.com

# Optional: Workflow and Step IDs (if not auto-detected from context)
WORKFLOW_ID=<workflow_id>
STEP_ID=<step_id>
```

**Usage:**

```bash
# Development with mocks (default)
flutter run -d chrome

# Development with real Tercen API
flutter run -d chrome \
  --dart-define=USE_MOCKS=false \
  --dart-define=TERCEN_TOKEN=eyJhbGc... \
  --dart-define=SERVICE_URI=https://tercen.example.com
```

---

## Notes

- **Simplified Architecture:** Using official `sci_tercen_client` eliminates the need for custom HTTP client, API configuration, and response parsing
- **Official Tercen Integration:** The `sci_tercen_client` is Tercen's official Dart client library with built-in authentication and service discovery
- **ServiceFactory Pattern:** Tercen uses a factory pattern - initialize once with `createServiceFactoryForWebApp()`, then access services via `factory.fileService`, `factory.workflowService`, etc.
- **File Download:** The `FileService.download()` method returns a `Stream<List<int>>` that must be collected into `Uint8List` before TIFF conversion
- **Filename Parsing:** Existing `TiffConverter.parseFilename()` can extract metadata (well, field, temperature, pump cycle, etc.) from TIFF filenames
- **Lazy-Loading:** Fetch only FileDocument metadata on start-up; download and convert TIFF files on-demand when images are displayed
- **Clean Architecture:** Existing `ImageService` abstraction means UI code requires zero changes
- **Environment Variables:** `TERCEN_TOKEN` and `SERVICE_URI` are standard Tercen operator environment variables

---

## Risks & Mitigation

**Risk:** Large TIFF files slow down conversion

**Mitigation:** Convert in background, show loading indicator, cache converted PNG aggressively

**Risk:** Workflow/Step context not available in operator

**Mitigation:** Accept WORKFLOW_ID and STEP_ID as environment variables, provide fallback to query FileDocuments by project

**Risk:** Memory issues with 100+ images

**Mitigation:** Strict cache size limit (50MB), LRU eviction, lazy-loading (only download when displayed)

**Risk:** FileDocument filenames don't match expected pattern

**Mitigation:** Use TiffConverter.parseFilename() which handles errors gracefully; fall back to default metadata values

**Risk:** Stream collection fails or hangs

**Mitigation:** Add timeout to stream collection, handle errors gracefully, return null on failure
