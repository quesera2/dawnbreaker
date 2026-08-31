import 'dart:async';

import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/components/app_dialog.dart';
import 'package:dawnbreaker/ui/common/components/app_snack_bar.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin MessagesListenMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  void listenMessages<S extends BaseUiState>(ProviderListenable<S> provider) {
    ref.listen(provider.select((s) => s.dialogMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      unawaited(_showDialog(next));
    });

    ref.listen(provider.select((s) => s.snackBarMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      AppSnackBar.show(context, next);
    });
  }

  /// サインインが切れているとどの画面も操作できないため、了承を待ってログイン画面へ送り出す。
  /// ViewModel には遷移の手段がないので、画面ごとに書かずここでまとめて引き受ける
  Future<void> _showDialog(DialogMessage message) async {
    await AppDialog.show(context, message);
    if (message is! SessionExpiredMessage || !mounted) return;
    context.go('/login');
  }
}
