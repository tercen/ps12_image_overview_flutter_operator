import 'dart:io';
import 'dart:convert';

import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:sci_http_client/http_io_client.dart' as io_http;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

/// Simple tool to fetch and print a Tercen task as JSON
///
/// Usage:
///   dart run tools/print_task_json.dart <serviceUrl> <token> <taskId>
///
/// Example:
///   dart run tools/print_task_json.dart "https://stage.tercen.com" "eyJ..." "848a5d..."
void main(List<String> args) async {
  if (args.length != 3) {
    print('Usage: dart run tools/print_task_json.dart <serviceUrl> <token> <taskId>');
    print('');
    print('Example:');
    print('  dart run tools/print_task_json.dart "https://stage.tercen.com" "eyJ..." "848a5d..."');
    exit(1);
  }

  final serviceUrl = args[0];
  final token = args[1];
  final taskId = args[2];

  print('Fetching task from Tercen...');
  print('  Service URL: $serviceUrl');
  print('  Task ID: $taskId');
  print('');

  try {
    // Initialize ServiceFactory with auth token (following connect.dart pattern)
    var factory = ServiceFactory();
    var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
    await factory.initializeWith(Uri.parse(serviceUrl), authClient);
    tercen.ServiceFactory.CURRENT = factory;

    // Fetch the task
    print('Calling taskService.get($taskId)...');
    final task = await tercen.ServiceFactory().taskService.get(taskId);

    // Convert to JSON and pretty print
    final encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(task.toJson());

    print('');
    print('Task JSON:');
    print('═' * 80);
    print(prettyJson);
    print('═' * 80);

    // Print some key fields
    print('');
    print('Key Fields:');
    print('  Task ID: ${task.id}');
    print('  Task Kind: ${task.kind}');
    print('  Task Type: ${task.runtimeType}');

    if (task is RunWebAppTask) {
      print('  → This is a RunWebAppTask');
      print('  → cubeQueryTaskId: ${task.cubeQueryTaskId}');
      print('  → operatorId: ${task.operatorId}');
    } else if (task is CubeQueryTask) {
      print('  → This is a CubeQueryTask');
      print('  → Has query: ${task.query != null}');
      if (task.query != null) {
        print('  → query.columnHash: ${task.query!.columnHash}');
      }
    }

    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    exit(1);
  }
}
