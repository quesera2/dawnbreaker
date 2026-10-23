import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/session_status.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.initialUser) : _user = initialUser;

  /// 昇格しようとした credential を既に持っているアカウント
  static const linkedAccountUser = LoggedIn('linked-account-user');

  final AppUser initialUser;
  AppUser _user;

  /// サインインが通信に失敗する状況を作る
  bool shouldThrow = false;

  /// Google サインインをユーザーが中断した状況を作る
  bool cancelSignIn = false;

  /// 昇格しようとした credential が既に別のアカウントで使われている状況を作る
  bool credentialAlreadyInUse = false;

  /// アカウント削除の Function 呼び出しが失敗する状況を作る
  bool shouldFailDeleteAccount = false;

  /// SDK がトークンの更新に失敗して、端末のセッションを捨てた状況を作る
  bool sessionLost = false;

  /// 端末にセッションが残っているときに、サーバーへの問い合わせが返す状態
  SessionStatus serverSessionStatus = .valid;

  int verifySessionCount = 0;
  int signInAsGuestCount = 0;
  int signInWithGoogleCount = 0;
  int signInWithLinkedCredentialCount = 0;
  int signOutCount = 0;
  int deleteAccountCount = 0;

  @override
  AppUser getUser() => _user;

  @override
  bool hasSession() => _user is SignedInUser && !sessionLost;

  @override
  Future<SessionStatus> verifySession() async {
    verifySessionCount++;
    if (!hasSession()) return .expired;
    return serverSessionStatus;
  }

  @override
  Future<Guest> signInAsGuest() async {
    signInAsGuestCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    const user = Guest('signed-in-guest');
    changeUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    changeUser(const NoLogin());
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCount++;
    if (shouldFailDeleteAccount) {
      throw const AccountDeletionException('テストエラー');
    }
  }

  @override
  Future<SignInResult> signInWithGoogle() async {
    signInWithGoogleCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    if (cancelSignIn) return const SignInCancelled();
    if (credentialAlreadyInUse) {
      return SignInCredentialInUse(
        GoogleAuthProvider.credential(idToken: 'linked-id-token'),
      );
    }

    // ゲストのままなら昇格になり、uid は変わらない
    final user = switch (_user) {
      SignedInUser(:final id) => LoggedIn(id),
      NoLogin() => const LoggedIn('signed-in-google-user'),
    };
    changeUser(user);
    return SignInSucceeded(user);
  }

  @override
  Future<LoggedIn> signInWithLinkedCredential(AuthCredential credential) async {
    signInWithLinkedCredentialCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    changeUser(linkedAccountUser);
    return linkedAccountUser;
  }

  /// 端末のセッションのユーザーを替える。`currentUserProvider` には、
  /// 本物と同じく読み直すまで伝わらない
  void changeUser(AppUser user) => _user = user;
}
