import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;

/// Resolves document IDs from Tercen context using multiple strategies.
///
/// This class implements a hierarchical fallback approach to find the
/// document ID (zip file) containing images:
///
/// 1. **Primary**: Extract from column data via Task's CubeQuery (PRODUCTION)
/// 2. **Fallback 1**: Search files by workflowId/stepId (auto-discovery)
/// 3. **Fallback 2**: Use hardcoded development zip file ID
/// 4. **Final**: Return null for mock data fallback
class DocumentIdResolver {
  final ServiceFactory _serviceFactory;
  final String? _taskId;
  final String? _workflowId;
  final String? _stepId;
  final String? _devZipFileId;

  DocumentIdResolver({
    required ServiceFactory serviceFactory,
    String? taskId,
    String? workflowId,
    String? stepId,
    String? devZipFileId,
  })  : _serviceFactory = serviceFactory,
        _taskId = taskId,
        _workflowId = workflowId,
        _stepId = stepId,
        _devZipFileId = devZipFileId;

  /// Resolves the document ID using hierarchical fallback strategy.
  ///
  /// Returns the document ID if found, or null to trigger mock data fallback.
  Future<String?> resolveDocumentId() async {
    print('🔍 DocumentIdResolver: Starting resolution process');
    print('   Available: taskId=${_taskId != null}, workflowId=${_workflowId != null}, stepId=${_stepId != null}');

    // Strategy 1: Extract from column data via taskId (PRIMARY - PRODUCTION)
    final docIdFromColumns = await _tryGetFromColumnData();
    if (docIdFromColumns != null) {
      print('✓ DocumentIdResolver: Found documentId from column data: $docIdFromColumns');
      return docIdFromColumns;
    }

    // Strategy 2: Search files by workflow/step (AUTO-DISCOVERY FALLBACK)
    final docIdFromFiles = await _tryFindFilesByWorkflowStep();
    if (docIdFromFiles != null) {
      print('✓ DocumentIdResolver: Found documentId by searching files: $docIdFromFiles');
      return docIdFromFiles;
    }

    // Strategy 3: Use development hardcoded ID (DEVELOPMENT)
    if (_devZipFileId != null && _devZipFileId!.isNotEmpty) {
      print('✓ DocumentIdResolver: Using development zip file ID: $_devZipFileId');
      return _devZipFileId;
    }

    // Strategy 4: Return null for mock fallback
    print('⚠️ DocumentIdResolver: No document ID found, will use mock data');
    return null;
  }

  /// Strategy 1: Extract documentId from column data via Task's CubeQuery.
  ///
  /// This is the primary production approach. The documentId is provided as a
  /// column factor in the Tercen data step (like Shiny operators).
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
      print('   ✓ Task type: ${task.runtimeType}');

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

      print('   ✓ Task has CubeQuery');

      // Get column schema from the query
      final columnHash = query.columnHash;
      if (columnHash == null || columnHash.isEmpty) {
        print('   ⊘ Query has no columnHash');
        return null;
      }

      print('   ✓ Column hash: $columnHash');

      // Get the column schema
      final columnSchema = await _serviceFactory.tableSchemaService.get(columnHash);
      print('   ✓ Retrieved column schema with ${columnSchema.nRows} rows');
      print('   ✓ Column names: ${columnSchema.columns.map((c) => c.name).join(", ")}');

      // Check if documentId column exists
      final docIdColumn = columnSchema.columns.where((col) => col.name == 'documentId').firstOrNull;
      if (docIdColumn == null) {
        print('   ⊘ No "documentId" column found in schema');
        return null;
      }

      print('   ✓ Found "documentId" column');

      // Select the documentId column data - get first row only
      print('   🔍 Fetching documentId data from table...');
      final columnData = await _serviceFactory.tableSchemaService
          .select(columnHash, ['documentId'], 0, 1);

      print('   ✓ Received table data');
      print('   ✓ Table type: ${columnData.runtimeType}');
      print('   ✓ Table columns: ${columnData.columns.length}');
      print('   ✓ Table nRows: ${columnData.nRows}');

      // Try to extract the documentId value
      // The Table object structure needs investigation - log what we find
      if (columnData.nRows == 0) {
        print('   ⊘ Table has no rows');
        return null;
      }

      // Attempt to access the data through the columns
      final docIdCol = columnData.columns.firstOrNull;
      if (docIdCol != null) {
        print('   ✓ First column name: ${docIdCol.name}');
        print('   ✓ First column type: ${docIdCol.type}');

        // Try to access column values if available
        if (docIdCol.values != null && docIdCol.values.isNotEmpty) {
          final documentId = docIdCol.values.first?.toString();
          if (documentId != null && documentId.isNotEmpty) {
            print('   ✓ Successfully extracted documentId: $documentId');
            return documentId;
          }
        } else {
          print('   ⚠️ Column values property is null or empty');
          print('   ℹ️ Column object: ${docIdCol.toJson()}');
        }
      }

      print('   ⊘ Could not extract documentId value from table data');
      return null;
    } catch (e, stackTrace) {
      print('   ✗ Error extracting documentId from column data: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Strategy 2: Search for files by workflowId and stepId.
  ///
  /// This auto-discovery approach finds zip files associated with the
  /// current workflow step, useful as fallback when column data extraction fails.
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
