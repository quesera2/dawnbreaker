import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_observer.g.dart';

/// 起動時と復帰時に、セッションがサーバーでも生きているか確かめる。
///
/// 定期削除バッチが消すのは、しばらくアプリを前面で使っていない匿名ユーザーに限られる。
/// 消されたあとにユーザーが最初に触れるのは必ず起動か復帰になるため、ここで確かめれば
/// 操作をしなくてもセッション切れに気づける
@Riverpod(keepAlive: true)
class SessionObserver extends _$SessionObserver with WidgetsBindingObserver {
  @override
  void build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
  }

  /// 起動処理から 1 度だけ呼ぶ
  void verifyOnStartup() => _verifyInBackground();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != .resumed) return;
    _verifyInBackground();
  }

  /// ライフサイクルの通知は同期で返す必要があるため待てない。待たない Future の例外は
  /// 未捕捉の非同期例外になるので、ここで受ける
  void _verifyInBackground() {
    unawaited(
      _verify().onError((e, s) {
        logger.e('verifySession failed', error: e, stackTrace: s);
      }),
    );
  }

  Future<void> _verify() async {
    // ログイン画面やチュートリアルにいる間は、確かめるセッションがない
    if (ref.read(currentUserProvider) is NoLogin) return;

    final status = await ref.read(userRepositoryProvider).verifySession();
    if (!ref.mounted) return;
    // 確かめられなかったときは、オフラインをセッション切れと取り違えないよう何もしない
    if (status != .expired) return;
    ref.read(sessionExpiryProvider.notifier).notifyExpired();
  }
}
