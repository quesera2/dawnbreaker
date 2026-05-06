import 'dart:async' show unawaited;

import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';

abstract final class AppSnackBar {
  static void show(BuildContext context, SnackBarMessage message) {
    final SnackBar snackBar;
    if (message.handler != null) {
      snackBar = createWithAction(
        message: _messageText(context.l10n, message),
        actionLabel: context.l10n.commonUndo,
        onAction: () => unawaited(message.handler!()),
      );
    } else {
      snackBar = create(message: _messageText(context.l10n, message));
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

String _messageText(
  AppLocalizations l10n,
  SnackBarMessage msg,
) => switch (msg) {
  TaskCompleteSuccess(:final taskName) => l10n.homeCompleteSuccess(taskName),
  TaskCreateSuccess(:final taskName) => l10n.editorSaveNewSuccess(taskName),
  TaskUpdateSuccess(:final taskName) => l10n.editorSaveEditSuccess(taskName),
  TaskDeleteSuccess(:final taskName) => l10n.appDetailDeleteSuccess(taskName),
  TaskExecutionUpdateSuccess() => l10n.appDetailUpdateHistorySuccess,
};
