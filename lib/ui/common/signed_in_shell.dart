import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// サインインしていないと開けない画面をまとめる Widget。
///
/// 他端末でアカウントを消されると、トークン更新の失敗で SDK がローカルでサインアウトし、
/// `currentUserProvider` が `NoLogin` になる
/// このとき配下を外して、セッション切れを知らせるためのシェル
class SignedInShell extends ConsumerWidget {
  const SignedInShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProvider, (_, user) {
      // サインイン中は何もしない
      if (user is! NoLogin) return;
      // ユーザーが自分で選んだログアウトとアカウント削除の場合も何もしない
      if (!(ModalRoute.of(context)?.isActive ?? false)) return;
      // セッション切れのダイアログはアプリのルートが出す
      ref.read(sessionExpiryProvider.notifier).notifyExpired();
    });

    return switch (ref.watch(currentUserProvider)) {
      SignedInUser() => child,
      // ダイアログを表示するためのダミー
      NoLogin() => const Scaffold(),
    };
  }
}
