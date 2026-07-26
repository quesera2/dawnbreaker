import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/google_credential_source.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

/// Google の credential 取得を差し替える。`credential` が `null` なら中断を表す
class _FakeGoogleCredentialSource implements GoogleCredentialSource {
  _FakeGoogleCredentialSource({this.credential});

  final AuthCredential? credential;
  int getCredentialCount = 0;

  @override
  Future<AuthCredential?> getCredential() async {
    getCredentialCount++;
    return credential;
  }
}

void main() {
  FirebaseUserRepository createRepository(
    MockFirebaseAuth auth, {
    GoogleCredentialSource? googleCredentialSource,
  }) => FirebaseUserRepository(
    auth: auth,
    googleCredentialSource:
        googleCredentialSource ??
        _FakeGoogleCredentialSource(
          credential: GoogleAuthProvider.credential(idToken: 'id-token'),
        ),
  );

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

  group('Google でサインイン', () {
    test('リンク済みユーザーが返る', () async {
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'user-1'));
      final repository = createRepository(auth);

      expect(await repository.signInWithGoogle(), const LoggedIn('user-1'));
    });

    test('ユーザーが中断したら null を返し、サインインしない', () async {
      final auth = MockFirebaseAuth();
      final repository = createRepository(
        auth,
        googleCredentialSource: _FakeGoogleCredentialSource(),
      );

      expect(await repository.signInWithGoogle(), isNull);
      expect(auth.currentUser, isNull);
    });

    test('サインインに失敗したら例外が伝わる', () async {
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'user-1'));
      whenCalling(
        Invocation.method(#signInWithCredential, [anything]),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'network-error'));
      final repository = createRepository(auth);

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('credential 取得が失敗したら SignInException が伝わる', () async {
      final auth = MockFirebaseAuth();
      final repository = createRepository(
        auth,
        googleCredentialSource: _ThrowingGoogleCredentialSource(),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<SignInException>()),
      );
    });
  });
}

/// credential 取得そのものが失敗する状況を作る
class _ThrowingGoogleCredentialSource implements GoogleCredentialSource {
  @override
  Future<AuthCredential?> getCredential() async =>
      throw const SignInException('google sign-in failed');
}
