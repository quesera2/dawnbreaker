import 'dart:async' show unawaited;

import 'package:dawnbreaker/generated/l10n.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';

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
