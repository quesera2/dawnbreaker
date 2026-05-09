import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

sealed class SnackBarMessage {
  SnackBarMessage({this.handler}) : id = const Uuid().v4();
  final String id;
  final AsyncCallback? handler;
}

class TaskCompleteSuccess extends SnackBarMessage {
  TaskCompleteSuccess({required this.taskName, required super.handler});

  final String taskName;
}

class TaskCreateSuccess extends SnackBarMessage {
  TaskCreateSuccess({required this.taskName, required super.handler});

  final String taskName;
}

class TaskUpdateSuccess extends SnackBarMessage {
  TaskUpdateSuccess({required this.taskName, required super.handler});

  final String taskName;
}

class TaskDeleteSuccess extends SnackBarMessage {
  TaskDeleteSuccess({required this.taskName, required super.handler});

  final String taskName;
}

class TaskExecutionUpdateSuccess extends SnackBarMessage {
  TaskExecutionUpdateSuccess({required super.handler});
}

class TaskExecutionDeleteSuccess extends SnackBarMessage {
  TaskExecutionDeleteSuccess({
    required this.taskName,
    required this.executedAt,
    required super.handler,
  });

  final String taskName;
  final DateTime executedAt;
}

class DebugDummyTasksGeneratedMessage extends SnackBarMessage {
  DebugDummyTasksGeneratedMessage();
}

class AllTasksDeletedMessage extends SnackBarMessage {
  AllTasksDeletedMessage();
}
