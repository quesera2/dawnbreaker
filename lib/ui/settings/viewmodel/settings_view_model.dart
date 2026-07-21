import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_token_service_impl.dart';
import 'package:dawnbreaker/core/util/stream_util.dart' show combineLatest3;
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/dummy_tasks.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  late SettingsRepository _repository;

  @override
  SettingsUiState build() {
    _repository = ref.read(settingsRepositoryProvider);
    unawaited(_initialize());
    return const SettingsUiState();
  }

  Future<void> _initialize() async {
    final userSettingsRepository = await ref.read(
      userSettingsRepositoryProvider.future,
    );
    if (!ref.mounted) return;

    final disposable = combineLatest3(
      userSettingsRepository.watchNotificationSetting(),
      _repository.watchHomeDisplayMode(),
      _repository.watchProgressBarAnimationEnabled(),
      (NotificationSetting notification, HomeDisplayMode mode, bool animation) {
        state = state.copyWith(
          notificationSetting: notification,
          displayMode: mode,
          progressBarAnimationEnabled: animation,
        );
      },
    );
    ref.onDispose(() => unawaited(disposable()));

    final info = await PackageInfo.fromPlatform();
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false, version: info.version);
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
    final fcmTokenService = await ref.read(fcmTokenServiceProvider.future);

    final hasPermission = await fcmTokenService.checkPermission();
    if (hasPermission) {
      await _setNotificationSetting(state.notificationSetting);
      if (!ref.mounted) return;
      state = state.copyWith(isNotificationUpdating: false);
      return;
    }

    final isGranted = await fcmTokenService.requestPermission();
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

    await fcmTokenService.registerToken();
    if (!ref.mounted) return;

    await _setNotificationSetting(state.notificationSetting);
    if (!ref.mounted) return;

    state = state.copyWith(isNotificationUpdating: false);
  }

  Future<void> _disableNotification() async {
    final updated = state.notificationSetting.copyWith(enabled: false);
    state = state.copyWith(
      isNotificationUpdating: true,
      notificationSetting: updated,
    );
    await _setNotificationSetting(updated);
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

  Future<void> setProgressBarAnimationEnabled(bool value) async {
    await _repository.setProgressBarAnimationEnabled(value);
  }

  Future<void> generateDummyTasks() async {
    final repository = await ref.read(taskRepositoryProvider.future);
    await repository.deleteAllTasks();
    await repository.restoreTask(
      buildDummyTasks(now: DateTime.now(), random: Random()),
    );
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: DebugDummyTasksGeneratedMessage());
  }

  Future<void> deleteAllTasks() async {
    final repository = await ref.read(taskRepositoryProvider.future);
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
    await _repository.setColorSettings(List<ColorSetting>.empty());
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: ColorSettingsResetMessage());
  }
}
