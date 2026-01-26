import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' hide ServiceFactory;

/// Container for resolved document IDs (both documentId and id columns).
class ResolvedIds {
  final String? documentId;
  final String? id;

  ResolvedIds({this.documentId, this.id});

  bool get hasAnyId => documentId != null || id != null;

  @override
  String toString() => 'ResolvedIds(documentId: $documentId, id: $id)';
}

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
  /// Returns both documentId and id column values if found, or null to trigger mock data fallback.
  Future<ResolvedIds?> resolveDocumentId() async {
    print('🔍 DocumentIdResolver: Starting resolution process');
    print('   Available: taskId=${_taskId != null}, workflowId=${_workflowId != null}, stepId=${_stepId != null}');

    // Strategy 1: Extract from column data via taskId (PRIMARY - PRODUCTION)
    final idsFromColumns = await _tryGetFromColumnData();
    if (idsFromColumns != null && idsFromColumns.hasAnyId) {
      print('✓ DocumentIdResolver: Found IDs from column data: $idsFromColumns');
      return idsFromColumns;
    }

    // Strategy 2: Search files by workflow/step (AUTO-DISCOVERY FALLBACK)
    final docIdFromFiles = await _tryFindFilesByWorkflowStep();
    if (docIdFromFiles != null) {
      print('✓ DocumentIdResolver: Found documentId by searching files: $docIdFromFiles');
      return ResolvedIds(documentId: docIdFromFiles);
    }

    // Strategy 3: Use development hardcoded ID (DEVELOPMENT)
    if (_devZipFileId != null && _devZipFileId!.isNotEmpty) {
      print('✓ DocumentIdResolver: Using development zip file ID: $_devZipFileId');
      return ResolvedIds(documentId: _devZipFileId);
    }

    // Strategy 4: Return null for mock fallback
    print('⚠️ DocumentIdResolver: No document ID found, will use mock data');
    return null;
  }

  /// Strategy 1: Extract documentId and id from column data via Task's CubeQuery.
  ///
  /// This is the primary production approach. The documentId is provided as a
  /// column factor in the Tercen data step (like Shiny operators).
  /// Returns both documentId and id column values for fallback handling.
  Future<ResolvedIds?> _tryGetFromColumnData() async {
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

      // Handle both RunWebAppTask and CubeQueryTask
      CubeQueryTask? cubeTask;

      if (task is RunWebAppTask) {
        print('   ✓ Task is RunWebAppTask, extracting cubeQueryTaskId');
        final cubeQueryTaskId = task.cubeQueryTaskId;
        if (cubeQueryTaskId.isEmpty) {
          print('   ⊘ RunWebAppTask has empty cubeQueryTaskId');
          return null;
        }

        print('   🔍 Fetching CubeQueryTask: $cubeQueryTaskId');
        final cubeTaskObj = await _serviceFactory.taskService.get(cubeQueryTaskId);

        if (cubeTaskObj is! CubeQueryTask) {
          print('   ⊘ Referenced task is not a CubeQueryTask: ${cubeTaskObj.runtimeType}');
          return null;
        }

        cubeTask = cubeTaskObj as CubeQueryTask;
        print('   ✓ Successfully retrieved CubeQueryTask');
      } else if (task is CubeQueryTask) {
        print('   ✓ Task is already a CubeQueryTask');
        cubeTask = task as CubeQueryTask;
      } else {
        print('   ⊘ Task is neither RunWebAppTask nor CubeQueryTask: ${task.runtimeType}');
        return null;
      }

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

      // DEBUG: Print ALL column details
      print('   🔍 DETAILED COLUMN INSPECTION:');
      for (var i = 0; i < columnSchema.columns.length; i++) {
        final col = columnSchema.columns[i];
        print('      Column[$i]: name="${col.name}", type=${col.runtimeType}');
      }

      // Check for .documentId (fundamental), documentId (alias), and id columns
      // Prefer .documentId as it contains the real FileDocument ID
      final dotDocIdColumn = columnSchema.columns.where((col) => col.name == '.documentId').firstOrNull;
      final docIdColumn = columnSchema.columns.where((col) => col.name == 'documentId').firstOrNull;
      final idColumn = columnSchema.columns.where((col) => col.name == 'id').firstOrNull;

      if (dotDocIdColumn == null && docIdColumn == null) {
        print('   ⊘ No ".documentId" or "documentId" column found in schema');

        // Try 'id' column as fallback
        if (idColumn != null) {
          print('   ℹ️ Found "id" column, will try that instead');
          final columnData = await _serviceFactory.tableSchemaService
              .select(columnHash, ['id'], 0, 1);

          final docIdMatches = columnData.columns.where((c) => c.name == 'id');
          if (docIdMatches.isNotEmpty) {
            final docIdCol = docIdMatches.first;
            if (docIdCol.values != null && docIdCol.values.isNotEmpty) {
              final id = docIdCol.values.first?.toString();
              if (id != null && id.isNotEmpty) {
                print('   ✓ Successfully extracted ID from "id" column: $id');
                return ResolvedIds(id: id);
              }
            }
          }
        }

        return null;
      }

      if (dotDocIdColumn != null) {
        print('   ✓ Found ".documentId" column (fundamental)');
      }
      if (docIdColumn != null) {
        print('   ✓ Found "documentId" column (alias)');
      }

      // Select columns - prefer .documentId, then documentId, plus id if available
      print('   🔍 Fetching documentId data from table...');
      final columnsToFetch = <String>[];
      if (dotDocIdColumn != null) {
        columnsToFetch.add('.documentId');
      }
      if (docIdColumn != null) {
        columnsToFetch.add('documentId');
      }
      if (idColumn != null) {
        columnsToFetch.add('id');
        print('   ℹ️ Also fetching "id" column for comparison');
      }

      final columnData = await _serviceFactory.tableSchemaService
          .select(columnHash, columnsToFetch, 0, 1);

      print('   ✓ Received table data');
      print('   ✓ Table type: ${columnData.runtimeType}');
      print('   ✓ Table columns: ${columnData.columns.length}');
      print('   ✓ Table nRows: ${columnData.nRows}');

      // Try to extract the documentId value
      if (columnData.nRows == 0) {
        print('   ⊘ Table has no rows');
        return null;
      }

      // Log all column values we received
      for (final col in columnData.columns) {
        final firstValue = col.values != null && col.values.isNotEmpty ? col.values.first : null;
        print('   📋 Column "${col.name}": $firstValue');
      }

      // Extract documentId (prefer .documentId over documentId) and id column values
      String? documentIdValue;
      String? idValue;

      // Prefer .documentId (fundamental) over documentId (alias)
      final dotDocIdMatches = columnData.columns.where((c) => c.name == '.documentId');
      if (dotDocIdMatches.isNotEmpty) {
        final dotDocIdColData = dotDocIdMatches.first;
        if (dotDocIdColData.values != null && dotDocIdColData.values.isNotEmpty) {
          documentIdValue = dotDocIdColData.values.first?.toString();
          if (documentIdValue != null && documentIdValue.isNotEmpty) {
            print('   ✓ Successfully extracted .documentId (fundamental): $documentIdValue');
          }
        }
      }

      // Fall back to documentId (alias) if .documentId not found or empty
      if (documentIdValue == null || documentIdValue.isEmpty) {
        final docIdMatches = columnData.columns.where((c) => c.name == 'documentId');
        if (docIdMatches.isNotEmpty) {
          final docIdColData = docIdMatches.first;
          if (docIdColData.values != null && docIdColData.values.isNotEmpty) {
            documentIdValue = docIdColData.values.first?.toString();
            if (documentIdValue != null && documentIdValue.isNotEmpty) {
              print('   ✓ Successfully extracted documentId (alias): $documentIdValue');
            }
          }
        }
      }

      // Get id column value
      final idMatches = columnData.columns.where((c) => c.name == 'id');
      if (idMatches.isNotEmpty) {
        final idColData = idMatches.first;
        if (idColData.values != null && idColData.values.isNotEmpty) {
          idValue = idColData.values.first?.toString();
          if (idValue != null && idValue.isNotEmpty) {
            print('   ✓ Successfully extracted id: $idValue');
          }
        }
      }

      // Return both values (even if one is null)
      if (documentIdValue != null || idValue != null) {
        final resolvedIds = ResolvedIds(documentId: documentIdValue, id: idValue);
        print('   ✓ Returning resolved IDs: $resolvedIds');
        return resolvedIds;
      }

      print('   ⊘ Could not extract any ID values from table data');
      return null;
    } catch (e, stackTrace) {
      print('   ✗ Error extracting documentId from column data: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Public method to search for files by workflow/step (for external fallback calls).
  ///
  /// This can be called from services when primary resolution strategies fail.
  Future<String?> tryFindFilesByWorkflowStep() async {
    return _tryFindFilesByWorkflowStep();
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
        descending: false,
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
