import 'package:dawnbreaker/data/repository/user/firestore_notification_token_repository.dart';
import 'package:dawnbreaker/data/repository/user/notification_token_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = 'test-user';

  late FakeFirebaseFirestore firestore;
  late NotificationTokenRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreNotificationTokenRepository(
      userId: userId,
      firestore: firestore,
    );
  });

  Future<List<String>> fetchTokens() async {
    final snapshot = await firestore.collection('users').doc(userId).get();
    final tokens = snapshot.data()?['fcmTokens'] as List<dynamic>?;
    return tokens?.cast<String>() ?? [];
  }

  group('addToken', () {
    test('ユーザーのドキュメントがなくてもトークンを登録できる', () async {
      await repository.addToken('token-a');
      expect(await fetchTokens(), ['token-a']);
    });

    test('複数の端末のトークンを並べて持てる', () async {
      await repository.addToken('token-a');
      await repository.addToken('token-b');
      expect(await fetchTokens(), ['token-a', 'token-b']);
    });

    test('同じトークンを登録し直しても重複しない', () async {
      await repository.addToken('token-a');
      await repository.addToken('token-a');
      expect(await fetchTokens(), ['token-a']);
    });

    test('ユーザーの他のフィールドを消さない', () async {
      await firestore.collection('users').doc(userId).set({
        'timezone': 'Asia/Tokyo',
      });
      await repository.addToken('token-a');

      final snapshot = await firestore.collection('users').doc(userId).get();
      expect(snapshot.data()?['timezone'], 'Asia/Tokyo');
      expect(await fetchTokens(), ['token-a']);
    });
  });

  group('removeToken', () {
    setUp(() async {
      await repository.addToken('token-a');
      await repository.addToken('token-b');
    });

    test('指定したトークンだけ取り除かれる', () async {
      await repository.removeToken('token-a');
      expect(await fetchTokens(), ['token-b']);
    });

    test('登録されていないトークンを指定しても何も変わらない', () async {
      await repository.removeToken('token-c');
      expect(await fetchTokens(), ['token-a', 'token-b']);
    });
  });
}
