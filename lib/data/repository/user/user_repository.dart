import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/session_status.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  AppUser getUser();

  /// この端末にセッションが残っているか。通信しない。
  ///
  /// アカウントが消されても、SDK がトークンの更新に失敗するまでは残って見える
  bool hasSession();

  /// サーバーに問い合わせてセッションが生きているか確かめる。
  ///
  /// 端末にセッションがなければ問い合わせずに [SessionStatus.expired] を返す
  Future<SessionStatus> verifySession();

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
