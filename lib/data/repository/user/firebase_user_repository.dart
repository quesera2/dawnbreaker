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
  Future<SignInResult> signInWithGoogle() =>
      _withGoogleCredential(_signInAsLinkedUser);

  @override
  Future<SignInResult> linkWithGoogle() => _withGoogleCredential(_link);

  /// Google のサインイン UI を出して credential を渡す。
  /// 中断はサインインでも昇格でも同じ扱いなので、ここでまとめて受ける
  Future<SignInResult> _withGoogleCredential(
    Future<SignInResult> Function(AuthCredential credential) signIn,
  ) async {
    final credential = await _googleCredentialSource.getCredential();
    if (credential == null) return const SignInCancelled();
    return signIn(credential);
  }

  Future<SignInResult> _signInAsLinkedUser(AuthCredential credential) async =>
      SignInSucceeded(await _signInWithCredential(credential));

  /// Google / Apple などプロバイダに依らず credential を匿名アカウントに結び付ける。
  ///
  /// 既に使われている credential だったときは、ここではサインインまで進めない。
  /// 進めるとゲストのデータを黙って捨てることになるため、判断は呼び出し元に返す
  Future<SignInResult> _link(AuthCredential credential) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const SignInException('cannot link a credential without a session');
    }

    final UserCredential result;
    try {
      result = await currentUser.linkWithCredential(credential);
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

    final user = result.user;
    if (user == null) {
      throw const SignInException('link succeeded but returned no user');
    }
    return SignInSucceeded(LoggedIn(user.uid));
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
