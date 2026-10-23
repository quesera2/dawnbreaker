import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_guard.g.dart';

/// 書き込みの前後でセッションを確かめ、切れていれば [SessionExpiry] へ知らせる。
///
/// 読み取りの失敗はユーザーに見せないが、書き込みはユーザーの操作なので、
/// セッション切れで失敗したならそう伝える
class SessionGuard {
  SessionGuard({required this._hasSession, required this._notifyExpired});

  final bool Function() _hasSession;
  final void Function() _notifyExpired;

  /// セッションが切れていれば知らせて true を返す。通信しない
  bool checkExpired() {
    if (_hasSession()) return false;
    _notifyExpired();
    return true;
  }
}

@riverpod
SessionGuard sessionGuard(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final sessionExpiry = ref.read(sessionExpiryProvider.notifier);
  return SessionGuard(
    hasSession: userRepository.hasSession,
    notifyExpired: sessionExpiry.notifyExpired,
  );
}
