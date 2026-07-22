sealed class TaskRepositoryException implements Exception {
  const TaskRepositoryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class TaskNotFoundException extends TaskRepositoryException {
  const TaskNotFoundException({required this.taskId}) : super();
  final String taskId;
}

class TaskLoadException extends TaskRepositoryException {
  const TaskLoadException([super.message]);
}

class TaskSaveException extends TaskRepositoryException {
  const TaskSaveException([super.message]);
}

class TaskUpdateException extends TaskRepositoryException {
  const TaskUpdateException([super.message]);
}

class TaskDeleteException extends TaskRepositoryException {
  const TaskDeleteException([super.message]);
}

class TaskInvalidArgumentException extends TaskRepositoryException {
  const TaskInvalidArgumentException([super.message]);
}

class TaskNotSignedInException extends TaskRepositoryException {
  const TaskNotSignedInException([super.message]);
}
