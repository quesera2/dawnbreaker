import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) =>
    FirebaseUserRepository(auth: FirebaseAuth.instance);

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({required this._auth});

  final FirebaseAuth _auth;

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

  AppUser _toAppUser(User? user) =>
      user == null ? const NoLogin() : _toSignedInUser(user);

  SignedInUser _toSignedInUser(User user) =>
      user.isAnonymous ? Guest(user.uid) : LoggedIn(user.uid);
}
