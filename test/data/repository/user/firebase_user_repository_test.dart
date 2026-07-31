import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/credential_source.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/link_result.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

/// credential 取得を差し替える。`credential` が `null` なら中断を表す
class _FakeCredentialSource implements CredentialSource {
  _FakeCredentialSource({this.credential});

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
    CredentialSource? googleCredentialSource,
  }) => FirebaseUserRepository(
    auth: auth,
    googleCredentialSource:
        googleCredentialSource ??
        _FakeCredentialSource(
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
        googleCredentialSource: _FakeCredentialSource(),
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
        googleCredentialSource: _ThrowingCredentialSource(),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<SignInException>()),
      );
    });
  });

  group('ゲストから昇格する', () {
    // mock_exceptions の登録先は MockUser の値等価で引かれる。uid を使い回すと
    // 前のテストで仕込んだ例外が次のテストにも効いてしまうため、テストごとに変える
    MockFirebaseAuth signedInAsGuest(String uid) => MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(isAnonymous: true, uid: uid),
    );

    test('uid を保ったままリンク済みになる', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: _LinkableMockUser(uid: 'guest-1'),
      );

      final result = await createRepository(auth).linkWithGoogle();

      expect(result, isA<LinkSucceeded>());
      expect((result as LinkSucceeded).user, const LoggedIn('guest-1'));
    });

    test('ユーザーが中断したらリンクしない', () async {
      final auth = signedInAsGuest('guest-cancelled');
      final repository = createRepository(
        auth,
        googleCredentialSource: _FakeCredentialSource(),
      );

      expect(await repository.linkWithGoogle(), isA<LinkCancelled>());
    });

    test('サインインしていなければ SignInException が伝わる', () async {
      final repository = createRepository(MockFirebaseAuth());

      await expectLater(
        repository.linkWithGoogle(),
        throwsA(isA<SignInException>()),
      );
    });

    test('リンクに失敗したら例外が伝わる', () async {
      final auth = signedInAsGuest('guest-link-failed');
      whenCalling(Invocation.method(#linkWithCredential, [anything]))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'network-error'));
      final repository = createRepository(auth);

      await expectLater(
        repository.linkWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    group('アカウントが既に使われているとき', () {
      final linkedCredential = GoogleAuthProvider.credential(
        idToken: 'linked-id-token',
      );
      late MockFirebaseAuth auth;

      setUp(() {
        // MockFirebaseAuth はサインイン先を mockUser で表す。ここでは credential を
        // 既に持っているアカウントを置き、乗り換えるとそこに入ることを見る
        auth = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'linked-account-user'),
        );
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(
              FirebaseAuthException(
                code: 'credential-already-in-use',
                credential: linkedCredential,
              ),
            );
      });

      // ここでサインインするとゲストのデータを黙って捨てることになる
      test('サインインせず、乗り換えに使う credential を返す', () async {
        final result = await createRepository(auth).linkWithGoogle();

        expect(result, isA<LinkCredentialInUse>());
        expect((result as LinkCredentialInUse).credential, linkedCredential);
      });

      test('了承後に乗り換えるとリンク済みユーザーになる', () async {
        final repository = createRepository(auth);
        final result = await repository.linkWithGoogle() as LinkCredentialInUse;

        expect(
          await repository.signInWithLinkedCredential(result.credential),
          const LoggedIn('linked-account-user'),
        );
      });

      // 例外に credential が入っていないと乗り換え先が分からず、無言で失敗してしまう
      test('credential が付いていなければ SignInException が伝わる', () async {
        final auth = signedInAsGuest('guest-credential-missing');
        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(auth.currentUser!)
            .thenThrow(
              FirebaseAuthException(code: 'credential-already-in-use'),
            );
        final repository = createRepository(auth);

        await expectLater(
          repository.linkWithGoogle(),
          throwsA(isA<SignInException>()),
        );
      });
    });
  });
}

/// 匿名ユーザーのリンクを再現するための差し替え。
///
/// firebase_auth_mocks の `linkWithCredential` はリンク後も匿名のままだと決め打ちして
/// assert するため、そのままでは昇格の成功を確認できない
// MockUser 自身が可変フィールドを持つため、継承すると @immutable 違反になる
// ignore: must_be_immutable
class _LinkableMockUser extends MockUser {
  _LinkableMockUser({required String super.uid}) : super(isAnonymous: true);

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async =>
      _LinkedUserCredential(MockUser(uid: uid));
}

class _LinkedUserCredential implements UserCredential {
  _LinkedUserCredential(this.user);

  @override
  final User user;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}

/// credential 取得そのものが失敗する状況を作る
class _ThrowingCredentialSource implements CredentialSource {
  @override
  Future<AuthCredential?> getCredential() async =>
      throw const SignInException('google sign-in failed');
}
