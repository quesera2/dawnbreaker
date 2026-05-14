import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_observer.g.dart';

@Riverpod(keepAlive: true)
class NotificationPermissionObserver extends _$NotificationPermissionObserver
    with WidgetsBindingObserver {
  late SettingsRepository _repository;
  @override
  void build() {
    _repository = ref.read(settingsRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermission();
    }
  }

  Future<void> _syncPermission() async {
    final enabled = await _repository.watchNotificationEnabled().first;
    if (!enabled) return;

    final service = await ref.read(notificationServiceProvider.future);
    final hasPermission = await service.checkPermission();
    if (!hasPermission) {
      await _repository.setNotificationEnabled(false);
    }
  }
}
