import 'package:dawnbreaker/data/repository/user/credential_source.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_credential_source.g.dart';

@riverpod
CredentialSource googleCredentialSource(Ref ref) =>
    GoogleSignInCredentialSource();

/// Google サインインの [CredentialSource]。
///
/// `GoogleSignIn.instance`（private コンストラクタのシングルトン）を包む薄いアダプタ。
/// 単体テストはせず、テストは [CredentialSource] の fake で書く。
class GoogleSignInCredentialSource implements CredentialSource {
  bool _initialized = false;

  @override
  Future<AuthCredential?> getCredential() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SignInException(
          'google sign-in succeeded but returned no id token',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // ユーザーが中断しただけならエラー扱いにしない
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw SignInException('google sign-in failed: ${e.code}');
    }
  }

  /// `authenticate()` の前に一度だけ初期化する。
  /// iOS は GoogleService-Info.plist の CLIENT_ID を、Android は google-services.json
  /// 由来の default_web_client_id を自動で読むため、引数は渡さない
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }
}
