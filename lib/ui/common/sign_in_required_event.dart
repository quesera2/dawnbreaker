import 'package:uuid/uuid.dart';

/// サインインし直す必要が出たこと。受け取った画面はログイン画面へ送り出す
class SignInRequiredEvent {
  SignInRequiredEvent() : id = const Uuid().v4();

  final String id;
}
