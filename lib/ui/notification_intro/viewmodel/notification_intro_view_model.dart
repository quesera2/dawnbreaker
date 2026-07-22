import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/notification_intro/viewmodel/notification_intro_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_intro_view_model.g.dart';

@riverpod
class NotificationIntroViewModel extends _$NotificationIntroViewModel {
  @override
  NotificationIntroUiState build() => const NotificationIntroUiState();

  Future<void> onClickEnable() async {
    if (state.isEnabling) return;

    state = state.copyWith(isEnabling: true);
    try {
      await _enableNotification();
    } catch (e, s) {
      logger.e('enable notification failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isEnabling: false,
        dialogMessage: NotificationEnableErrorMessage(),
      );
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      isEnabling: false,
      completed: NotificationIntroCompletedEvent(),
    );
  }

  /// 「あとで」を押したときと、戻る操作をしたときに呼ぶ
  void onSkip() {
    state = state.copyWith(completed: NotificationIntroCompletedEvent());
  }

  /// 許可されなかった場合は何も書かない。`users/{uid}` の初期値が通知 OFF のため、
  /// 設定画面から明示的に有効化してもらう
  Future<void> _enableNotification() async {
    final notificationService = await ref.read(
      fcmNotificationServiceProvider.future,
    );
    if (!await notificationService.requestPermission()) return;

    await notificationService.registerToken();
    final userSettings = await ref.read(userSettingsRepositoryProvider.future);
    await userSettings.setNotificationSetting(
      const NotificationSetting(enabled: true),
    );
  }
}
