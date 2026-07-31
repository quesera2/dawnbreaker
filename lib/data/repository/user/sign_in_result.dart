import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// credential でサインインした結果。初回のサインインと昇格で共通に使う
sealed class SignInResult {
  const SignInResult();
}

/// サインインできた場合。昇格なら uid もデータもそのまま残る
final class SignInSucceeded extends SignInResult {
  const SignInSucceeded(this.user);

  final LoggedIn user;
}

/// アカウントがすでに使われていた場合。昇格でだけ起きる
final class SignInCredentialInUse extends SignInResult {
  const SignInCredentialInUse(this.credential);

  final AuthCredential credential;
}

/// 操作がキャンセルされた場合
final class SignInCancelled extends SignInResult {
  const SignInCancelled();
}
