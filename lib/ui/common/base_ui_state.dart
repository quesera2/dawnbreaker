import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';

abstract class BaseUiState {
  DialogMessage? get dialogMessage;

  SnackBarMessage? get snackBarMessage;
}
