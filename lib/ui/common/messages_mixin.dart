import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/components/app_dialog.dart';
import 'package:dawnbreaker/ui/common/components/app_snack_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin MessagesListenMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  void listenMessages<S extends BaseUiState>(ProviderListenable<S> provider) {
    ref.listen(provider.select((s) => s.dialogMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      AppDialog.show(context, next);
    });

    ref.listen(provider.select((s) => s.snackBarMessage), (prev, next) {
      if (next == null || prev?.id == next.id) return;
      AppSnackBar.show(context, next);
    });
  }
}
