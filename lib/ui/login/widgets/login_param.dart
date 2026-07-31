/// ログイン画面をどう開くか。
///
/// 入口ごとに、出す導線と到着後にやることが変わる。
/// 初回は既定のまま、昇格は `showGuest: false`、ログアウトは `executeLogout: true`
class LoginParam {
  const LoginParam({this.showGuest = true, this.executeLogout = false});

  /// ゲストではじめる導線を出すか
  final bool showGuest;

  /// 到着後にサインアウトを実行するか
  final bool executeLogout;

  /// ViewModel の family のキーになるため、値で等しさを判定する
  @override
  bool operator ==(Object other) =>
      other is LoginParam &&
      other.showGuest == showGuest &&
      other.executeLogout == executeLogout;

  @override
  int get hashCode => Object.hash(showGuest, executeLogout);
}
