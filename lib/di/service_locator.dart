import 'package:get_it/get_it.dart';
import 'package:ps12_image_overview/implementations/services/tercen_image_service.dart';
import 'package:ps12_image_overview/services/image_service.dart';
import 'package:ps12_image_overview/utils/task_lifecycle_manager.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';

final GetIt getIt = GetIt.instance;
final GetIt locator = getIt;

void setupServiceLocator({
  required ServiceFactory tercenFactory,
  String? taskId,
  String? workflowId,
  String? stepId,
  String? devZipFileId,
}) {
  locator.registerSingleton<ServiceFactory>(tercenFactory);

  final imageService = TercenImageService(
    tercenFactory,
    taskId: taskId,
    workflowId: workflowId,
    stepId: stepId,
    devZipFileId: devZipFileId,
  );
  locator.registerSingleton<ImageService>(imageService);

  if (taskId != null && taskId.isNotEmpty) {
    final lifecycleManager = TaskLifecycleManager(
      taskId: taskId,
      serviceFactory: tercenFactory,
      onCancelled: () {
        print('🧹 Clearing image cache due to cancellation...');
        imageService.clearCache();
      },
    );
    locator.registerSingleton<TaskLifecycleManager>(lifecycleManager);
    print('✓ TaskLifecycleManager registered for taskId: $taskId');
  }
}

Future<void> resetServiceLocator() async {
  await locator.reset();
}
