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
    final config = _labels(context, message);
    return AppDialog(
      title: config.title,
      message: config.messageText,
      actions: _buildActions(
        context,
        message,
        config.primaryActionLabel,
        config.secondaryActionLabel,
      ),
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

typedef LabelConfig = ({
  String title,
  String messageText,
  String primaryActionLabel,
  String secondaryActionLabel,
});

LabelConfig _labels(BuildContext context, DialogMessage msg) => switch (msg) {
  TaskLoadErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorLoadFailed,
    primaryActionLabel: context.l10n.commonRetry,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  TaskSaveErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorSaveFailed,
    primaryActionLabel: context.l10n.commonRetry,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  TaskUpdateErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorUpdateFailed,
    primaryActionLabel: context.l10n.commonRetry,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  TaskDeleteErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorDeleteFailed,
    primaryActionLabel: context.l10n.commonRetry,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  TaskExecutionDeleteErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.appDetailDeleteHistoryFailed,
    primaryActionLabel: context.l10n.commonRetry,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  DeleteTaskConfirmMessage(:final taskName) => (
    title: context.l10n.commonConfirmTitle,
    messageText: context.l10n.appDetailTaskDeleteConfirm(taskName),
    primaryActionLabel: context.l10n.commonDelete,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  TaskInvalidArgumentErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.taskErrorInvalidArgument,
    primaryActionLabel: '',
    secondaryActionLabel: context.l10n.commonOk,
  ),
  OnboardingSaveErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.onboardingErrorSaveFailed,
    primaryActionLabel: '',
    secondaryActionLabel: context.l10n.commonOk,
  ),
  NotificationPermissionDeniedMessage() => (
    title: context.l10n.settingsNotificationPermissionTitle,
    messageText: context.l10n.settingsNotificationPermissionMessage,
    primaryActionLabel: context.l10n.commonOpenSettings,
    secondaryActionLabel: context.l10n.commonCancel,
  ),
  ExactAlarmPermissionRequestMessage() => (
    title: context.l10n.settingsExactAlarmPermissionTitle,
    messageText: context.l10n.settingsExactAlarmPermissionMessage,
    primaryActionLabel: context.l10n.commonOpenSettings,
    secondaryActionLabel: context.l10n.commonSkip,
  ),
  UnknownErrorMessage() => (
    title: context.l10n.commonErrorTitle,
    messageText: context.l10n.commonErrorUnknown,
    primaryActionLabel: '',
    secondaryActionLabel: context.l10n.commonOk,
  ),
};

List<Widget> _buildActions(
  BuildContext context,
  DialogMessage message,
  String primaryActionLabel,
  String secondaryActionLabel,
) {
  void close() => Navigator.of(context).pop();

  if (message.primaryHandler == null) {
    return [
      AppButton(
        onPressed: () {
          close();
          message.secondaryHandler?.call();
        },
        label: secondaryActionLabel,
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
      onPressed: () {
        close();
        message.secondaryHandler?.call();
      },
      label: secondaryActionLabel,
      variant: .secondary,
      size: .medium,
    ),
    AppButton(
      onPressed: () {
        close();
        message.primaryHandler!();
      },
      label: primaryActionLabel,
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
