import 'package:dawnbreaker/data/model/notification_setting.dart';

/// `users/{userId}` が持つ、アカウントに紐づく設定。
///
/// 通知の送信主体が Cloud Functions になるため、通知設定は端末ローカルではなく
/// Firestore に置く。配色・表示モードなど端末固有の設定は SharedPreferences に残る。
abstract interface class UserSettingsRepository {
  Stream<NotificationSetting> watchNotificationSetting();

  Future<void> setNotificationSetting(NotificationSetting setting);

  /// 放置アカウントの回収で使う最終アクティブ日時を更新する。
  Future<void> updateLastActiveAt();
}
