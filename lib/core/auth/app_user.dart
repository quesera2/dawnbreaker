/// アプリ内で扱うユーザー。
///
/// 値等価を実装しているのは、Riverpod が `state` への代入時に `previous != next` で
/// 通知の要否を判定するため（`ProviderElement.defaultUpdateShouldNotify`）。
/// `currentUserProvider` は初期値を `getUser()` から受け取り、その直後に同じ値を
/// `watchUser()` からもう一度受け取る。等価でないとこの 2 度目が変更として下流に伝わり、
/// 値が変わっていないのに起動のたびにリポジトリと ViewModel が作り直される
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
