import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum DialogType { error, info, destruction }

sealed class DialogMessage {
  DialogMessage({required this.type, this.handler}) : id = const Uuid().v4();

  final DialogType type;
  final VoidCallback? handler;
  final String id;
}

class TaskLoadErrorMessage extends DialogMessage {
  TaskLoadErrorMessage({required super.handler})
    : super(type: DialogType.error);
}

class TaskSaveErrorMessage extends DialogMessage {
  TaskSaveErrorMessage({required super.handler})
    : super(type: DialogType.error);
}

class TaskUpdateErrorMessage extends DialogMessage {
  TaskUpdateErrorMessage({required super.handler})
    : super(type: DialogType.error);
}

class TaskDeleteErrorMessage extends DialogMessage {
  TaskDeleteErrorMessage({super.handler}) : super(type: DialogType.error);
}

class TaskExecutionDeleteErrorMessage extends DialogMessage {
  TaskExecutionDeleteErrorMessage({super.handler})
    : super(type: DialogType.error);
}

class TaskInvalidArgumentErrorMessage extends DialogMessage {
  TaskInvalidArgumentErrorMessage() : super(type: DialogType.error);
}

class OnboardingSaveErrorMessage extends DialogMessage {
  OnboardingSaveErrorMessage() : super(type: DialogType.error);
}

class DeleteTaskConfirmMessage extends DialogMessage {
  DeleteTaskConfirmMessage(this.taskName, {required super.handler})
    : super(type: DialogType.destruction);

  final String taskName;
}

class UnknownErrorMessage extends DialogMessage {
  UnknownErrorMessage() : super(type: DialogType.error);
}
