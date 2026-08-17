import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.initialUser) : _user = initialUser;

  /// 昇格しようとした credential を既に持っているアカウント
  static const linkedAccountUser = LoggedIn('linked-account-user');

  final AppUser initialUser;
  final _controller = StreamController<AppUser>.broadcast();
  AppUser _user;

  /// サインインが通信に失敗する状況を作る
  bool shouldThrow = false;

  /// Google サインインをユーザーが中断した状況を作る
  bool cancelSignIn = false;

  /// 昇格しようとした credential が既に別のアカウントで使われている状況を作る
  bool credentialAlreadyInUse = false;

  /// アカウント削除の Function 呼び出しが失敗する状況を作る
  bool shouldFailDeleteAccount = false;

  int signInAsGuestCount = 0;
  int signInWithGoogleCount = 0;
  int signInWithLinkedCredentialCount = 0;
  int signOutCount = 0;
  int deleteAccountCount = 0;

  @override
  AppUser getUser() => _user;

  /// 本物の `authStateChanges()` は購読した時点のユーザーを 1 度流してから変化を流す
  @override
  Stream<AppUser> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<Guest> signInAsGuest() async {
    signInAsGuestCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    const user = Guest('signed-in-guest');
    // 本物は authStateChanges() 経由でサインイン後のユーザーを流す
    emit(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    emit(const NoLogin());
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
    // 本物は authStateChanges() 経由でサインイン後のユーザーを流す
    emit(user);
    return SignInSucceeded(user);
  }

  @override
  Future<LoggedIn> signInWithLinkedCredential(AuthCredential credential) async {
    signInWithLinkedCredentialCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    emit(linkedAccountUser);
    return linkedAccountUser;
  }

  /// `authStateChanges()` からユーザーが流れてくる状況を作る
  void emit(AppUser user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> close() => _controller.close();
}
