# [PROJECT_NAME] - Technical Specification v[VERSION]

**Created:** [DATE]

**Version:** [VERSION]

**Status:** [Draft | In Progress | Approved | Implemented]

---

## Document Overview

This document specifies the technical architecture, patterns, and implementation requirements for version [VERSION] of [PROJECT_NAME]. This specification provides a structured approach to Flutter application development with clean architecture principles.

---

## How to Use This Template

This is a **generic technical specification template** for Flutter applications. To adapt it for your project:

1. **Replace all placeholders** with your actual values:
   - `[PROJECT_NAME]` → Your project name
   - `[VERSION]` → Your version number (e.g., 0.0.1, 1.0.0)
   - `[DATE]` → Current date
   - `[AUTHOR]` → Your name
   - `[package_name]` → Your Flutter package name
   - `[Service]` / `[service]` → Your service name (e.g., Image, Product, User)
   - `[Entity]` / `[entity]` / `[entities]` / `[Entities]` → Your domain entity (e.g., Image/image/images/Images)
   - `[Feature]` / `[feature]` → Your feature name (e.g., Gallery, Dashboard)
   - `[Widget]` / `[widget]` → Your widget names
   - `[Screen]` / `[screen]` → Your screen names

2. **Customize sections** based on your needs:
   - Update the Goals and Non-Goals to match your project scope
   - Modify service interfaces to match your domain requirements
   - Add or remove sections as appropriate
   - Update dependencies based on your specific requirements

3. **Remove this section** once you've customized the template for your project

---

## Version [VERSION] Scope

Version [VERSION] is a **Minimum Viable Product (MVP)** focused on establishing the core architecture with abstraction layers and mock implementations.

### Goals
- Establish project architecture with abstraction layers
- Implement service injection pattern using GetIt
- Create mock services for development and testing
- Build core UI components and screens
- Demonstrate data loading and display
- Validate architecture for future real backend integration
- Provide theme support (light/dark modes)

### Non-Goals (Deferred to Future Versions)
- Real backend API integration
- Persistent storage/database
- Advanced features beyond MVP
- Authentication/authorization
- Full mobile/tablet responsiveness
- Advanced user customization

---

## Architecture Overview

### Layered Architecture

The application follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │   Screens    │  │   Widgets    │  │ Providers│  │
│  └──────────────┘  └──────────────┘  └──────────┘  │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Domain Layer                      │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │    Models    │  │   Services   │                 │
│  │  (Abstract)  │  │  (Abstract)  │                 │
│  └──────────────┘  └──────────────┘                 │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                Implementation Layer                 │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │  Mock Impls  │  │  Real Impls  │                 │
│  │   (v0.0.1)   │  │   (Future)   │                 │
│  └──────────────┘  └──────────────┘                 │
└─────────────────────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart                          # Application entry point
├── di/
│   └── service_locator.dart          # Dependency injection setup
├── models/
│   ├── [model_name].dart             # Abstract model interfaces
│   ├── [model_name]_impl.dart        # Concrete implementations
│   └── [collection_name].dart        # Collection models
├── services/
│   ├── [service_name]_service.dart   # Abstract service interfaces
│   ├── api_service.dart              # Abstract API interface
│   └── storage_service.dart          # Abstract storage interface
├── implementations/
│   └── services/
│       ├── mock_[service]_service.dart  # Mock service implementations
│       └── real_[service]_service.dart  # Real service implementations (future)
├── providers/
│   ├── [feature]_provider.dart       # Feature-specific state management
│   └── theme_provider.dart           # Theme state management
├── screens/
│   ├── [screen_name]_screen.dart     # Application screens
│   └── detail_screen.dart            # Detail/secondary screens
└── widgets/
    ├── [widget_name].dart            # Reusable UI components
    └── [custom_widget].dart          # Custom widgets

test/
├── models/                            # Model tests
├── services/                          # Service interface tests
├── implementations/
│   └── services/                      # Mock service tests
├── providers/                         # Provider tests
└── widgets/                           # Widget tests

integration_test/
└── [feature]_flow_test.dart          # End-to-end tests
```

---

## Dependency Injection Pattern

### Service Locator Setup

Using **GetIt** for dependency injection to enable:
- Easy mocking for tests
- Swapping between mock and real implementations
- Singleton service management
- Clear dependency management

**Implementation:**

```dart
// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:[package_name]/implementations/services/mock_[service]_service.dart';
import 'package:[package_name]/implementations/services/mock_api_service.dart';
import 'package:[package_name]/implementations/services/mock_storage_service.dart';
import 'package:[package_name]/services/[service]_service.dart';
import 'package:[package_name]/services/api_service.dart';
import 'package:[package_name]/services/storage_service.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Alias for backwards compatibility
final GetIt locator = getIt;

/// Sets up the service locator with dependency registrations.
///
/// Call this function before running the app to register all services.
///
/// Parameters:
///   - [useMocks]: If true, registers mock implementations. If false, registers
///     real implementations (when available). Defaults to true.
///
/// Example:
/// ```dart
/// void main() {
///   setupServiceLocator(useMocks: true);
///   runApp(MyApp());
/// }
/// ```
void setupServiceLocator({bool useMocks = true}) {
  if (useMocks) {
    // Register mock services
    locator.registerSingleton<[Service]Service>(Mock[Service]Service());
    locator.registerSingleton<ApiService>(MockApiService());
    locator.registerSingleton<StorageService>(MockStorageService());
  } else {
    // TODO: Register real services when implemented
    // locator.registerSingleton<[Service]Service>(Real[Service]Service());
    // locator.registerSingleton<ApiService>(RealApiService());
    // locator.registerSingleton<StorageService>(RealStorageService());
    throw UnimplementedError('Real services not yet implemented');
  }
}

/// Resets the service locator.
///
/// Useful for testing to ensure a clean state between tests.
Future<void> resetServiceLocator() async {
  await locator.reset();
}
```

**Usage in main.dart:**

```dart
void main() {
  setupServiceLocator(useMocks: true);
  runApp(const MyApp());
}
```

**Usage in widgets:**

```dart
class [Screen]Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = locator<[Service]Service>();
    // Use service...
  }
}
```

---

## Service Abstractions

### 1. [Primary Domain]Service

**Purpose:** Abstract interface for [primary domain functionality] management.

**Interface:**

```dart
/// Abstract interface for [domain] service.
///
/// Provides methods to load, cache, and manage [domain entities].
abstract class [Service]Service {
  /// Loads a collection of [entities] with metadata.
  ///
  /// Returns a [Future] that completes with a [EntityCollection].
  /// Throws an exception if loading fails.
  Future<[Entity]Collection> load[Entities]();

  /// Loads a single [entity] by ID.
  ///
  /// Returns a [Future] that completes with [EntityMetadata].
  /// Throws an exception if [entity] is not found.
  Future<[Entity]Metadata> get[Entity]ById(String id);

  /// Filters [entities] based on criteria.
  ///
  /// Returns a filtered [EntityCollection] matching the criteria.
  Future<[Entity]Collection> filter[Entities](FilterCriteria criteria);

  /// Searches [entities] by query string.
  ///
  /// Searches through [entity] metadata (ID, labels, tags).
  Future<[Entity]Collection> search[Entities](String query);
}
```

**Mock Implementation:**

```dart
/// Mock implementation of [Service]Service for development and testing.
///
/// Returns predefined [entity] data from sample sources.
class Mock[Service]Service implements [Service]Service {
  // Cache for loaded [entities]
  final Map<String, [Entity]Metadata> _[entity]Cache = {};
  final List<[Entity]Metadata> _all[Entities] = [];

  Mock[Service]Service() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate mock [entities] using sample data or local assets
    for (int i = 1; i <= 50; i++) {
      final [entity] = [Entity]MetadataImpl(
        id: '[entity]_$i',
        // Add additional fields specific to your domain
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        metadata: {
          'label': 'Sample [Entity] $i',
          'category': i % 3 == 0 ? 'Category A' : 'Category B',
          // Add other metadata fields
        },
      );
      _all[Entities].add([entity]);
      _[entity]Cache[[entity].id] = [entity];
    }
  }

  @override
  Future<[Entity]Collection> load[Entities]() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return [Entity]Collection([entities]: List.from(_all[Entities]));
  }

  @override
  Future<[Entity]Metadata> get[Entity]ById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_[entity]Cache.containsKey(id)) {
      throw Exception('[Entity] not found: $id');
    }

    return _[entity]Cache[id]!;
  }

  @override
  Future<[Entity]Collection> filter[Entities](FilterCriteria criteria) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = _all[Entities].where(([entity]) {
      // Apply filters based on criteria
      if (criteria.category != null) {
        if ([entity].metadata['category'] != criteria.category) {
          return false;
        }
      }

      if (criteria.dateRange != null) {
        // Filter by date range
        // Implementation details...
      }

      return true;
    }).toList();

    return [Entity]Collection([entities]: filtered);
  }

  @override
  Future<[Entity]Collection> search[Entities](String query) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (query.isEmpty) {
      return load[Entities]();
    }

    final queryLower = query.toLowerCase();
    final results = _all[Entities].where(([entity]) {
      return [entity].id.toLowerCase().contains(queryLower) ||
             [entity].metadata['label']?.toLowerCase().contains(queryLower) == true;
    }).toList();

    return [Entity]Collection([entities]: results);
  }
}
```

### 2. ApiService

**Purpose:** Abstract interface for backend API integration.

**Interface:**

```dart
/// Abstract interface for API service.
///
/// Provides methods to communicate with backend platform.
abstract class ApiService {
  /// Authenticates with backend using provided credentials.
  Future<bool> authenticate(String token);

  /// Fetches data from backend.
  Future<Map<String, dynamic>> getData(String dataId);

  /// Fetches configuration.
  Future<Map<String, dynamic>> getConfig(String configId);

  /// Saves output data.
  Future<void> saveOutput(String id, Map<String, dynamic> data);

  /// Saves application state.
  Future<void> saveState(String id, Map<String, dynamic> state);

  /// Loads application state.
  Future<Map<String, dynamic>> loadState(String id);
}
```

**Mock Implementation:**

```dart
/// Mock implementation of ApiService for development and testing.
class MockApiService implements ApiService {
  bool _isAuthenticated = false;
  final Map<String, dynamic> _mockState = {};

  @override
  Future<bool> authenticate(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock authentication always succeeds for non-empty tokens
    _isAuthenticated = token.isNotEmpty;
    return _isAuthenticated;
  }

  @override
  Future<Map<String, dynamic>> getData(String dataId) async {
    if (!_isAuthenticated) {
      throw Exception('Not authenticated');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock data
    return {
      'dataId': dataId,
      '[entities]': List.generate(20, (i) => {
        'id': '[entity]_$i',
        // Add mock data fields specific to your domain
        'metadata': {
          'field1': 'Value_${String.fromCharCode(65 + (i % 8))}${(i % 12) + 1}',
          'field2': i % 4,
          'field3': i % 3 == 0 ? 'Type A' : i % 3 == 1 ? 'Type B' : 'Type C',
        }
      }),
    };
  }

  @override
  Future<Map<String, dynamic>> getConfig(String configId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'configId': configId,
      'config': {
        'setting1': 'value1',
        'setting2': 200,
        'setting3': true,
        // Add mock configuration fields
      }
    };
  }

  @override
  Future<void> saveOutput(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // In real implementation, this would save to backend
    print('Mock: Saving output for $id');
  }

  @override
  Future<void> saveState(String id, Map<String, dynamic> state) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockState[id] = state;
  }

  @override
  Future<Map<String, dynamic>> loadState(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockState[id] ?? {};
  }
}
```

### 3. StorageService

**Purpose:** Abstract interface for local/session storage.

**Interface:**

```dart
/// Abstract interface for storage service.
abstract class StorageService {
  /// Saves user selections.
  Future<void> saveSelections(List<String> imageIds);

  /// Loads user selections.
  Future<List<String>> loadSelections();

  /// Saves filter preferences.
  Future<void> saveFilters(FilterCriteria filters);

  /// Loads filter preferences.
  Future<FilterCriteria?> loadFilters();

  /// Clears all stored data.
  Future<void> clear();
}
```

---

## Data Models

### [Entity]Metadata (Abstract)

```dart
/// Abstract interface for [entity] metadata.
abstract class [Entity]Metadata {
  /// Unique identifier for the [entity].
  String get id;

  /// Timestamp when [entity] was captured/created.
  DateTime get timestamp;

  /// Additional metadata as key-value pairs.
  Map<String, dynamic> get metadata;

  /// Whether this [entity] is currently selected.
  bool get isSelected;

  /// Creates a copy with updated fields.
  [Entity]Metadata copyWith({
    bool? isSelected,
    Map<String, dynamic>? metadata,
  });
}
```

### [Entity]Metadata Implementation

```dart
/// Concrete implementation of [Entity]Metadata.
class [Entity]MetadataImpl implements [Entity]Metadata {
  @override
  final String id;

  @override
  final DateTime timestamp;

  @override
  final Map<String, dynamic> metadata;

  @override
  final bool isSelected;

  const [Entity]MetadataImpl({
    required this.id,
    required this.timestamp,
    required this.metadata,
    this.isSelected = false,
  });

  @override
  [Entity]Metadata copyWith({
    bool? isSelected,
    Map<String, dynamic>? metadata,
  }) {
    return [Entity]MetadataImpl(
      id: id,
      timestamp: timestamp,
      metadata: metadata ?? this.metadata,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is [Entity]Metadata &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### [Entity]Collection

```dart
/// Collection of [entities] with utility methods.
class [Entity]Collection {
  final List<[Entity]Metadata> [entities];

  const [Entity]Collection({required this.[entities]});

  /// Returns the number of [entities].
  int get count => [entities].length;

  /// Returns selected [entities].
  List<[Entity]Metadata> get selected =>
      [entities].where((item) => item.isSelected).toList();

  /// Returns unselected [entities].
  List<[Entity]Metadata> get unselected =>
      [entities].where((item) => !item.isSelected).toList();

  /// Creates a copy with updated [entities].
  [Entity]Collection copyWith({List<[Entity]Metadata>? [entities]}) {
    return [Entity]Collection([entities]: [entities] ?? this.[entities]);
  }
}
```

### FilterCriteria

```dart
/// Criteria for filtering images.
class FilterCriteria {
  final String? category;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? customFilters;

  const FilterCriteria({
    this.category,
    this.dateRange,
    this.customFilters,
  });

  /// Creates a copy with updated fields.
  FilterCriteria copyWith({
    String? category,
    DateTimeRange? dateRange,
    Map<String, dynamic>? customFilters,
  }) {
    return FilterCriteria(
      category: category ?? this.category,
      dateRange: dateRange ?? this.dateRange,
      customFilters: customFilters ?? this.customFilters,
    );
  }

  /// Checks if any filters are active.
  bool get hasActiveFilters =>
      category != null || dateRange != null || customFilters?.isNotEmpty == true;
}
```

---

## State Management with Provider

### [Feature]Provider

```dart
import 'package:flutter/foundation.dart';
import 'package:[package_name]/di/service_locator.dart';
import 'package:[package_name]/models/[entity]_collection.dart';
import 'package:[package_name]/models/filter_criteria.dart';
import 'package:[package_name]/services/[service]_service.dart';

/// Provider for managing [feature] state.
class [Feature]Provider extends ChangeNotifier {
  final [Service]Service _[service]Service = locator<[Service]Service>();

  [Entity]Collection _[entities] = const [Entity]Collection([entities]: []);
  FilterCriteria _filters = const FilterCriteria();
  bool _isLoading = false;
  String? _error;

  [Entity]Collection get [entities] => _[entities];
  FilterCriteria get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads [entities] from the service.
  Future<void> load[Entities]() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _[entities] = await _[service]Service.load[Entities]();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Applies filters to the [entity] collection.
  Future<void> applyFilters(FilterCriteria filters) async {
    _filters = filters;
    _isLoading = true;
    notifyListeners();

    try {
      _[entities] = await _[service]Service.filter[Entities](filters);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles selection for an [entity].
  void toggleSelection(String [entity]Id) {
    final updated[Entities] = _[entities].[entities].map((item) {
      if (item.id == [entity]Id) {
        return item.copyWith(isSelected: !item.isSelected);
      }
      return item;
    }).toList();

    _[entities] = [Entity]Collection([entities]: updated[Entities]);
    notifyListeners();
  }

  /// Selects all [entities].
  void selectAll() {
    final updated[Entities] = _[entities].[entities]
        .map((item) => item.copyWith(isSelected: true))
        .toList();

    _[entities] = [Entity]Collection([entities]: updated[Entities]);
    notifyListeners();
  }

  /// Clears all selections.
  void clearSelection() {
    final updated[Entities] = _[entities].[entities]
        .map((item) => item.copyWith(isSelected: false))
        .toList();

    _[entities] = [Entity]Collection([entities]: updated[Entities]);
    notifyListeners();
  }
}
```

---

## Testing Strategy

### Unit Tests

**Service Tests:**

```dart
// test/services/mock_[service]_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:[package_name]/implementations/services/mock_[service]_service.dart';

void main() {
  group('Mock[Service]Service', () {
    late Mock[Service]Service service;

    setUp(() {
      service = Mock[Service]Service();
    });

    test('load[Entities] returns [entity] collection', () async {
      final collection = await service.load[Entities]();

      expect(collection, isNotNull);
      expect(collection.[entities], isNotEmpty);
      expect(collection.count, greaterThan(0));
    });

    test('get[Entity]ById returns correct [entity]', () async {
      final collection = await service.load[Entities]();
      final first[Entity]Id = collection.[entities].first.id;

      final [entity] = await service.get[Entity]ById(first[Entity]Id);

      expect([entity].id, equals(first[Entity]Id));
    });

    test('get[Entity]ById throws for invalid ID', () async {
      expect(
        () => service.get[Entity]ById('invalid_id'),
        throwsException,
      );
    });

    test('filter[Entities] applies criteria correctly', () async {
      final criteria = FilterCriteria(category: 'Category A');
      final filtered = await service.filter[Entities](criteria);

      for (final [entity] in filtered.[entities]) {
        expect([entity].metadata['category'], equals('Category A'));
      }
    });

    test('search[Entities] finds matching results', () async {
      final results = await service.search[Entities]('Sample [Entity] 5');

      expect(results.[entities], isNotEmpty);
      expect(
        results.[entities].any((item) => item.id.contains('5')),
        isTrue,
      );
    });
  });
}
```

**Provider Tests:**

```dart
// test/providers/[feature]_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:[package_name]/di/service_locator.dart';
import 'package:[package_name]/providers/[feature]_provider.dart';

void main() {
  group('[Feature]Provider', () {
    late [Feature]Provider provider;

    setUp(() {
      setupServiceLocator(useMocks: true);
      provider = [Feature]Provider();
    });

    tearDown(() async {
      await resetServiceLocator();
    });

    test('initial state is empty', () {
      expect(provider.[entities].count, equals(0));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('load[Entities] updates state', () async {
      await provider.load[Entities]();

      expect(provider.[entities].count, greaterThan(0));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('toggleSelection updates [entity] selection', () async {
      await provider.load[Entities]();
      final first[Entity]Id = provider.[entities].[entities].first.id;

      provider.toggleSelection(first[Entity]Id);

      final selected[Entity] = provider.[entities].[entities]
          .firstWhere((item) => item.id == first[Entity]Id);
      expect(selected[Entity].isSelected, isTrue);
    });

    test('selectAll selects all [entities]', () async {
      await provider.load[Entities]();

      provider.selectAll();

      expect(
        provider.[entities].[entities].every((item) => item.isSelected),
        isTrue,
      );
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/[widget]_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:[package_name]/models/[entity]_metadata_impl.dart';
import 'package:[package_name]/widgets/[widget].dart';

void main() {
  group('[Widget]', () {
    final mock[Entity] = [Entity]MetadataImpl(
      id: 'test_1',
      timestamp: DateTime.now(),
      metadata: {'label': 'Test [Entity]'},
    );

    testWidgets('displays [entity]', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: [Widget]([entity]: mock[Entity]),
          ),
        ),
      );

      expect(find.text('Test [Entity]'), findsOneWidget);
    });

    testWidgets('shows selection indicator when selected', (tester) async {
      final selected[Entity] = mock[Entity].copyWith(isSelected: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: [Widget]([entity]: selected[Entity]),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
```

### Integration Tests

```dart
// integration_test/[feature]_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:[package_name]/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('[Feature] Flow', () {
    testWidgets('loads and displays [entities]', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify main screen loads
      expect(find.text('[Screen Title]'), findsOneWidget);

      // Verify [entities] are displayed
      expect(find.byType([Widget]), findsWidgets);
    });

    testWidgets('can select and deselect [entities]', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap first [entity] to select
      await tester.tap(find.byType([Widget]).first);
      await tester.pumpAndSettle();

      // Verify selection indicator appears
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.byType([Widget]).first);
      await tester.pumpAndSettle();

      // Verify selection indicator disappears
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });
}
```

---

## Dependencies (pubspec.yaml)

```yaml
name: [package_name]
description: "[Your app description]"
publish_to: 'none'
version: [VERSION]

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.1.1

  # Service locator for dependency injection
  get_it: ^7.6.4

  # Utilities
  uuid: ^4.2.1
  intl: ^0.19.0

  # Add domain-specific packages here
  # Examples:
  # cached_network_image: ^3.3.0  # For image handling
  # http: ^1.1.0                  # For API calls
  # shared_preferences: ^2.2.0    # For local storage

  # UI components
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Linting and testing
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.6

flutter:
  uses-material-design: true
  # Add assets as needed:
  # assets:
  #   - assets/images/
  #   - assets/icons/
```

---

## Implementation Checklist

### Phase 1: Foundation

- [ ] Set up Flutter project structure
- [ ] Configure pubspec.yaml with dependencies
- [ ] Create directory structure (models, services, implementations, etc.)
- [ ] Set up GetIt service locator
- [ ] Create abstract model interfaces
- [ ] Create abstract service interfaces

### Phase 2: Mock Implementations

- [ ] Implement Mock[Service]Service with sample data
- [ ] Implement MockApiService
- [ ] Implement MockStorageService
- [ ] Create concrete model implementations
- [ ] Write unit tests for mock services

### Phase 3: State Management

- [ ] Create [Feature]Provider
- [ ] Create FilterProvider (if needed)
- [ ] Create ThemeProvider
- [ ] Write provider unit tests

### Phase 4: UI Components

- [ ] Create core widgets for [entities]
- [ ] Create layout/container widgets
- [ ] Create filter/search widgets (if needed)
- [ ] Create detail view widgets
- [ ] Write widget tests

### Phase 5: Screens

- [ ] Create main screen
- [ ] Create detail/secondary screens
- [ ] Implement navigation
- [ ] Write screen tests

### Phase 6: Integration

- [ ] Wire up providers to UI
- [ ] Implement theme switching
- [ ] Add loading states and error handling
- [ ] Write integration tests

### Phase 7: Polish

- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Cross-platform testing (web/mobile)
- [ ] Documentation

### Phase 8: Deployment Prep (Optional)

- [ ] Create deployment configuration (Docker, etc.)
- [ ] Set up CI/CD
- [ ] Write deployment documentation
- [ ] Prepare for production release

---

## Best Practices

### 1. Service Abstraction
- Always define abstract interfaces for services
- Keep interfaces focused and cohesive
- Mock implementations should behave realistically
- Use dependency injection for all service access

### 2. Testing
- Write tests alongside implementation (TDD approach)
- Aim for >80% code coverage
- Test edge cases and error conditions
- Use meaningful test descriptions

### 3. State Management
- Keep providers focused on single responsibilities
- Use `notifyListeners()` judiciously
- Implement proper error handling in providers
- Reset service locator between tests

### 4. Code Organization
- Follow consistent naming conventions
- Group related functionality
- Keep files small and focused
- Document public APIs with dartdoc comments

### 5. Performance
- Use `const` constructors where possible
- Implement lazy loading for images
- Cache network requests appropriately
- Profile before optimizing

---

## Future Enhancements (Post v[VERSION])

### Real Backend Integration

- Implement Real[Service]Service
- Implement RealApiService
- Add authentication flow
- Integrate with backend REST API
- Handle file/data references from backend

### Advanced Features

- Advanced filtering and search options
- Batch operations
- Export capabilities
- Comparison/analytics views
- Advanced data processing features
- User customization and preferences

### Performance Improvements

- Virtual scrolling for large datasets
- Progressive data loading
- Caching strategies
- Offline support
- PWA capabilities (for web)

---

## Revision History

| Version   | Date       | Author          | Changes                         |
|-----------|------------|-----------------|---------------------------------|
| [VERSION] | [DATE]     | [AUTHOR]        | Initial technical specification |
