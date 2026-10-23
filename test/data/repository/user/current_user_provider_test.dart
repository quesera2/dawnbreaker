import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_user_repository.dart';

void main() {
  late FakeUserRepository repository;
  late ProviderContainer container;
  late List<AppUser> notifiedUsers;

  void setUpContainer(AppUser initialUser) {
    repository = FakeUserRepository(initialUser);
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    notifiedUsers = [];
    container.listen(currentUserProvider, (_, next) => notifiedUsers.add(next));
    addTearDown(container.dispose);
  }

  group('起動直後', () {
    test('前回のセッションが残っていればそのユーザーになる', () {
      setUpContainer(const Guest('user-1'));
      expect(container.read(currentUserProvider), const Guest('user-1'));
    });

    test('セッションがなければ未サインインになる', () {
      setUpContainer(const NoLogin());
      expect(container.read(currentUserProvider), const NoLogin());
    });
  });

  group('端末のセッションが替わったとき', () {
    // 外から切られたセッションで下流の画面が作り直されて壊れないよう、自分からは追わない
    test('読み直すまでは伝わらない', () async {
      setUpContainer(const LoggedIn('user-1'));

      repository.changeUser(const NoLogin());
      await pumpEventQueue();

      expect(container.read(currentUserProvider), const LoggedIn('user-1'));
      expect(notifiedUsers, isEmpty);
    });

    test('読み直すと新しいユーザーが伝わる', () async {
      setUpContainer(const NoLogin());

      repository.changeUser(const Guest('user-1'));
      container.invalidate(currentUserProvider);
      await pumpEventQueue();

      expect(container.read(currentUserProvider), const Guest('user-1'));
      expect(notifiedUsers, [const Guest('user-1')]);
    });

    test('読み直しても同じユーザーなら作り直しは起きない', () async {
      setUpContainer(const Guest('user-1'));

      container.invalidate(currentUserProvider);
      await pumpEventQueue();

      expect(notifiedUsers, isEmpty);
    });
  });
}
