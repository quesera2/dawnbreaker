/// FCM 通知に関するこの端末側の窓口。権限の確認・要求、送信先としてのトークン登録を担う。
abstract interface class NotificationService {
  /// 通知権限の有無をチェックする
  Future<bool> checkPermission();

  /// 通知権限が必要な場合に取得処理を行う
  Future<bool> requestPermission();

  /// トークンを取得し現在アカウントの通知送信先に登録する
  ///
  /// 通知許可権限がある場合のみ実行する
  Future<void> registerToken();

  /// 現在アカウントに登録されている通知送信先からこの端末を外す
  Future<void> unregisterToken();
}
