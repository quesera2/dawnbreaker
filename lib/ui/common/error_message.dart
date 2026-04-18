import 'package:flutter/foundation.dart';

sealed class ErrorMessage {
  const ErrorMessage({this.handler});

  final VoidCallback? handler;
}

class TaskNotFoundErrorMessage extends ErrorMessage {
  const TaskNotFoundErrorMessage() : super();
}

class TaskLoadErrorMessage extends ErrorMessage {
  const TaskLoadErrorMessage({super.handler});
}

class TaskSaveErrorMessage extends ErrorMessage {
  const TaskSaveErrorMessage({super.handler});
}

class TaskUpdateErrorMessage extends ErrorMessage {
  const TaskUpdateErrorMessage({super.handler});
}

class TaskDeleteErrorMessage extends ErrorMessage {
  const TaskDeleteErrorMessage({super.handler});
}

class TaskInvalidArgumentErrorMessage extends ErrorMessage {
  const TaskInvalidArgumentErrorMessage() : super();
}

class UnknownErrorMessage extends ErrorMessage {
  const UnknownErrorMessage() : super();
}
