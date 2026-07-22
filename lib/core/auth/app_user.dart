/// アプリ内で扱うユーザー。
///
/// 値等価を実装しているのは、`currentUserProvider` が同じ値を 2 度受け取るため。
/// 初期値を `getUser()` から、その直後に同じ値が `watchUser()` から流れてくるので、
/// 等価でないと起動のたびに下流が 1 度無駄に再構築される
sealed class AppUser {
  const AppUser();
}

/// 未サインイン、またはサインアウト後
final class NoLogin extends AppUser {
  const NoLogin();

  @override
  bool operator ==(Object other) => other is NoLogin;

  @override
  int get hashCode => (NoLogin).hashCode;
}

/// サインイン済み。必ず uid を持つ
sealed class SignedInUser extends AppUser {
  const SignedInUser(this.id);

  final String id;
}

/// 匿名アカウント
final class Guest extends SignedInUser {
  const Guest(super.id);

  @override
  bool operator ==(Object other) => other is Guest && other.id == id;

  @override
  int get hashCode => Object.hash(Guest, id);
}

/// Google / Apple にリンク済みのアカウント
final class LoggedIn extends SignedInUser {
  const LoggedIn(super.id);

  @override
  bool operator ==(Object other) => other is LoggedIn && other.id == id;

  @override
  int get hashCode => Object.hash(LoggedIn, id);
}
