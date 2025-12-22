import 'package:get_it/get_it.dart';
import 'package:ps12_image_overview/implementations/services/mock_image_service.dart';
import 'package:ps12_image_overview/services/image_service.dart';

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
    locator.registerSingleton<ImageService>(MockImageService());
  } else {
    // TODO: Register real services when implemented
    throw UnimplementedError('Real services not yet implemented');
  }
}

/// Resets the service locator.
///
/// Useful for testing to ensure a clean state between tests.
Future<void> resetServiceLocator() async {
  await locator.reset();
}
