import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum DialogType { error, info, destruction }

sealed class DialogMessage {
  DialogMessage({
    required this.type,
    this.primaryHandler,
    this.secondaryHandler,
    this.dismissible = true,
  }) : id = const Uuid().v4();

  final DialogType type;
  final VoidCallback? primaryHandler;
  final VoidCallback? secondaryHandler;

  /// 枠外タップで閉じられるか。閉じるとハンドラが走らないため、
  /// どちらかを必ず選ばせたいものは `false` にする
  final bool dismissible;
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

class SignInErrorMessage extends DialogMessage {
  SignInErrorMessage({required super.primaryHandler})
    : super(type: DialogType.error);
}

/// 昇格しようとしたアカウントが既に使われていたとき、ゲストのタスクを
/// 捨ててよいか確かめる
class SwitchAccountConfirmMessage extends DialogMessage {
  SwitchAccountConfirmMessage({required super.primaryHandler})
    : super(type: DialogType.destruction);
}

/// アカウントとタスクがすべて消えることを、消す前に確かめる
class DeleteAccountConfirmMessage extends DialogMessage {
  DeleteAccountConfirmMessage({required super.primaryHandler})
    : super(type: DialogType.destruction);
}

/// 削除に失敗したときのエラー。消えたかどうかを曖昧にしないよう、
/// 枠外タップでは閉じさせず、再試行かキャンセルを選ばせる
class DeleteAccountErrorMessage extends DialogMessage {
  DeleteAccountErrorMessage({required super.primaryHandler})
    : super(type: DialogType.error, dismissible: false);
}

class NotificationEnableErrorMessage extends DialogMessage {
  NotificationEnableErrorMessage() : super(type: DialogType.error);
}

class NotificationPermissionDeniedMessage extends DialogMessage {
  NotificationPermissionDeniedMessage({required super.primaryHandler})
    : super(type: DialogType.info);
}

/// サインインが切れていたときのエラー。他端末でアカウントを消されると
/// トークンの更新が失敗して SDK がローカルでサインアウトするため、
/// タスクの読み書きが `TaskNotSignedInException` になる形で表に出る。
/// 了承したらログイン画面へ送り出すので、枠外タップでは閉じさせない
class SessionExpiredMessage extends DialogMessage {
  SessionExpiredMessage({required super.secondaryHandler})
    : super(type: DialogType.error, dismissible: false);
}

class UnknownErrorMessage extends DialogMessage {
  UnknownErrorMessage() : super(type: DialogType.error);
}
