/// FCM 通知に関するこの端末側の窓口。権限の確認・要求、送信先としてのトークン登録を担う。
abstract interface class NotificationService {
  /// 通知権限の有無をチェックする
  Future<bool> checkPermission();

  /// 通知権限が必要な場合に取得処理を行う
  Future<bool> requestPermission();

  /// 通知の許可を得た直後に呼ぶ。
  ///
  /// iOS は許可を得るまで APNs トークンが発行されず `getToken()` が返らない。
  /// Android は許可がなくてもトークンを取得できるが、表示されない通知の送信先を
  /// 抱えても仕方がないので、同じく許可済みのときだけ登録する。
  Future<void> registerToken();
}
