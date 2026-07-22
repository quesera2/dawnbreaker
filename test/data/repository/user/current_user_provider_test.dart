import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this._initialUser);

  final AppUser _initialUser;
  final _controller = StreamController<AppUser>.broadcast();

  @override
  AppUser getUser() => _initialUser;

  @override
  Stream<AppUser> watchUser() => _controller.stream;

  @override
  Future<Guest> signInAsGuest() async =>
      throw UnimplementedError('not called in this test');

  void emit(AppUser user) => _controller.add(user);

  Future<void> close() => _controller.close();
}

void main() {
  late FakeUserRepository repository;
  late ProviderContainer container;
  late List<AppUser> notifiedUsers;

  void createContainer(AppUser initialUser) {
    repository = FakeUserRepository(initialUser);
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    notifiedUsers = [];
    container.listen(
      currentUserProvider,
      (_, next) => notifiedUsers.add(next),
      fireImmediately: false,
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });
  }

  test('初期値は getUser() から同期で読める', () {
    createContainer(const Guest('user-1'));
    expect(container.read(currentUserProvider), const Guest('user-1'));
  });

  test('サインインしていなければ NoLogin になる', () {
    createContainer(const NoLogin());
    expect(container.read(currentUserProvider), const NoLogin());
  });

  test('watchUser() の変化が state に反映される', () async {
    createContainer(const NoLogin());
    container.read(currentUserProvider);

    repository.emit(const Guest('user-1'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentUserProvider), const Guest('user-1'));
    expect(notifiedUsers, [const Guest('user-1')]);
  });

  test('初期値と同じ値が Stream から届いても下流に通知されない', () async {
    createContainer(const Guest('user-1'));
    container.read(currentUserProvider);

    // authStateChanges() が購読直後に現在値を 1 度流すのを模す
    repository.emit(const Guest('user-1'));
    await Future<void>.delayed(Duration.zero);

    expect(notifiedUsers, isEmpty);
  });
}
