import 'dart:async';

import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_observer.g.dart';

@Riverpod(keepAlive: true)
class NotificationPermissionObserver extends _$NotificationPermissionObserver
    with WidgetsBindingObserver {
  @override
  void build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncPermission());
    }
  }

  Future<void> _syncPermission() async {
    final repository = await ref.read(userSettingsRepositoryProvider.future);
    final setting = await repository.watchNotificationSetting().first;
    if (!setting.enabled) return;

    final service = await ref.read(notificationServiceProvider.future);
    final hasPermission = await service.checkPermission();
    if (!hasPermission) {
      await repository.setNotificationSetting(setting.copyWith(enabled: false));
    }

    await service.syncExactAlarmPermission();
  }
}
