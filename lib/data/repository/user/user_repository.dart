import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/link_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  AppUser getUser();

  /// 以降の変化を購読する
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<Guest> signInAsGuest();

  /// Google のサインイン UI を出してログインする。ユーザーが中断したら `null` を返す
  Future<LoggedIn?> signInWithGoogle();

  /// Google のサインイン UI を出して、いまの匿名アカウントを昇格させる。
  /// credential が既に使われていたときは [LinkCredentialInUse] を返すだけで、サインインはしない
  Future<LinkResult> linkWithGoogle();

  /// [LinkCredentialInUse] が持っていた credential でサインインし直す。
  ///
  /// 昇格をあきらめて別のアカウントへ乗り換える操作で、いまの匿名アカウントのデータは捨てる。
  /// 了承を得たあとにだけ呼ぶ
  Future<LoggedIn> signInWithLinkedCredential(AuthCredential credential);
}
