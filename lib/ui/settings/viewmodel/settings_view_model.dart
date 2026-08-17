import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/util/stream_util.dart';
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/dummy_tasks.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  late SettingsRepository _settingsRepository;

  @override
  SettingsUiState build() {
    _settingsRepository = ref.read(settingsRepositoryProvider);
    // ユーザー状態に応じて表示を出し分ける、ログインから戻ってきた場合に更新されるようにする
    ref.listen(currentUserProvider, (_, next) {
      state = state.copyWith(isGuest: next is Guest);
    });
    unawaited(_initialize());
    final user = ref.read(currentUserProvider);
    return SettingsUiState(isGuest: user is Guest);
  }

  Future<void> _initialize() async {
    final userSettingsRepository = await ref.read(
      userSettingsRepositoryProvider.future,
    );
    if (!ref.mounted) return;

    final disposable = combineLatest4(
      userSettingsRepository.watchNotificationSetting(),
      _settingsRepository.watchHomeDisplayMode(),
      _settingsRepository.watchProgressBarAnimationEnabled(),
      PackageInfo.fromPlatform().asStream(),
      (notification, mode, animation, info) {
        state = state.copyWith(
          isLoading: false,
          notificationSetting: notification,
          displayMode: mode,
          progressBarAnimationEnabled: animation,
          version: info.version,
        );
      },
    );
    ref.onDispose(() => unawaited(disposable()));
  }

  Future<void> setNotificationEnabled(bool value) async {
    if (value) {
      await _enableNotification();
    } else {
      await _disableNotification();
    }
  }

  Future<void> setNotificationTime({
    required NotifyDay notifyDay,
    required int hour,
    required int minute,
  }) async {
    final updated = state.notificationSetting.copyWith(
      notifyDay: notifyDay,
      hour: hour,
      minute: minute,
    );
    await _setNotificationSetting(updated);
  }

  Future<void> _enableNotification() async {
    state = state.copyWith(
      isNotificationUpdating: true,
      notificationSetting: state.notificationSetting.copyWith(enabled: true),
    );
    final notificationService = await ref.read(
      fcmNotificationServiceProvider.future,
    );

    final hasPermission = await notificationService.checkPermission();
    if (hasPermission) {
      await _setNotificationEnabled(true);
      if (!ref.mounted) return;
      state = state.copyWith(isNotificationUpdating: false);
      return;
    }

    final isGranted = await notificationService.requestPermission();
    if (!ref.mounted) return;

    if (!isGranted) {
      state = state.copyWith(
        isNotificationUpdating: false,
        notificationSetting: state.notificationSetting.copyWith(enabled: false),
        dialogMessage: NotificationPermissionDeniedMessage(
          primaryHandler: () =>
              AppSettings.openAppSettings(type: AppSettingsType.notification),
        ),
      );
      return;
    }

    await notificationService.registerToken();
    if (!ref.mounted) return;

    await _setNotificationEnabled(true);
    if (!ref.mounted) return;

    state = state.copyWith(isNotificationUpdating: false);
  }

  Future<void> _disableNotification() async {
    final updated = state.notificationSetting.copyWith(enabled: false);
    state = state.copyWith(
      isNotificationUpdating: true,
      notificationSetting: updated,
    );
    await _setNotificationEnabled(false);
    if (!ref.mounted) return;
    state = state.copyWith(isNotificationUpdating: false);
  }

  Future<void> _setNotificationSetting(NotificationSetting setting) async {
    final userSettings = await ref.read(userSettingsRepositoryProvider.future);
    // Firestorage はオフラインキャッシュに書き込むため await しない（エラーは権限設定不備などで発生）
    unawaited(
      userSettings.setNotificationSetting(setting).onError((e, s) {
        logger.e('setNotificationSetting failed', error: e, stackTrace: s);
      }),
    );
  }

  Future<void> _setNotificationEnabled(bool enabled) async {
    final userSettings = await ref.read(userSettingsRepositoryProvider.future);
    // Firestorage はオフラインキャッシュに書き込むため await しない（エラーは権限設定不備などで発生）
    unawaited(
      userSettings.setNotificationEnabled(enabled).onError((e, s) {
        logger.e('setNotificationEnabled failed', error: e, stackTrace: s);
      }),
    );
  }

  Future<void> setProgressBarAnimationEnabled(bool value) async {
    await _settingsRepository.setProgressBarAnimationEnabled(value);
  }

  /// 取り消せない操作なので、押しただけでは消さず確認を挟む
  void deleteAccount() {
    state = state.copyWith(
      dialogMessage: DeleteAccountConfirmMessage(
        primaryHandler: () => unawaited(_deleteAccount()),
      ),
    );
  }

  /// アカウントとデータを消して、チュートリアルの先頭へ戻す。
  /// 最初の画面に戻すことで、完全に消えた雰囲気を出す
  Future<void> _deleteAccount() async {
    if (state.isDeletingAccount) return;
    state = state.copyWith(isDeletingAccount: true);

    // 消したアカウント宛の通知がこの端末に届き続けないよう、先に捨てる。
    // Firestore の fcmTokens は users/{uid} ごと消えるため触らない
    await _deleteToken();
    if (!ref.mounted) return;

    try {
      await ref.read(userRepositoryProvider).deleteAccount();
    } on UserRepositoryException catch (e, s) {
      logger.e('deleteAccount failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isDeletingAccount: false,
        dialogMessage: DeleteAccountErrorMessage(
          primaryHandler: () => unawaited(_deleteAccount()),
        ),
      );
      return;
    }
    if (!ref.mounted) return;

    // サインアウトとチュートリアルフラグの削除は遷移先が行う。ここでサインアウトすると、
    // まだ生きているこの画面の購読が NoLogin で走って例外になる（ログアウトと同じ形）
    state = state.copyWith(
      isDeletingAccount: false,
      accountDeleted: AccountDeletedEvent(),
    );
  }

  /// この端末のトークンを捨てる。失敗しても削除は続ける
  Future<void> _deleteToken() async {
    try {
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      await notificationService.deleteToken();
    } catch (e, s) {
      logger.e('deleteToken failed', error: e, stackTrace: s);
    }
  }

  // デバッグメニュー専用。TaskRepository は Firebase に触るため、ここでだけ読む
  Future<void> generateDummyTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteAllTasks();
    await repository.restoreTask(
      buildDummyTasks(now: DateTime.now(), random: Random()),
    );
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: DebugDummyTasksGeneratedMessage());
  }

  // デバッグメニュー専用。TaskRepository は Firebase に触るため、ここでだけ読む
  Future<void> deleteAllTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteAllTasks();
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: AllTasksDeletedMessage());
  }

  Future<void> deleteTutorialFlag() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.removeCompletion();
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: TutorialFlagResetMessage());
  }

  Future<void> resetColorSettings() async {
    await _settingsRepository.setColorSettings(List<ColorSetting>.empty());
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: ColorSettingsResetMessage());
  }
}
