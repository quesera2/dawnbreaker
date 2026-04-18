import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin ErrorDialogMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void listenError<S extends BaseUiState>(ProviderListenable<S> provider) {
    ref.listen(provider.select((s) => s.errorMessage), (_, errorMessage) {
      if (errorMessage == null) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.errorTitle),
          content: Text(_errorText(ctx, errorMessage)),
          actions: [
            if (errorMessage.handler != null) ...[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  errorMessage.handler!();
                },
                child: Text(ctx.l10n.retry),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.l10n.ok),
              ),
          ],
        ),
      );
    });
  }

  String _errorText(BuildContext ctx, ErrorMessage e) => switch (e) {
    TaskNotFoundErrorMessage() => ctx.l10n.taskErrorNotFound,
    TaskLoadErrorMessage() => ctx.l10n.taskErrorLoadFailed,
    TaskSaveErrorMessage() => ctx.l10n.taskErrorSaveFailed,
    TaskUpdateErrorMessage() => ctx.l10n.taskErrorUpdateFailed,
    TaskDeleteErrorMessage() => ctx.l10n.taskErrorDeleteFailed,
    TaskInvalidArgumentErrorMessage() => ctx.l10n.taskErrorInvalidArgument,
    UnknownErrorMessage() => ctx.l10n.errorUnknown,
  };
}
