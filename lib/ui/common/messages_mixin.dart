import 'dart:async';

import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/components/app_dialog.dart';
import 'package:dawnbreaker/ui/common/components/app_snack_bar.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin MessagesListenMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// [onDialogClosed] はダイアログを閉じた後に呼ぶ。閉じてから遷移するものは
  /// ここで受け取る（ViewModel からは遷移できず、遷移先は画面ごとに違うため）
  void listenMessages<S extends BaseUiState>(
    ProviderListenable<S> provider, {
    void Function(DialogMessage message)? onDialogClosed,
  }) {
    ref.listen(provider.select((s) => s.dialogMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      unawaited(_showDialog(next, onDialogClosed));
    });

    ref.listen(provider.select((s) => s.snackBarMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      AppSnackBar.show(context, next);
    });
  }

  Future<void> _showDialog(
    DialogMessage message,
    void Function(DialogMessage message)? onDialogClosed,
  ) async {
    await AppDialog.show(context, message);
    if (!mounted) return;
    onDialogClosed?.call(message);
  }
}
