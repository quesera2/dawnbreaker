import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

sealed class AppUser {
  const AppUser();
}

/// SQLiteでローカル動作するためのユーザー
class LocalUser extends AppUser {
  const LocalUser();
}

/// Firebase CloudStore
class FirebaseAppUser extends AppUser {
  const FirebaseAppUser(this._user);

  final firebase_auth.User _user;

  String get id => _user.uid;

  bool get isAnonymous => _user.isAnonymous;
}
