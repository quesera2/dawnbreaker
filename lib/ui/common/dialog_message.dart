import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum DialogType { error, info, destruction }

sealed class DialogMessage {
  DialogMessage({
    required this.type,
    this.primaryHandler,
    this.secondaryHandler,
  }) : id = const Uuid().v4();

  final DialogType type;
  final VoidCallback? primaryHandler;
  final VoidCallback? secondaryHandler;
  final String id;
}

class TaskLoadErrorMessage extends DialogMessage {
  TaskLoadErrorMessage({required super.primaryHandler})
    : super(type: DialogType.error);
}

class TaskSaveErrorMessage extends DialogMessage {
  TaskSaveErrorMessage({required super.primaryHandler})
    : super(type: DialogType.error);
}

class TaskUpdateErrorMessage extends DialogMessage {
  TaskUpdateErrorMessage({required super.primaryHandler})
    : super(type: DialogType.error);
}

class TaskDeleteErrorMessage extends DialogMessage {
  TaskDeleteErrorMessage({super.primaryHandler})
    : super(type: DialogType.error);
}

class TaskExecutionDeleteErrorMessage extends DialogMessage {
  TaskExecutionDeleteErrorMessage({super.primaryHandler})
    : super(type: DialogType.error);
}

class TaskInvalidArgumentErrorMessage extends DialogMessage {
  TaskInvalidArgumentErrorMessage() : super(type: DialogType.error);
}

class OnboardingSaveErrorMessage extends DialogMessage {
  OnboardingSaveErrorMessage() : super(type: DialogType.error);
}

class DeleteTaskConfirmMessage extends DialogMessage {
  DeleteTaskConfirmMessage(this.taskName, {required super.primaryHandler})
    : super(type: DialogType.destruction);

  final String taskName;
}

class NotificationPermissionDeniedMessage extends DialogMessage {
  NotificationPermissionDeniedMessage({required super.primaryHandler})
    : super(type: DialogType.info);
}

class ExactAlarmPermissionRequestMessage extends DialogMessage {
  ExactAlarmPermissionRequestMessage({
    required super.primaryHandler,
    super.secondaryHandler,
  }) : super(type: DialogType.info);
}

class UnknownErrorMessage extends DialogMessage {
  UnknownErrorMessage() : super(type: DialogType.error);
}
