import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.initialUser);

  final AppUser initialUser;
  final _controller = StreamController<AppUser>.broadcast();

  @override
  AppUser getUser() => initialUser;

  @override
  Stream<AppUser> watchUser() => _controller.stream;

  @override
  Future<Guest> signInAsGuest() async => const Guest('signed-in-guest');

  /// `authStateChanges()` からユーザーが流れてくる状況を作る
  void emit(AppUser user) => _controller.add(user);

  Future<void> close() => _controller.close();
}
