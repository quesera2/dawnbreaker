import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = 'test-user';
  const timezone = 'Asia/Tokyo';

  late FakeFirebaseFirestore firestore;
  late UserSettingsRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreUserSettingsRepository(
      userId: userId,
      timezone: timezone,
      firestore: firestore,
    );
  });

  Future<Map<String, dynamic>?> fetchUser() async {
    final snapshot = await firestore.collection('users').doc(userId).get();
    return snapshot.data();
  }

  group('watchNotificationSetting', () {
    test('設定がまだない場合は通知しない設定が流れる', () async {
      final setting = await repository.watchNotificationSetting().first;
      expect(setting.enabled, false);
    });

    test('保存済みの設定が流れる', () async {
      const saved = NotificationSetting(
        enabled: true,
        notifyDay: NotifyDay.yesterday,
        hour: 20,
        minute: 30,
      );
      await repository.setNotificationSetting(saved);

      final setting = await repository.watchNotificationSetting().first;
      expect(setting, saved);
    });

    test('設定を変更すると新しい値が流れる', () async {
      final expectation = expectLater(
        repository.watchNotificationSetting().map((s) => s.enabled),
        emitsInOrder([false, true]),
      );
      await pumpEventQueue();

      await repository.setNotificationSetting(
        const NotificationSetting(enabled: true),
      );
      await expectation;
    });
  });

  group('fetchNotificationSetting', () {
    test('設定がまだない場合は通知しない設定を返す', () async {
      final setting = await repository.fetchNotificationSetting();
      expect(setting.enabled, false);
    });

    test('保存済みの設定を返す', () async {
      const saved = NotificationSetting(
        enabled: true,
        notifyDay: NotifyDay.yesterday,
        hour: 20,
        minute: 30,
      );
      await repository.setNotificationSetting(saved);

      expect(await repository.fetchNotificationSetting(), saved);
    });
  });

  group('setNotificationSetting', () {
    test('通知時刻を書き換えるとタイムゾーンも一緒に保存される', () async {
      await repository.setNotificationSetting(
        const NotificationSetting(enabled: true, hour: 7),
      );
      expect((await fetchUser())?['timezone'], timezone);
    });

    test('ユーザーの他のフィールドを消さない', () async {
      await firestore.collection('users').doc(userId).set({
        'fcmTokens': ['token-a'],
      });
      await repository.setNotificationSetting(
        const NotificationSetting(enabled: true),
      );
      expect((await fetchUser())?['fcmTokens'], ['token-a']);
    });
  });

  group('setNotificationEnabled', () {
    test('設定済みの通知時刻を残したまま書き換える', () async {
      await repository.setNotificationSetting(
        const NotificationSetting(
          notifyDay: NotifyDay.yesterday,
          hour: 20,
          minute: 30,
        ),
      );

      await repository.setNotificationEnabled(true);

      expect(
        await repository.fetchNotificationSetting(),
        const NotificationSetting(
          enabled: true,
          notifyDay: NotifyDay.yesterday,
          hour: 20,
          minute: 30,
        ),
      );
    });

    test('設定がまだなくても書ける', () async {
      await repository.setNotificationEnabled(true);

      expect((await repository.fetchNotificationSetting()).enabled, true);
    });

    test('タイムゾーンも一緒に保存される', () async {
      await repository.setNotificationEnabled(true);
      expect((await fetchUser())?['timezone'], timezone);
    });

    test('ユーザーの他のフィールドを消さない', () async {
      await firestore.collection('users').doc(userId).set({
        'fcmTokens': ['token-a'],
      });
      await repository.setNotificationEnabled(true);
      expect((await fetchUser())?['fcmTokens'], ['token-a']);
    });
  });

  group('updateLastActiveAt', () {
    test('最終アクティブ日時が記録される', () async {
      await repository.updateLastActiveAt();
      expect((await fetchUser())?['lastActiveAt'], isA<Timestamp>());
    });

    test('ユーザーの他のフィールドを消さない', () async {
      await repository.setNotificationSetting(
        const NotificationSetting(enabled: true),
      );
      await repository.updateLastActiveAt();

      final user = await fetchUser();
      expect(user?['timezone'], timezone);
      expect((user?['notificationSetting'] as Map)['enabled'], true);
    });
  });
}
