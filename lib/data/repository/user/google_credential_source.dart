import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_credential_source.g.dart';

/// Google のサインイン UI を出し、Firebase 用の credential を作って返す。
///
/// この抽象がテストの seam。`GoogleSignInCredentialSource` は
/// `GoogleSignIn.instance`（private コンストラクタのシングルトン）を包むだけの
/// 薄いアダプタで単体テストはせず、テストはこのインターフェースの fake で書く。
/// Google 固有の処理（トークン取得と `GoogleAuthProvider` への詰め替え）はここで閉じ、
/// リポジトリには `AuthCredential` だけを渡す。
abstract interface class GoogleCredentialSource {
  /// サインイン UI を出して credential を返す。ユーザーが中断したら `null` を返す。
  Future<AuthCredential?> getCredential();
}

@riverpod
GoogleCredentialSource googleCredentialSource(Ref ref) =>
    GoogleSignInCredentialSource();

class GoogleSignInCredentialSource implements GoogleCredentialSource {
  /// `authenticate()` の前に一度だけ初期化する必要がある。`late final` により
  /// 初回アクセスで一度だけ実行され、以降は同じ Future を待つ。
  /// iOS は GoogleService-Info.plist の CLIENT_ID を、Android は google-services.json
  /// 由来の default_web_client_id を自動で読むため、引数は渡さない
  late final Future<void> _initialization = GoogleSignIn.instance.initialize();

  @override
  Future<AuthCredential?> getCredential() async {
    await _initialization;
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
}
