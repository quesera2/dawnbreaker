import 'dart:async' show unawaited;

import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

abstract final class AppSnackBar {
  static void show(BuildContext context, SnackBarMessage message) {
    final (:text, :actionLabel) = _labels(context, message);
    final SnackBar snackBar;
    if (message.handler != null) {
      snackBar = createWithAction(
        message: text,
        actionLabel: actionLabel,
        onAction: () => unawaited(message.handler!()),
      );
    } else {
      snackBar = create(message: text);
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

({String text, String actionLabel}) _labels(
  BuildContext context,
  SnackBarMessage msg,
) => switch (msg) {
  TaskCompleteSuccess(:final taskName) => (
    text: context.l10n.homeCompleteSuccess(taskName),
    actionLabel: context.l10n.commonUndo,
  ),
  TaskCreateSuccess(:final taskName) => (
    text: context.l10n.editorSaveNewSuccess(taskName),
    actionLabel: context.l10n.commonUndo,
  ),
  TaskUpdateSuccess(:final taskName) => (
    text: context.l10n.editorSaveEditSuccess(taskName),
    actionLabel: context.l10n.commonUndo,
  ),
  TaskDeleteSuccess(:final taskName) => (
    text: context.l10n.appDetailDeleteSuccess(taskName),
    actionLabel: context.l10n.commonUndo,
  ),
  TaskExecutionUpdateSuccess() => (
    text: context.l10n.appDetailUpdateHistorySuccess,
    actionLabel: context.l10n.commonUndo,
  ),
  DebugDummyTasksGeneratedMessage() => (
    text: context.l10n.settingsDebugDummyTasksGenerated,
    actionLabel: '',
  ),
  AllTasksDeletedMessage() => (
    text: context.l10n.settingsDebugAllTasksDeleted,
    actionLabel: '',
  ),
};

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
