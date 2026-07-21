/// この端末を通知の送信先として登録する。
abstract interface class FcmTokenService {
  Future<bool> checkPermission();

  Future<bool> requestPermission();

  /// 通知の許可を得た直後に呼ぶ。
  ///
  /// iOS は許可を得るまで APNs トークンが発行されず `getToken()` が返らない。
  /// Android は許可がなくてもトークンを取得できるが、表示されない通知の送信先を
  /// 抱えても仕方がないので、同じく許可済みのときだけ登録する。
  Future<void> registerToken();
}
