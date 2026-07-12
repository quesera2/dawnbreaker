import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_user_settings_repository.g.dart';

@Riverpod(keepAlive: true)
Future<UserSettingsRepository> userSettingsRepository(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final timeZone = await FlutterTimezone.getLocalTimezone();
  return switch (user) {
    // LocalUser を作る経路は残っておらず、Phase8 で型ごと削除する。
    // 通知設定は Firestore にしか置き場がないため、握り潰さず落とす
    LocalUser() => throw UnsupportedError('LocalUser は通知設定を持たない'),
    FirebaseAppUser(:final id) => FirestoreUserSettingsRepository(
      userId: id,
      firestore: FirebaseFirestore.instance,
      timezone: timeZone.identifier,
    ),
  };
}

@Riverpod(keepAlive: true)
Stream<NotificationSetting> notificationSetting(Ref ref) async* {
  final repository = await ref.watch(userSettingsRepositoryProvider.future);
  yield* repository.watchNotificationSetting();
}

class FirestoreUserSettingsRepository implements UserSettingsRepository {
  FirestoreUserSettingsRepository({
    required this.userId,
    required this.timezone,
    required this._firestore,
  });

  final String userId;

  /// `notificationSetting` の hour / minute を解釈する IANA タイムゾーン ID。
  /// 1 ユーザー 1 タイムゾーンとし、起動やレジュームごとの追随はしない
  final String timezone;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef() =>
      _firestore.collection('users').doc(userId);

  @override
  Stream<NotificationSetting> watchNotificationSetting() =>
      _userRef().snapshots().map((snapshot) {
        final setting = snapshot.data()?['notificationSetting'] as Map?;
        return NotificationSetting.fromMap(
          setting == null ? null : Map<String, dynamic>.from(setting),
        );
      });

  @override
  Future<void> setNotificationSetting(NotificationSetting setting) =>
      _userRef().set({
        'notificationSetting': setting.toJson(),
        'timezone': timezone,
      }, SetOptions(merge: true));

  @override
  Future<void> updateLastActiveAt() => _userRef().set({
    'lastActiveAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
