import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/google_credential_source.dart';
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
  final GoogleCredentialSource _googleCredentialSource;

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
  Future<LoggedIn?> signInWithGoogle() async {
    final credential = await _googleCredentialSource.getCredential();
    if (credential == null) return null;
    return _signInWithCredential(credential);
  }

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
