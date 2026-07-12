/// デバイストークンを `users/{userId}.fcmTokens` に出し入れする。
///
/// 複数端末が同じアカウントにログインするため配列で保持する。
abstract interface class NotificationTokenRepository {
  Future<void> addToken(String token);

  Future<void> removeToken(String token);
}
