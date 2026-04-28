import 'dart:async' show unawaited;

import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin MessagesListenMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  void listenMessages<S extends BaseUiState>(ProviderListenable<S> provider) {
    ref.listen(provider.select((s) => s.errorMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;

      showDialog<void>(
        context: context,
        builder: (context) => _errorAlertDialog(context, next),
      );
    });

    ref.listen(provider.select((s) => s.snackBarMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_snackText(context, next)),
          persist: false,
          action: next.handler == null
              ? null
              : SnackBarAction(
                  label: _snackActionLabel(context, next),
                  onPressed: () => unawaited(next.handler!()),
                ),
        ),
      );
    });
  }

  Widget _errorAlertDialog(BuildContext ctx, ErrorMessage errorMessage) {
    return AlertDialog(
      title: Text(ctx.l10n.commonErrorTitle),
      content: Text(_errorText(ctx, errorMessage)),
      actions: [
        if (errorMessage.handler != null) ...[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              errorMessage.handler!();
            },
            child: Text(ctx.l10n.commonRetry),
          ),
        ] else
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonOk),
          ),
      ],
    );
  }

  String _snackText(BuildContext ctx, SnackBarMessage m) => switch (m) {
    TaskCompleteSuccessSnackMessage(:final taskName) =>
      ctx.l10n.homeCompleteSuccess(taskName),
    TaskCreateSuccessSnackMessage(:final taskName) =>
      ctx.l10n.editorSaveNewSuccess(taskName),
    TaskUpdateSuccessSnackMessage(:final taskName) =>
      ctx.l10n.editorSaveEditSuccess(taskName),
    TaskDeleteSuccessSnackMessage(:final taskName) =>
      ctx.l10n.appDetailDeleteSuccess(taskName),
    TaskExecutionUpdateSuccessSnackMessage() =>
      ctx.l10n.appDetailUpdateHistorySuccess,
  };

  String _snackActionLabel(BuildContext ctx, SnackBarMessage m) => switch (m) {
    TaskCompleteSuccessSnackMessage() ||
    TaskCreateSuccessSnackMessage() ||
    TaskUpdateSuccessSnackMessage() ||
    TaskDeleteSuccessSnackMessage() ||
    TaskExecutionUpdateSuccessSnackMessage() => ctx.l10n.commonUndo,
  };

  String _errorText(BuildContext ctx, ErrorMessage e) => switch (e) {
    TaskNotFoundErrorMessage() => ctx.l10n.taskErrorNotFound,
    TaskLoadErrorMessage() => ctx.l10n.taskErrorLoadFailed,
    TaskSaveErrorMessage() => ctx.l10n.taskErrorSaveFailed,
    TaskUpdateErrorMessage() => ctx.l10n.taskErrorUpdateFailed,
    TaskDeleteErrorMessage() => ctx.l10n.taskErrorDeleteFailed,
    TaskInvalidArgumentErrorMessage() => ctx.l10n.taskErrorInvalidArgument,
    OnboardingSaveErrorMessage() => ctx.l10n.onboardingErrorSaveFailed,
    UnknownErrorMessage() => ctx.l10n.commonErrorUnknown,
  };
}
