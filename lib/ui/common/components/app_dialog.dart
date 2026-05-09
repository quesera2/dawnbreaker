import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/preview_show_case.dart';
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
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorLoadFailed,
    actionLabel: context.l10n.commonRetry,
  ),
  TaskSaveErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorSaveFailed,
    actionLabel: context.l10n.commonRetry,
  ),
  TaskUpdateErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorUpdateFailed,
    actionLabel: context.l10n.commonRetry,
  ),
  TaskDeleteErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorDeleteFailed,
    actionLabel: context.l10n.commonRetry,
  ),
  TaskExecutionDeleteErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.appDetailDeleteHistoryFailed,
    actionLabel: context.l10n.commonRetry,
  ),
  DeleteTaskConfirmMessage(:final taskName) => (
    title: context.l10n.commonConfirmTitle,
    messageText: context.l10n.appDetailTaskDeleteConfirm(taskName),
    actionLabel: context.l10n.commonDelete,
  ),
  TaskInvalidArgumentErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorInvalidArgument,
    actionLabel: '',
  ),
  OnboardingSaveErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.onboardingErrorSaveFailed,
    actionLabel: '',
  ),
  UnknownErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.commonErrorUnknown,
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
        label: context.l10n.commonOk,
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
      label: context.l10n.commonCancel,
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

final class DialogShowCase extends PreviewShowCase {
  const DialogShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) => Column(
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
  );
}
