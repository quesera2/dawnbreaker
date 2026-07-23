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
    if (state != AppLifecycleState.resumed) return;

    // ライフサイクルの通知は同期で返す必要があるため待てない。待たない Future の例外は
    // 未捕捉の非同期例外になるので、ここで受ける
    unawaited(
      _syncPermission().onError((e, s) {
        logger.e('syncPermission failed', error: e, stackTrace: s);
      }),
    );
  }

  /// 設定は有効なのに OS の許可が失われていたら、設定を無効に戻す。
  ///
  /// 完了を待っている呼び出し元がいないため、オフラインで最後の書き込みが終わらなくても困らない
  Future<void> _syncPermission() async {
    // ログイン画面を開いたままアプリを行き来すると未サインインで復帰する。
    // 通知設定の置き場が users/{uid} なので、同期する対象がそもそも無い
    if (ref.read(currentUserProvider) is NoLogin) return;

    final repository = await ref.read(userSettingsRepositoryProvider.future);
    final setting = await repository.fetchNotificationSetting();
    if (!setting.enabled) return;

    final service = await ref.read(fcmNotificationServiceProvider.future);
    if (await service.checkPermission()) return;

    await repository.setNotificationEnabled(false);
  }
}
