import 'package:cloud_functions/cloud_functions.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/credential_source.dart';
import 'package:dawnbreaker/data/repository/user/google_credential_source.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) => FirebaseUserRepository(
  auth: FirebaseAuth.instance,
  googleCredentialSource: ref.watch(googleCredentialSourceProvider),
);

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({
    required this._auth,
    required this._googleCredentialSource,
  });

  final FirebaseAuth _auth;
  final CredentialSource _googleCredentialSource;

  /// `currentUser` は `Firebase.initializeApp()` が復元したセッションを見る同期 getter で、
  /// 通信もアカウント作成もしない
  @override
  AppUser getUser() => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser> watchUser() => _auth.authStateChanges().map(_toAppUser);

  @override
  Future<Guest> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw const SignInException('sign-in succeeded but returned no user');
    }
    return Guest(user.uid);
  }

  @override
  Future<SignInResult> signInWithGoogle() async {
    final credential = await _googleCredentialSource.getCredential();
    if (credential == null) return const SignInCancelled();
    try {
      final currentUser = _auth.currentUser;
      final LoggedIn user;
      if (currentUser == null) {
        user = await _signInWithCredential(credential);
      } else if (currentUser.isAnonymous) {
        // ゲストのまま押されたときは昇格になる。uid もデータもそのまま残る
        user = await _linkCredential(currentUser, credential);
      } else {
        // リンク済みのまま別のアカウントに入ると、無言でアカウントが入れ替わる。
        // 乗り換えるなら一度ログアウトを挟む導線にする
        throw const SignInException(
          'cannot sign in while already linked to an account',
        );
      }
      return SignInSucceeded(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Apple は nonce の都合で元の credential を再利用できないため、
        // 例外で渡された credential を使う必要がある
        final linkedCredential = e.credential;
        if (linkedCredential == null) {
          throw const SignInException(
            'credential-already-in-use came without a credential',
          );
        }
        return SignInCredentialInUse(linkedCredential);
      } else {
        rethrow;
      }
    }
  }

  /// 匿名アカウントに credential を結び付ける。
  ///
  /// 既に使われている credential だったときは `credential-already-in-use` が飛ぶ。
  /// ここではサインインまで進めない。進めるとゲストのデータを黙って捨てることになる
  Future<LoggedIn> _linkCredential(User user, AuthCredential credential) async {
    final result = await user.linkWithCredential(credential);
    final linkedUser = result.user;
    if (linkedUser == null) {
      throw const SignInException('link succeeded but returned no user');
    }
    return LoggedIn(linkedUser.uid);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// 削除は Functions 側でしか行えないため、通信の失敗もここでは救えない。
  /// 呼び出し元が再試行できるよう、リポジトリの例外に変換して投げ直す。
  ///
  /// `FirebaseFunctions` はモックがなく差し替えても何も確かめられないため、
  /// `_auth` と違い注入しない。テストは `UserRepository` ごと Fake に差し替える
  @override
  Future<void> deleteAccount() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('deleteAccount')
          .call<void>();
    } on FirebaseFunctionsException catch (e) {
      // 認証が付かないのは、この端末が既にサインアウトしているとき。
      // 他端末で消された後なのでアカウントは残っておらず、消えた扱いで返す
      if (e.code == 'unauthenticated') return;
      throw AccountDeletionException(
        'deleteAccount failed: ${e.code} ${e.message}',
      );
    } catch (e) {
      // ID トークンの取得失敗やプラグインの不在もここに来る。素通しすると
      // 呼び出し元の型付き catch を抜けて、進捗表示が消えないまま画面が固まる
      throw AccountDeletionException('deleteAccount failed: $e');
    }
  }

  @override
  Future<LoggedIn> signInWithLinkedCredential(AuthCredential credential) =>
      _signInWithCredential(credential);

  /// Google / Apple などプロバイダに依らず credential でサインインする。
  /// Apple を足すときはトークン取得だけ増やし、この経路を使い回す
  Future<LoggedIn> _signInWithCredential(AuthCredential credential) async {
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw const SignInException('sign-in succeeded but returned no user');
    }
    return LoggedIn(user.uid);
  }

  AppUser _toAppUser(User? user) =>
      user == null ? const NoLogin() : _toSignedInUser(user);

  SignedInUser _toSignedInUser(User user) =>
      user.isAnonymous ? Guest(user.uid) : LoggedIn(user.uid);
}
