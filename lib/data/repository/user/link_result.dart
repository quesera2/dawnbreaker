import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 匿名アカウントを credential にリンクしようとした結果。
///
/// リンクできたかどうかだけでなく、「別のアカウントで使われている」ことも
/// 呼び出し元が扱えるようにする。データを捨てる操作になるため、
/// 了承を得てからサインインし直すかどうかを UI 側が決める
sealed class LinkResult {
  const LinkResult();
}

/// 昇格できた。uid もデータもそのまま残る
final class LinkSucceeded extends LinkResult {
  const LinkSucceeded(this.user);

  final LoggedIn user;
}

/// ユーザーがサインイン UI を閉じた。失敗ではない
final class LinkCancelled extends LinkResult {
  const LinkCancelled();
}

/// credential が既に別のアカウントで使われていた。
///
/// 持っている credential でサインインすればそのアカウントに入れるが、
/// いまの匿名アカウントのデータは引き継がれない
final class LinkCredentialInUse extends LinkResult {
  const LinkCredentialInUse(this.credential);

  final AuthCredential credential;
}
