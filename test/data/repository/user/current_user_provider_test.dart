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
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });
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

  group('起動後にユーザーが変わったとき', () {
    test('新しいユーザーが伝わる', () async {
      setUpContainer(const NoLogin());

      repository.emit(const Guest('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), const Guest('user-1'));
      expect(notifiedUsers, [const Guest('user-1')]);
    });

    test('ログアウトが伝わる', () async {
      setUpContainer(const LoggedIn('user-1'));

      repository.emit(const NoLogin());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), const NoLogin());
      expect(notifiedUsers, [const NoLogin()]);
    });
  });

  // authStateChanges() は購読した直後に現在のユーザーを 1 度流すため、
  // 起動時は同じユーザーが 2 度届く。ここが通知として下流に漏れると、
  // 値が変わっていないのに起動のたびにリポジトリと ViewModel が作り直される
  test('同じユーザーが 2 度届いても作り直しは起きない', () async {
    setUpContainer(const Guest('user-1'));

    repository.emit(const Guest('user-1'));
    await Future<void>.delayed(Duration.zero);

    expect(notifiedUsers, isEmpty);
  });
}
