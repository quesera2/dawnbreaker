import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

sealed class ErrorMessage {
  ErrorMessage({this.handler}) : id = const Uuid().v4();

  final VoidCallback? handler;
  final String id;
}

class TaskNotFoundErrorMessage extends ErrorMessage {
  TaskNotFoundErrorMessage() : super();
}

class TaskLoadErrorMessage extends ErrorMessage {
  TaskLoadErrorMessage({super.handler});
}

class TaskSaveErrorMessage extends ErrorMessage {
  TaskSaveErrorMessage({super.handler});
}

class TaskUpdateErrorMessage extends ErrorMessage {
  TaskUpdateErrorMessage({super.handler});
}

class TaskDeleteErrorMessage extends ErrorMessage {
  TaskDeleteErrorMessage({super.handler});
}

class TaskInvalidArgumentErrorMessage extends ErrorMessage {
  TaskInvalidArgumentErrorMessage() : super();
}

class OnboardingSaveErrorMessage extends ErrorMessage {
  OnboardingSaveErrorMessage() : super();
}

class UnknownErrorMessage extends ErrorMessage {
  UnknownErrorMessage() : super();
}
