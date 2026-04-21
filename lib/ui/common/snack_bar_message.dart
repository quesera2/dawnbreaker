import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

sealed class SnackBarMessage {
  SnackBarMessage({this.handler}) : id = const Uuid().v4();
  final String id;
  final VoidCallback? handler;
}

class TaskCompleteSuccessSnackMessage extends SnackBarMessage {
  TaskCompleteSuccessSnackMessage({required this.taskName, super.handler});
  final String taskName;
}
