import 'package:get_it/get_it.dart';
import 'package:ps12_image_overview/implementations/services/mock_image_service.dart';
import 'package:ps12_image_overview/implementations/services/tercen_image_service.dart';
import 'package:ps12_image_overview/services/image_service.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';

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
///     real implementations using Tercen API.
///   - [tercenFactory]: Required when useMocks is false. The initialized
///     Tercen ServiceFactory for API access.
///   - [documentId]: Optional document ID from URL path (/_w3op/{documentId})
///   - [taskId]: Optional task ID from Tercen URL query parameters
///   - [workflowId]: Optional workflow ID for Tercen context
///   - [stepId]: Optional step ID for Tercen context
///   - [devZipFileId]: Optional hardcoded zip file ID for development
///
/// Example:
/// ```dart
/// void main() async {
///   if (useMocks) {
///     setupServiceLocator(useMocks: true);
///   } else {
///     final factory = await createServiceFactoryForWebApp();
///     setupServiceLocator(useMocks: false, tercenFactory: factory);
///   }
///   runApp(MyApp());
/// }
/// ```
void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? tercenFactory,
  String? documentId,
  String? taskId,
  String? workflowId,
  String? stepId,
  String? devZipFileId,
}) {
  if (useMocks) {
    // Register mock services
    locator.registerSingleton<ImageService>(MockImageService());
  } else {
    if (tercenFactory == null) {
      throw StateError(
          'Tercen ServiceFactory is required when useMocks is false. '
          'Call createServiceFactoryForWebApp() first.');
    }

    // Register Tercen ServiceFactory for potential use by other services
    locator.registerSingleton<ServiceFactory>(tercenFactory);

    // Register real image service using Tercen API
    locator.registerSingleton<ImageService>(
      TercenImageService(
        tercenFactory,
        documentId: documentId,
        taskId: taskId,
        workflowId: workflowId,
        stepId: stepId,
        devZipFileId: devZipFileId,
      ),
    );
  }
}

/// Resets the service locator.
///
/// Useful for testing to ensure a clean state between tests.
Future<void> resetServiceLocator() async {
  await locator.reset();
}
