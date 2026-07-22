import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) => FirebaseUserRepository();

class FirebaseUserRepository implements UserRepository {
  /// `currentUser` は `Firebase.initializeApp()` が復元したセッションを見る同期 getter で、
  /// 通信もアカウント作成もしない
  @override
  AppUser getUser() => _toAppUser(FirebaseAuth.instance.currentUser);

  @override
  Stream<AppUser> watchUser() =>
      FirebaseAuth.instance.authStateChanges().map(_toAppUser);

  @override
  Future<SignedInUser> signInAnonymously() async {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return _toSignedInUser(credential.user!);
  }

  AppUser _toAppUser(User? user) =>
      user == null ? const NoLogin() : _toSignedInUser(user);

  SignedInUser _toSignedInUser(User user) =>
      user.isAnonymous ? Guest(user.uid) : LoggedIn(user.uid);
}
