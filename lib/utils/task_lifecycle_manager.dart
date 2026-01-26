import 'dart:async';
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_client/sci_client.dart' show DoneState, CanceledState;

/// Manages Tercen task lifecycle - marking task as done and handling cancellation.
///
/// This class handles the operator lifecycle by:
/// 1. Marking the task as "Done" when image loading completes
/// 2. Polling for cancellation signals from Tercen UI
/// 3. Cleaning up resources when cancelled
///
/// The app does NOT automatically close - users close it manually.
class TaskLifecycleManager {
  final String _taskId;
  final ServiceFactory _serviceFactory;
  Timer? _cancellationPollTimer;
  bool _isCompleted = false;
  bool _isCancelled = false;

  /// Callbacks for lifecycle events
  final void Function()? onCancelled;

  TaskLifecycleManager({
    required String taskId,
    required ServiceFactory serviceFactory,
    this.onCancelled,
  })  : _taskId = taskId,
        _serviceFactory = serviceFactory;

  /// Marks the task as completed (DoneState).
  ///
  /// Call this when the app has finished initial loading and is ready for user interaction.
  Future<void> markTaskComplete() async {
    if (_isCompleted) {
      print('⚠️ Task already marked as complete');
      return;
    }

    try {
      print('📝 Marking task as complete...');

      // Fetch current task
      final task = await _serviceFactory.taskService.get(_taskId);

      // Update state to DoneState
      task.state = DoneState();

      // Save updated task
      await _serviceFactory.taskService.update(task);

      _isCompleted = true;
      print('✅ Task marked as complete (DoneState)');

      // Start polling for cancellation signals
      _startCancellationPolling();
    } catch (e, stackTrace) {
      print('❌ Error marking task as complete: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Starts polling the task state to detect cancellation from Tercen UI.
  void _startCancellationPolling() {
    // Poll every 2 seconds to check if task was cancelled externally
    _cancellationPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final task = await _serviceFactory.taskService.get(_taskId);

        // Check if task state changed to CanceledState
        if (task.state is CanceledState && !_isCancelled) {
          print('🛑 Task cancellation detected from Tercen UI');
          _handleCancellation();
        }
      } catch (e) {
        // Silently ignore polling errors to avoid cluttering console
        // The task might have been deleted or become inaccessible
      }
    });
  }

  /// Handles cancellation signal from Tercen.
  void _handleCancellation() {
    if (_isCancelled) return;

    _isCancelled = true;
    print('🧹 Cleaning up resources after cancellation...');

    // Stop polling
    _cancellationPollTimer?.cancel();
    _cancellationPollTimer = null;

    // Notify listener (e.g., to clean up image cache)
    onCancelled?.call();

    print('✓ Resource cleanup complete');
    print('ℹ️ User can now close the app window manually');
  }

  /// Manually marks the task as cancelled (for graceful shutdown).
  Future<void> cancel() async {
    if (_isCancelled) return;

    try {
      print('🛑 Cancelling task...');

      // Fetch current task
      final task = await _serviceFactory.taskService.get(_taskId);

      // Update state to CanceledState if not already cancelled
      if (task.state is! CanceledState) {
        task.state = CanceledState();
        await _serviceFactory.taskService.update(task);
        print('✓ Task state updated to CanceledState');
      }

      _handleCancellation();
    } catch (e, stackTrace) {
      print('❌ Error cancelling task: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Cleans up resources and stops polling.
  void dispose() {
    _cancellationPollTimer?.cancel();
    _cancellationPollTimer = null;
  }
}
