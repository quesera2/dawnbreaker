import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_user_settings_repository.g.dart';

@Riverpod(keepAlive: true)
Future<UserSettingsRepository> userSettingsRepository(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  final timeZone = await FlutterTimezone.getLocalTimezone();
  return switch (user) {
    NoLogin() => throw const UserSettingsNotSignedInException(
      'a signed-out user has no notification setting',
    ),
    SignedInUser(:final id) => FirestoreUserSettingsRepository(
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

  @override
  Stream<NotificationSetting> watchNotificationSetting() => _userRef()
      .snapshots()
      .map(_toNotificationSetting)
      .handleError((Object e) => throw UserSettingsLoadException(e.toString()));

  @override
  Future<NotificationSetting> fetchNotificationSetting() async {
    try {
      return _toNotificationSetting(await _userRef().get());
    } catch (e) {
      throw UserSettingsLoadException(e.toString());
    }
  }

  @override
  Future<void> setNotificationSetting(NotificationSetting setting) async {
    try {
      await _userRef().set({
        'notificationSetting': setting.toJson(),
        'timezone': timezone,
      }, SetOptions(merge: true));
    } catch (e) {
      throw UserSettingsSaveException(e.toString());
    }
  }

  @override
  Future<void> updateLastActiveAt() async {
    try {
      await _userRef().set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw UserSettingsSaveException(e.toString());
    }
  }

  /// `users/{uid}` は初期化していないため、ドキュメントごと無いことがある。
  /// その場合は初期値（通知 OFF）として扱う
  NotificationSetting _toNotificationSetting(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final setting = snapshot.data()?['notificationSetting'] as Map?;
    return NotificationSetting.fromMap(
      setting == null ? null : Map<String, dynamic>.from(setting),
    );
  }

  DocumentReference<Map<String, dynamic>> _userRef() =>
      _firestore.collection('users').doc(userId);
}
