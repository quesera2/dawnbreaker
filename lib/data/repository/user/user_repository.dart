import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  AppUser getUser();

  /// 以降の変化を購読する
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<Guest> signInAsGuest();

  /// Google のサインイン UI を出してログインする
  Future<SignInResult> signInWithGoogle();

  /// サインアウトする。リンク済みユーザーにだけ許す操作で、
  /// 匿名アカウントは credential がないため戻れなくなる
  Future<void> signOut();

  /// アカウントと、そのユーザーのデータをすべて削除する。
  ///
  /// クライアントの `delete()` は `requires-recent-login` で失敗しうるため、
  /// Cloud Functions 側の Admin SDK で消す
  Future<void> deleteAccount();

  /// [SignInCredentialInUse] が持っていた credential でサインインし直す。
  ///
  /// 昇格をあきらめて別のアカウントへ乗り換える操作で、いまの匿名アカウントのデータは捨てる。
  /// 了承を得たあとにだけ呼ぶ
  Future<LoggedIn> signInWithLinkedCredential(AuthCredential credential);
}
