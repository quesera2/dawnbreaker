import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';

abstract class BaseUiState {
  ErrorMessage? get errorMessage;
  SnackBarMessage? get snackBarMessage;
}
