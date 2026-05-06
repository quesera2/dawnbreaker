import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:dawnbreaker/generated/l10n.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
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

  static AppDialog create(BuildContext context, DialogMessage message) =>
      AppDialog(
        title: S.of(context).commonErrorTitle,
        message: _messageText(context, message),
        actions: _buildActions(context, message),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: actions,
    );
  }
}

String _messageText(BuildContext context, DialogMessage msg) => switch (msg) {
  TaskNotFoundErrorMessage() => S.of(context).taskErrorNotFound,
  TaskLoadErrorMessage() => S.of(context).taskErrorLoadFailed,
  TaskSaveErrorMessage() => S.of(context).taskErrorSaveFailed,
  TaskUpdateErrorMessage() => S.of(context).taskErrorUpdateFailed,
  TaskDeleteErrorMessage() => S.of(context).taskErrorDeleteFailed,
  TaskInvalidArgumentErrorMessage() => S.of(context).taskErrorInvalidArgument,
  OnboardingSaveErrorMessage() => S.of(context).onboardingErrorSaveFailed,
  UnknownErrorMessage() => S.of(context).commonErrorUnknown,
};

List<Widget> _buildActions(BuildContext context, DialogMessage message) {
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
      label: message.actionLabel ?? S.of(context).commonRetry,
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
    return Theme(
      data: createThemeData(context),
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
