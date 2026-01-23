import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ps12_image_overview/di/service_locator.dart';
import 'package:ps12_image_overview/providers/image_overview_provider.dart';
import 'package:ps12_image_overview/providers/theme_provider.dart';
import 'package:ps12_image_overview/screens/image_overview_screen.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if we should use mock services or real Tercen API
  // Default to false (real data) when deployed to Tercen
  // Override with --dart-define=USE_MOCKS=true for local development with mocks
  const useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: false, // Default to real Tercen API (production mode)
  );

  if (useMocks) {
    // Use mock services for development/testing
    setupServiceLocator(useMocks: true);
  } else {
    // Initialize Tercen ServiceFactory with token and URI from environment
    final tercenFactory = await createServiceFactoryForWebApp();

    // Parse URL to extract Tercen parameters
    final uri = Uri.base;
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    print('🔍 URL Analysis:');
    print('   Full URL: $uri');
    print('   Path segments: $pathSegments');
    print('   Query parameters: ${queryParams.keys.join(", ")}');

    // Extract parameters from query string (primary source for operators)
    String? taskId = queryParams['taskId'];
    String? workflowId = queryParams['workflowId'];
    String? stepId = queryParams['stepId'];
    String? documentId;

    print('📥 Query parameters:');
    print('   taskId: $taskId');
    print('   workflowId: $workflowId');
    print('   stepId: $stepId');

    // Extract documentId from URL path: /_w3op/{documentId}
    if (pathSegments.contains('_w3op') && pathSegments.length > 1) {
      final index = pathSegments.indexOf('_w3op');
      if (index + 1 < pathSegments.length) {
        documentId = pathSegments[index + 1];
        print('✓ Found documentId in URL path: $documentId');
      }
    }

    // Also check path segments for workflow mode (legacy support)
    if (pathSegments.contains('w') && pathSegments.contains('ds')) {
      final wIndex = pathSegments.indexOf('w');
      final dsIndex = pathSegments.indexOf('ds');
      if (wIndex + 1 < pathSegments.length && dsIndex + 1 < pathSegments.length) {
        workflowId ??= pathSegments[wIndex + 1];
        stepId ??= pathSegments[dsIndex + 1];
        print('📋 Also found in path: workflowId=$workflowId, stepId=$stepId');
      }
    }

    // Fallback to environment variables for local development
    workflowId ??= const String.fromEnvironment('WORKFLOW_ID');
    stepId ??= const String.fromEnvironment('STEP_ID');
    documentId ??= const String.fromEnvironment('DEV_ZIP_FILE_ID');

    print('📋 Final configuration:');
    print('   taskId: $taskId');
    print('   workflowId: $workflowId');
    print('   stepId: $stepId');
    print('   documentId (dev): $documentId');

    // Set up service locator with real Tercen services
    setupServiceLocator(
      useMocks: false,
      tercenFactory: tercenFactory,
      documentId: documentId?.isEmpty ?? true ? null : documentId,
      taskId: taskId,
      workflowId: workflowId?.isEmpty ?? true ? null : workflowId,
      stepId: stepId?.isEmpty ?? true ? null : stepId,
      devZipFileId: const String.fromEnvironment('DEV_ZIP_FILE_ID'),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageOverviewProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Image Overview',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[100],
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[900],
            ),
            home: const ImageOverviewScreen(),
          );
        },
      ),
    );
  }
}
