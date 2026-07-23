import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
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
    // ログイン画面を開いたままアプリを行き来すると未サインインで復帰する。
    // 通知設定の置き場が users/{uid} なので、同期する対象がそもそも無い
    if (ref.read(currentUserProvider) is NoLogin) return;

    try {
      final repository = await ref.read(userSettingsRepositoryProvider.future);
      final setting = await repository.fetchNotificationSetting();
      if (!setting.enabled) return;

      final service = await ref.read(fcmNotificationServiceProvider.future);
      final hasPermission = await service.checkPermission();
      if (!hasPermission) {
        // 書き込みはオフラインだと完了しないため待たない。unawaited した Future の例外は
        // 外側の try/catch では捕まらないので、ここで受ける
        unawaited(
          repository.setNotificationEnabled(false).onError((e, s) {
            logger.e('disable notification failed', error: e, stackTrace: s);
          }),
        );
      }
    } catch (e, s) {
      // 呼び出し元が unawaited のため、ここで握らないと未捕捉の非同期例外になる
      logger.e('syncPermission failed', error: e, stackTrace: s);
    }
  }
}
