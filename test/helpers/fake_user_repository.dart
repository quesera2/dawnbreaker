import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.initialUser);

  final AppUser initialUser;
  final _controller = StreamController<AppUser>.broadcast();

  /// サインインが通信に失敗する状況を作る
  bool shouldThrow = false;

  /// Google サインインをユーザーが中断した状況を作る
  bool cancelSignIn = false;
  int signInAsGuestCount = 0;
  int signInWithGoogleCount = 0;

  @override
  AppUser getUser() => initialUser;

  @override
  Stream<AppUser> watchUser() => _controller.stream;

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
  Future<LoggedIn?> signInWithGoogle() async {
    signInWithGoogleCount++;
    if (shouldThrow) throw const SignInException('テストエラー');
    if (cancelSignIn) return null;
    const user = LoggedIn('signed-in-google-user');
    // 本物は authStateChanges() 経由でサインイン後のユーザーを流す
    emit(user);
    return user;
  }

  /// `authStateChanges()` からユーザーが流れてくる状況を作る
  void emit(AppUser user) => _controller.add(user);

  Future<void> close() => _controller.close();
}
