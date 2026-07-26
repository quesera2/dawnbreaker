import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_auth_token_source.g.dart';

/// Google サインインで得たトークン。Firebase の credential 生成に使う。
class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken});

  final String idToken;
}

/// Google のサインイン UI を出してトークンを取る。
///
/// `GoogleSignIn.instance` はシングルトンで差し替えられないため、リポジトリから
/// 直接触らずこの seam を挟む。テストでは fake に差し替える。
abstract interface class GoogleAuthTokenSource {
  /// サインイン UI を出してトークンを返す。ユーザーが中断したら `null` を返す。
  Future<GoogleAuthTokens?> getTokens();
}

@riverpod
GoogleAuthTokenSource googleAuthTokenSource(Ref ref) =>
    GoogleSignInTokenSource();

class GoogleSignInTokenSource implements GoogleAuthTokenSource {
  GoogleSignInTokenSource({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  /// `authenticate()` の前に一度だけ呼ぶ必要がある。結果を保持して以降は使い回す。
  /// iOS は GoogleService-Info.plist の CLIENT_ID を、Android は google-services.json
  /// 由来の default_web_client_id を自動で読むため、引数は渡さない
  Future<void>? _initialization;

  @override
  Future<GoogleAuthTokens?> getTokens() async {
    await (_initialization ??= _googleSignIn.initialize());
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SignInException(
          'google sign-in succeeded but returned no id token',
        );
      }
      return GoogleAuthTokens(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // ユーザーが中断しただけならエラー扱いにしない
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw SignInException('google sign-in failed: ${e.code}');
    }
  }
}
