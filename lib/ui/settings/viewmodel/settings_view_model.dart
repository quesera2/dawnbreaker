import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
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
    ref.listen(notificationEnabledProvider, (_, next) {
      next.whenData(
        (enabled) => state = state.copyWith(notificationEnabled: enabled),
      );
    });
    _initialize();
    return const SettingsUiState();
  }

  Future<void> _initialize() async {
    final info = await PackageInfo.fromPlatform();
    final notificationEnabled = await _repository
        .watchNotificationEnabled()
        .first;
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: false,
      version: info.version,
      notificationEnabled: notificationEnabled,
    );
  }

  Future<void> setNotificationEnabled(bool value) async {
    if (value) {
      await _enableNotification();
    } else {
      await _disableNotification();
    }
  }

  Future<void> _enableNotification() async {
    state = state.copyWith(
      isNotificationUpdating: true,
      notificationEnabled: true,
    );
    final notificationService = await ref.read(
      notificationServiceProvider.future,
    );

    final hasPermission = await notificationService.checkPermission();
    if (hasPermission) {
      await ref.read(settingsRepositoryProvider).setNotificationEnabled(true);
      if (!ref.mounted) return;
      state = state.copyWith(isNotificationUpdating: false);
      return;
    }

    final isGranted = await notificationService.requestPermission();
    if (!ref.mounted) return;

    if (!isGranted) {
      state = state.copyWith(
        isNotificationUpdating: false,
        notificationEnabled: false,
        dialogMessage: NotificationPermissionDeniedMessage(
          primaryHandler: () =>
              AppSettings.openAppSettings(type: AppSettingsType.notification),
        ),
      );
      return;
    }

    await ref.read(settingsRepositoryProvider).setNotificationEnabled(true);
    if (!ref.mounted) return;

    final canExact = await notificationService.canScheduleExactAlarms();
    if (!ref.mounted) return;
    if (!canExact) {
      state = state.copyWith(
        isNotificationUpdating: false,
        dialogMessage: ExactAlarmPermissionRequestMessage(
          primaryHandler: () =>
              notificationService.requestExactAlarmPermission(),
        ),
      );
      return;
    }

    state = state.copyWith(isNotificationUpdating: false);
  }

  Future<void> _disableNotification() async {
    state = state.copyWith(
      isNotificationUpdating: true,
      notificationEnabled: false,
    );
    await ref.read(settingsRepositoryProvider).setNotificationEnabled(false);
    if (!ref.mounted) return;
    state = state.copyWith(isNotificationUpdating: false);
  }

  Future<void> generateDummyTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteAllTasks();
    for (final task in buildDummyTasks(now: DateTime.now(), random: Random())) {
      await repository.restoreTask(task);
    }
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: DebugDummyTasksGeneratedMessage());
  }

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
}
