import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;

/// Resolves document IDs from Tercen context using multiple strategies.
///
/// This class implements a hierarchical fallback approach to find the
/// document ID (zip file) containing images:
///
/// 1. **Primary**: Use documentId from URL path (/_w3op/{documentId})
/// 2. **Fallback 1**: Extract from column data via CubeQuery
/// 3. **Fallback 2**: Search files by workflowId/stepId (auto-discovery)
/// 4. **Fallback 3**: Use hardcoded development zip file ID
/// 5. **Final**: Return null for mock data fallback
class DocumentIdResolver {
  final ServiceFactory _serviceFactory;
  final String? _documentId;  // From URL path
  final String? _taskId;
  final String? _workflowId;
  final String? _stepId;
  final String? _devZipFileId;

  DocumentIdResolver({
    required ServiceFactory serviceFactory,
    String? documentId,  // documentId from URL path
    String? taskId,
    String? workflowId,
    String? stepId,
    String? devZipFileId,
  })  : _serviceFactory = serviceFactory,
        _documentId = documentId,
        _taskId = taskId,
        _workflowId = workflowId,
        _stepId = stepId,
        _devZipFileId = devZipFileId;

  /// Resolves the document ID using hierarchical fallback strategy.
  ///
  /// Returns the document ID if found, or null to trigger mock data fallback.
  Future<String?> resolveDocumentId() async {
    print('🔍 DocumentIdResolver: Starting resolution process');

    // Strategy 1: Use documentId from URL path (PRIMARY - SIMPLEST)
    if (_documentId != null && _documentId!.isNotEmpty) {
      print('✓ DocumentIdResolver: Using documentId from URL path: $_documentId');
      return _documentId;
    }

    // Strategy 2: Extract from column data (PRODUCTION - like Shiny)
    final docIdFromColumns = await _tryGetFromColumnData();
    if (docIdFromColumns != null) {
      print('✓ DocumentIdResolver: Found documentId from column data: $docIdFromColumns');
      return docIdFromColumns;
    }

    // Strategy 3: Search files by workflow/step (AUTO-DISCOVERY)
    final docIdFromFiles = await _tryFindFilesByWorkflowStep();
    if (docIdFromFiles != null) {
      print('✓ DocumentIdResolver: Found documentId by searching files: $docIdFromFiles');
      return docIdFromFiles;
    }

    // Strategy 4: Use development hardcoded ID (DEVELOPMENT)
    if (_devZipFileId != null && _devZipFileId!.isNotEmpty) {
      print('✓ DocumentIdResolver: Using development zip file ID: $_devZipFileId');
      return _devZipFileId;
    }

    // Strategy 5: Return null for mock fallback
    print('⚠️ DocumentIdResolver: No document ID found, will use mock data');
    return null;
  }

  /// Strategy 2: Extract documentId from column data via Task's CubeQuery.
  ///
  /// This is used when documentId is provided as a column factor in the
  /// Tercen data step (like Shiny operators).
  ///
  /// NOTE: This implementation is simplified - extracting actual column data from
  /// Tercen's Table API requires understanding the internal data format. For now,
  /// we skip to auto-discovery which works reliably.
  Future<String?> _tryGetFromColumnData() async {
    try {
      if (_taskId == null || _taskId!.isEmpty) {
        print('   ⊘ No taskId available, skipping column data extraction');
        return null;
      }

      print('   🔍 Attempting to get documentId from column data (taskId: $_taskId)...');

      // Get the task object
      final task = await _serviceFactory.taskService.get(_taskId!);
      print('   ✓ Retrieved task: ${task.id}');

      // Check if task has a query (CubeQueryTask)
      if (task is! CubeQueryTask) {
        print('   ⊘ Task is not a CubeQueryTask, no column data available');
        return null;
      }

      final cubeTask = task as CubeQueryTask;
      final query = cubeTask.query;

      if (query == null) {
        print('   ⊘ Task has no query, cannot extract column data');
        return null;
      }

      // TODO: Implement full column data extraction when Table API is better understood
      // For now, return null to fall through to file search (which works well)
      print('   ⊘ Column data extraction not yet fully implemented, falling through to file search');
      return null;
    } catch (e, stackTrace) {
      print('   ✗ Error extracting documentId from column data: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Strategy 3: Search for files by workflowId and stepId.
  ///
  /// This auto-discovery approach finds zip files associated with the
  /// current workflow step, useful when documentId is not in URL or column data.
  Future<String?> _tryFindFilesByWorkflowStep() async {
    try {
      if (_workflowId == null || _workflowId!.isEmpty ||
          _stepId == null || _stepId!.isEmpty) {
        print('   ⊘ No workflowId/stepId available, skipping file search');
        return null;
      }

      print('   🔍 Searching for files by workflowId: $_workflowId, stepId: $_stepId...');

      final files = await _serviceFactory.fileService
          .findFileByWorkflowIdAndStepId(
        startKey: [_workflowId, _stepId],
        endKey: [_workflowId, _stepId, {}],
        limit: 10,
      );

      print('   ✓ Found ${files.length} files');

      if (files.isEmpty) {
        print('   ⊘ No files found for workflow/step');
        return null;
      }

      // Look for zip files first (preferred)
      final zipFiles = files.where((f) => f.name.toLowerCase().endsWith('.zip')).toList();
      if (zipFiles.isNotEmpty) {
        final zipFile = zipFiles.first;
        print('   ✓ Found zip file: ${zipFile.name} (${zipFile.id})');
        return zipFile.id;
      }

      // Fallback to first file if no zip found
      final firstFile = files.first;
      print('   ⚠️ No zip file found, using first file: ${firstFile.name} (${firstFile.id})');
      return firstFile.id;
    } catch (e, stackTrace) {
      print('   ✗ Error searching files by workflow/step: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }
}
