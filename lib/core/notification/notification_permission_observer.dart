import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_observer.g.dart';

/// OS の通知権限が失われたときにアプリ設定も追従するように監視を行う
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
    if (state != AppLifecycleState.resumed) return;

    // ライフサイクルの通知は同期で返す必要があるため待てない。待たない Future の例外は
    // 未捕捉の非同期例外になるので、ここで受ける
    unawaited(
      _syncPermission().onError((e, s) {
        logger.e('syncPermission failed', error: e, stackTrace: s);
      }),
    );
  }

  Future<void> _syncPermission() async {
    // 未ログインの場合は何もしない
    if (ref.read(currentUserProvider) is NoLogin) return;

    // OSの通知権限がある場合は何もしない
    final service = await ref.read(fcmNotificationServiceProvider.future);
    if (await service.checkPermission()) return;

    // 通知権限がなくなった場合、通知をOFFにする
    // チェック→書き込みだと2回課金が発生するので常にOFFに倒す
    final repository = await ref.read(userSettingsRepositoryProvider.future);
    await repository.setNotificationEnabled(false);
  }
}
