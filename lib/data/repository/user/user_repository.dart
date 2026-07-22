import 'package:dawnbreaker/core/auth/app_user.dart';

abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  AppUser getUser();

  /// 以降の変化を購読する
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<Guest> signInAsGuest();
}
