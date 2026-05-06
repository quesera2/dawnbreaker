import 'dart:async' show unawaited;

import 'package:dawnbreaker/generated/l10n.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

abstract final class AppSnackBar {
  static void show(BuildContext context, SnackBarMessage message) {
    final SnackBar snackBar;
    if (message.handler != null) {
      snackBar = createWithAction(
        message: _messageText(context, message),
        actionLabel: S.of(context).commonUndo,
        onAction: () => unawaited(message.handler!()),
      );
    } else {
      snackBar = create(message: _messageText(context, message));
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static SnackBar create({required String message}) =>
      SnackBar(content: Text(message), persist: false);

  static SnackBar createWithAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) => SnackBar(
    content: Text(message),
    persist: false,
    action: SnackBarAction(label: actionLabel, onPressed: onAction),
  );
}

@Preview()
Widget previewSnackBar() => const SnackBarShowCase();

final class SnackBarShowCase extends StatelessWidget {
  const SnackBarShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewWrapper(
      child: ScaffoldMessenger(
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  AppButton(
                    label: '完了通知',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar.create(message: '「オイル交換」の完了を記録しました'),
                    ),
                  ),
                  AppButton(
                    label: '登録通知（取り消しあり）',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar.createWithAction(
                        message: '「歯ブラシ交換」を登録しました',
                        actionLabel: '取り消し',
                        onAction: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _messageText(BuildContext context, SnackBarMessage msg) => switch (msg) {
  TaskCompleteSuccess(:final taskName) =>
    S.of(context).homeCompleteSuccess(taskName),
  TaskCreateSuccess(:final taskName) =>
    S.of(context).editorSaveNewSuccess(taskName),
  TaskUpdateSuccess(:final taskName) =>
    S.of(context).editorSaveEditSuccess(taskName),
  TaskDeleteSuccess(:final taskName) =>
    S.of(context).appDetailDeleteSuccess(taskName),
  TaskExecutionUpdateSuccess() => S.of(context).appDetailUpdateHistorySuccess,
};
