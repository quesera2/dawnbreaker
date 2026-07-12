import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
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
    try {
      final repository = await ref.read(userSettingsRepositoryProvider.future);
      final setting = await repository.watchNotificationSetting().first;
      if (!setting.enabled) return;

      final service = await ref.read(notificationServiceProvider.future);
      final hasPermission = await service.checkPermission();
      if (!hasPermission) {
        // 書き込みはオフラインだと完了しないため待たない。unawaited した Future の例外は
        // 外側の try/catch では捕まらないので、ここで受ける
        unawaited(
          repository
              .setNotificationSetting(setting.copyWith(enabled: false))
              .onError((e, s) {
                logger.e(
                  'disable notification failed',
                  error: e,
                  stackTrace: s,
                );
              }),
        );
      }

      await service.syncExactAlarmPermission();
    } catch (e, s) {
      // 呼び出し元が unawaited のため、ここで握らないと未捕捉の非同期例外になる
      logger.e('syncPermission failed', error: e, stackTrace: s);
    }
  }
}
