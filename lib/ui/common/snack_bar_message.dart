import 'package:uuid/uuid.dart';

sealed class SnackBarMessage {
  SnackBarMessage() : id = const Uuid().v4();
  final String id;
}

class TaskCompleteSuccessSnackMessage extends SnackBarMessage {
  TaskCompleteSuccessSnackMessage({required this.taskName});
  final String taskName;
}
