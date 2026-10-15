import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/ui/common/components/app_dialog.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// サインインしていないと開けない画面をまとめる Widget。
///
/// 他端末でアカウントを消されると、トークン更新の失敗で SDK がローカルでサインアウトし、
/// `currentUserProvider` が `NoLogin` になる
/// このときセッション切れのダイアログを表示するためのシェル
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
      // セッション切れのダイアログを表示する
      unawaited(
        AppDialog.show(
          context,
          SessionExpiredMessage(secondaryHandler: () => context.go('/login')),
        ),
      );
    });

    return switch (ref.watch(currentUserProvider)) {
      SignedInUser() => child,
      // ダイアログを表示するためのダミー
      NoLogin() => const Scaffold(),
    };
  }
}
