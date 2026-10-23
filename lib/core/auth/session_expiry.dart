import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'session_expiry.g.dart';

/// セッションが切れていたことがわかったという知らせ。受け取ったらダイアログを出す
class SessionExpiredEvent {
  SessionExpiredEvent() : id = const Uuid().v4();

  final String id;
}

/// セッション切れを、アプリのどこで見つけても 1 か所へ知らせる。
///
/// 状態ではなく一度きりの知らせとして扱う。セッションを値として下流へ流すと、
/// 切れた瞬間に下流の画面が作り直されて壊れるため
@Riverpod(keepAlive: true)
class SessionExpiry extends _$SessionExpiry {
  @override
  SessionExpiredEvent? build() => null;

  /// セッション切れを知らせる。起動時の確認と操作時の確認が同時に見つけても
  /// ダイアログが重ならないよう、サインインし直すまでは 1 度しか知らせない
  void notifyExpired() {
    if (state != null) return;
    state = SessionExpiredEvent();
  }

  /// サインインし直したら、次のセッション切れを知らせられるようにする
  void reset() => state = null;
}
