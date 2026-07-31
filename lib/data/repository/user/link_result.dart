import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 匿名アカウントをアカウントにリンク（昇格）した際の結果
sealed class LinkResult {
  const LinkResult();
}

/// アカウントが使われていなかった場合
final class LinkSucceeded extends LinkResult {
  const LinkSucceeded(this.user);

  final LoggedIn user;
}

/// アカウントがすでに使われていた場合
final class LinkCredentialInUse extends LinkResult {
  const LinkCredentialInUse(this.credential);

  final AuthCredential credential;
}

/// 操作がキャンセルされた場合
final class LinkCancelled extends LinkResult {
  const LinkCancelled();
}
