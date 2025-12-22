# PS12 Image Overview - Flutter Application

A Flutter application that replicates an image grid overview UI with filtering capabilities.

## Features

- **Image Grid Display**: 4x3 grid layout showing images with row numbers and column IDs
- **Filter Controls**:
  - Cycle filter dropdown
  - Exposure Time filter dropdown
- **Clean Architecture**: Follows the technical specification with service abstraction, dependency injection, and state management
- **Mock Data**: Uses mock service with placeholder images for development

## Architecture

This project follows clean architecture principles:

- **Models**: Abstract interfaces and concrete implementations
- **Services**: Abstract service interfaces for data operations
- **Implementations**: Mock service implementations (ready for real backend integration)
- **Providers**: State management using Provider pattern
- **Screens**: UI screens
- **Widgets**: Reusable UI components
- **DI**: Dependency injection using GetIt

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.1)
- Dart SDK

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

### For Web:
```bash
flutter run -d chrome
```

### For Desktop (Windows):
```bash
flutter run -d windows
```

## Project Structure

```
lib/
├── di/
│   └── service_locator.dart          # Dependency injection setup
├── models/
│   ├── image_metadata.dart           # Abstract image metadata interface
│   ├── image_metadata_impl.dart      # Concrete implementation
│   ├── image_collection.dart         # Collection model
│   └── filter_criteria.dart          # Filter criteria model
├── services/
│   └── image_service.dart            # Abstract service interface
├── implementations/
│   └── services/
│       └── mock_image_service.dart   # Mock service implementation
├── providers/
│   └── image_overview_provider.dart  # State management
├── screens/
│   └── image_overview_screen.dart    # Main screen
├── widgets/
│   └── image_grid_cell.dart          # Grid cell widget
└── main.dart                          # Application entry point
```

## Key Dependencies

- `provider: ^6.1.1` - State management
- `get_it: ^7.6.4` - Service locator for dependency injection

## Future Enhancements

- Real backend integration
- Image loading from actual files/URLs
- Advanced filtering options
- Image selection and export
- Zoom and detail views

## Technical Specification

See [FLUTTER_TECHNICAL_SPECIFICATION.md](FLUTTER_TECHNICAL_SPECIFICATION.md) for detailed architecture and implementation guidelines.