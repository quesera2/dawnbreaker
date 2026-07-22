import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FirebaseUserRepository createRepository(MockFirebaseAuth auth) =>
      FirebaseUserRepository(auth: auth);

  group('起動時のユーザーの読み取り', () {
    test('セッションが残っていなければ未サインインになる', () {
      final auth = MockFirebaseAuth();
      expect(createRepository(auth).getUser(), const NoLogin());
    });

    test('匿名のセッションが残っていればゲストになる', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true, uid: 'guest-1'),
      );
      expect(createRepository(auth).getUser(), const Guest('guest-1'));
    });

    test('リンク済みのセッションが残っていればログイン済みになる', () {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-1'),
      );
      expect(createRepository(auth).getUser(), const LoggedIn('user-1'));
    });

    test('読み取ってもアカウントは作られない', () {
      final auth = MockFirebaseAuth();
      createRepository(auth).getUser();
      expect(auth.currentUser, isNull);
    });
  });

  // 購読より前のユーザーも流れてくるため、変化そのものが届くことだけを見る
  // （本物の authStateChanges() も購読時に現在のユーザーを 1 度流す）
  group('起動後のユーザーの変化', () {
    test('ゲストになったことが流れてくる', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(isAnonymous: true, uid: 'guest-1'),
      );
      final repository = createRepository(auth);
      final emitted = expectLater(
        repository.watchUser(),
        emitsThrough(const Guest('guest-1')),
      );

      await repository.signInAsGuest();

      await emitted;
    });

    test('サインアウトしたことが流れてくる', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true, uid: 'guest-1'),
      );
      final repository = createRepository(auth);
      final emitted = expectLater(
        repository.watchUser(),
        emitsThrough(const NoLogin()),
      );

      await auth.signOut();

      await emitted;
    });
  });

  group('ゲストではじめる', () {
    test('ゲストが返る', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(isAnonymous: true, uid: 'guest-1'),
      );
      final repository = createRepository(auth);

      expect(await repository.signInAsGuest(), const Guest('guest-1'));
    });

    test('作ったゲストが以降のセッションになる', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(isAnonymous: true, uid: 'guest-1'),
      );
      final repository = createRepository(auth);

      await repository.signInAsGuest();

      expect(repository.getUser(), const Guest('guest-1'));
    });
  });
}
