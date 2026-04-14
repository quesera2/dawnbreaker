class TaskRepositoryException implements Exception {
  const TaskRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause != null ? '$message (cause: $cause)' : message;
}
