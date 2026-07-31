import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/credential_source.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
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

      final result = await repository.signInWithGoogle();

      expect(result, isA<SignInSucceeded>());
      expect((result as SignInSucceeded).user, const LoggedIn('user-1'));
    });

    test('ユーザーが中断したらサインインしない', () async {
      final auth = MockFirebaseAuth();
      final repository = createRepository(
        auth,
        googleCredentialSource: _FakeCredentialSource(),
      );

      expect(await repository.signInWithGoogle(), isA<SignInCancelled>());
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

  group('ゲストのままサインインする', () {
    MockFirebaseAuth signedInAsGuest({FirebaseAuthException? linkError}) =>
        MockFirebaseAuth(
          signedIn: true,
          mockUser: _LinkableMockUser(uid: 'guest-1', linkError: linkError),
        );

    test('uid を保ったままリンク済みになる', () async {
      final result = await createRepository(
        signedInAsGuest(),
      ).signInWithGoogle();

      expect(result, isA<SignInSucceeded>());
      expect((result as SignInSucceeded).user, const LoggedIn('guest-1'));
    });

    test('ユーザーが中断したらリンクしない', () async {
      final repository = createRepository(
        signedInAsGuest(),
        googleCredentialSource: _FakeCredentialSource(),
      );

      expect(await repository.signInWithGoogle(), isA<SignInCancelled>());
    });

    // 匿名でないユーザーをリンクしようとすると provider-already-linked で失敗する
    test('リンク済みユーザーなら昇格させず、サインインし直す', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-1'),
      );
      whenCalling(Invocation.method(#linkWithCredential, [anything]))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'provider-already-linked'));

      final result = await createRepository(auth).signInWithGoogle();

      expect(result, isA<SignInSucceeded>());
      expect((result as SignInSucceeded).user, const LoggedIn('user-1'));
    });

    test('リンクに失敗したら例外が伝わる', () async {
      final auth = signedInAsGuest(
        linkError: FirebaseAuthException(code: 'network-error'),
      );

      await expectLater(
        createRepository(auth).signInWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    group('アカウントが既に使われているとき', () {
      final linkedCredential = GoogleAuthProvider.credential(
        idToken: 'linked-id-token',
      );
      late MockFirebaseAuth auth;

      setUp(() {
        auth = signedInAsGuest(
          linkError: FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: linkedCredential,
          ),
        );
      });

      // ここでサインインするとゲストのデータを黙って捨てることになる
      test('サインインせず、乗り換えに使う credential を返す', () async {
        final result = await createRepository(auth).signInWithGoogle();

        expect(result, isA<SignInCredentialInUse>());
        expect((result as SignInCredentialInUse).credential, linkedCredential);
        expect(auth.currentUser?.uid, 'guest-1');
      });

      test('了承後に乗り換えるとリンク済みユーザーになる', () async {
        final repository = createRepository(auth);
        final result =
            await repository.signInWithGoogle() as SignInCredentialInUse;
        // MockFirebaseAuth はサインイン先を mockUser で表す。
        // credential を既に持っているアカウントに差し替えて乗り換えを再現する
        auth.mockUser = MockUser(uid: 'linked-account-user');

        expect(
          await repository.signInWithLinkedCredential(result.credential),
          const LoggedIn('linked-account-user'),
        );
      });

      // 例外に credential が入っていないと乗り換え先が分からず、無言で失敗してしまう
      test('credential が付いていなければ SignInException が伝わる', () async {
        final auth = signedInAsGuest(
          linkError: FirebaseAuthException(code: 'credential-already-in-use'),
        );

        await expectLater(
          createRepository(auth).signInWithGoogle(),
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
  _LinkableMockUser({required String super.uid, this.linkError})
    : super(isAnonymous: true);

  /// リンクが失敗する状況を作る
  final FirebaseAuthException? linkError;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final error = linkError;
    if (error != null) throw error;
    return _LinkedUserCredential(MockUser(uid: uid));
  }
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
