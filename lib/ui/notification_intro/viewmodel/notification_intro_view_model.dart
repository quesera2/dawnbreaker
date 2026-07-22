import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
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

  /// 「あとで」を押したときと、戻る操作をしたときに呼ぶ。
  ///
  /// 有効化の最中は受け付けない。ここでホームへ進むと画面と一緒にこの ViewModel も
  /// 破棄され、書き込みが失敗してもエラーを返せないまま通知 ON だと思わせてしまうため
  void onSkip() {
    if (state.isEnabling) return;

    state = state.copyWith(completed: NotificationIntroCompletedEvent());
  }

  /// 許可されなかった場合は何も書かない。`users/{uid}` の初期値が通知 OFF のため、
  /// 設定画面から明示的に有効化してもらう
  ///
  /// 既存アカウントで別端末からサインインするとこの画面を通るため、通知の時刻・日は
  /// サーバーにある値を引き継ぐ。丸ごと書くと設定済みの時刻が初期値に戻る
  Future<void> _enableNotification() async {
    final notificationService = await ref.read(
      fcmNotificationServiceProvider.future,
    );
    if (!await notificationService.requestPermission()) return;

    await notificationService.registerToken();
    final userSettings = await ref.read(userSettingsRepositoryProvider.future);
    final current = await userSettings.watchNotificationSetting().first;
    await userSettings.setNotificationSetting(current.copyWith(enabled: true));
  }
}
