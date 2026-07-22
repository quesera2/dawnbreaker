import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'login_ui_state.freezed.dart';

enum LoginDestination { home, notificationIntro }

class LoginDestinationEvent {
  LoginDestinationEvent(this.type) : id = const Uuid().v4();

  final LoginDestination type;
  final String id;
}

@freezed
abstract class LoginUiState with _$LoginUiState implements BaseUiState {
  const LoginUiState._();

  const factory LoginUiState({
    @Default(false) bool isSigningIn,
    LoginDestinationEvent? destination,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _LoginUiState;
}
