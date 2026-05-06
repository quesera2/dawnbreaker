import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/generated/l10n.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  static Future<void> show(BuildContext context, DialogMessage message) {
    return showDialog<void>(
      context: context,
      builder: (context) => create(context, message),
    );
  }

  static AppDialog create(BuildContext context, DialogMessage message) {
    final (:title, :messageText, :actionLabel) = _labels(context, message);
    return AppDialog(
      title: title,
      message: messageText,
      actions: _buildActions(context, message, actionLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: actions,
    );
  }
}

({String title, String messageText, String actionLabel}) _labels(
  BuildContext context,
  DialogMessage msg,
) => switch (msg) {
  TaskLoadErrorMessage() => (
    title: S.of(context).commonErrorTitle,
    messageText: S.of(context).taskErrorLoadFailed,
    actionLabel: S.of(context).commonUndo,
  ),
  TaskSaveErrorMessage() => (
    title: S.of(context).commonErrorTitle,
    messageText: S.of(context).taskErrorSaveFailed,
    actionLabel: S.of(context).commonUndo,
  ),
  TaskUpdateErrorMessage() => (
    title: S.of(context).commonErrorTitle,
    messageText: S.of(context).taskErrorUpdateFailed,
    actionLabel: S.of(context).commonUndo,
  ),
  TaskDeleteErrorMessage() => (
    title: S.of(context).commonErrorTitle,
    messageText: S.of(context).taskErrorDeleteFailed,
    actionLabel: S.of(context).commonUndo,
  ),
  DeleteTaskConfirmMessage(:final taskName) => (
    title: S.of(context).commonConfirmTitle,
    messageText: S.of(context).appDetailTaskDeleteConfirm(taskName),
    actionLabel: S.of(context).commonDelete,
  ),
  TaskNotFoundErrorMessage() => (
    title: '',
    messageText: S.of(context).taskErrorNotFound,
    actionLabel: '',
  ),
  TaskInvalidArgumentErrorMessage() => (
    title: '',
    messageText: S.of(context).taskErrorInvalidArgument,
    actionLabel: '',
  ),
  OnboardingSaveErrorMessage() => (
    title: '',
    messageText: S.of(context).onboardingErrorSaveFailed,
    actionLabel: '',
  ),
  UnknownErrorMessage() => (
    title: '',
    messageText: S.of(context).commonErrorUnknown,
    actionLabel: '',
  ),
};

List<Widget> _buildActions(
  BuildContext context,
  DialogMessage message,
  String actionLabel,
) {
  void close() => Navigator.of(context).pop();

  if (message.handler == null) {
    return [
      AppButton(
        onPressed: close,
        label: S.of(context).commonOk,
        variant: .secondary,
        size: .medium,
      ),
    ];
  }

  final variant = switch (message.type) {
    .error || .info => AppButtonVariant.primary,
    .destruction => AppButtonVariant.danger,
  };
  return [
    AppButton(
      onPressed: close,
      label: S.of(context).commonCancel,
      variant: .secondary,
      size: .medium,
    ),
    AppButton(
      onPressed: () {
        close();
        message.handler!();
      },
      label: actionLabel,
      variant: variant,
      size: .medium,
    ),
  ];
}

@Preview()
Widget previewAppDialog() => const DialogShowCase();

final class DialogShowCase extends StatelessWidget {
  const DialogShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return PreviewWrapper(
      child: Container(
        color: c.bg,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            AppDialog(
              title: 'エラー',
              message: '読み込みに失敗しました。',
              actions: [
                AppButton(
                  label: 'OK',
                  variant: .secondary,
                  size: .medium,
                  onPressed: () {},
                ),
              ],
            ),
            AppDialog(
              title: 'エラー',
              message: '読み込みに失敗しました。',
              actions: [
                AppButton(
                  label: 'キャンセル',
                  variant: .secondary,
                  size: .medium,
                  onPressed: () {},
                ),
                AppButton(
                  label: '再試行',
                  variant: .primary,
                  size: .medium,
                  onPressed: () {},
                ),
              ],
            ),
            AppDialog(
              title: '確認',
              message: 'タスクを削除しますか？',
              actions: [
                AppButton(
                  label: 'キャンセル',
                  variant: .secondary,
                  size: .medium,
                  onPressed: () {},
                ),
                AppButton(
                  label: '削除',
                  variant: .danger,
                  size: .medium,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
