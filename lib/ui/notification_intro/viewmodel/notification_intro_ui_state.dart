import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'notification_intro_ui_state.freezed.dart';

/// 誘導を終えてホームへ進む合図。行き先は 1 つしかないため種別を持たない
class NotificationIntroCompletedEvent {
  NotificationIntroCompletedEvent() : id = const Uuid().v4();

  final String id;
}

@freezed
abstract class NotificationIntroUiState
    with _$NotificationIntroUiState
    implements BaseUiState {
  const NotificationIntroUiState._();

  const factory NotificationIntroUiState({
    @Default(false) bool isEnabling,
    NotificationIntroCompletedEvent? completed,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _NotificationIntroUiState;
}
