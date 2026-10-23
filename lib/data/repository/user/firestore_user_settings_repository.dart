import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/session_guard.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_user_settings_repository.g.dart';

@Riverpod(keepAlive: true)
Future<UserSettingsRepository> userSettingsRepository(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final timeZone = await FlutterTimezone.getLocalTimezone();
  if (userId == null) {
    throw const UserSettingsNotSignedInException(
      'a signed-out user has no notification setting',
    );
  }
  return FirestoreUserSettingsRepository(
    userId: userId,
    firestore: FirebaseFirestore.instance,
    timezone: timeZone.identifier,
    sessionGuard: ref.watch(sessionGuardProvider),
  );
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
    required this._sessionGuard,
  });

  final String userId;

  /// `notificationSetting` の hour / minute を解釈する IANA タイムゾーン ID。
  /// 1 ユーザー 1 タイムゾーンとし、起動やレジュームごとの追随はしない
  final String timezone;

  final FirebaseFirestore _firestore;
  final SessionGuard _sessionGuard;

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
    _ensureSession();
    try {
      await _userRef().set({
        'notificationSetting': setting.toJson(),
        'timezone': timezone,
      }, SetOptions(merge: true));
    } catch (e) {
      throw _sessionExpiredOr(UserSettingsSaveException(e.toString()));
    }
  }

  /// `merge: true` はネストしたマップを再帰的にマージするため、`enabled` だけを
  /// 送れば時刻・日はサーバーにある値が残る
  @override
  Future<void> setNotificationEnabled(bool enabled) async {
    _ensureSession();
    try {
      await _userRef().set({
        'notificationSetting': {'enabled': enabled},
        'timezone': timezone,
      }, SetOptions(merge: true));
    } catch (e) {
      throw _sessionExpiredOr(UserSettingsSaveException(e.toString()));
    }
  }

  /// 書く前にセッションを確かめる。セッションのない書き込みは完了を待ち続けるため、通信の前に弾く
  void _ensureSession() {
    if (!_sessionGuard.checkExpired()) return;
    throw const UserSettingsSessionExpiredException(
      'cannot write user settings: the session has expired',
    );
  }

  /// 書き込みの失敗が、途中でセッションが切れたことによるものならその例外に置き換える
  UserSettingsRepositoryException _sessionExpiredOr(
    UserSettingsRepositoryException exception,
  ) => _sessionGuard.checkExpired()
      ? UserSettingsSessionExpiredException(exception.message)
      : exception;

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
