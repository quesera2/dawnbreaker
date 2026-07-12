import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting.freezed.dart';
part 'notification_setting.g.dart';

@JsonEnum()
enum NotifyDay {
  yesterday,
  today;

  int get dayOffset => switch (this) {
    .today => 0,
    .yesterday => -1,
  };
}

@freezed
abstract class NotificationSetting with _$NotificationSetting {
  const NotificationSetting._();

  const factory NotificationSetting({
    @Default(false) bool enabled,
    @Default(NotifyDay.today) NotifyDay notifyDay,
    @Default(9) int hour,
    @Default(0) int minute,
  }) = _NotificationSetting;

  factory NotificationSetting.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingFromJson(json);

  /// Firestore の `users/{userId}.notificationSetting` から読む。
  ///
  /// 未設定・欠けたフィールド・範囲外の値を含む場合はデフォルト値（通知しない）を返す。
  /// サーバー側のデータが壊れていても画面が落ちないようにするため。
  static NotificationSetting fromMap(Map<String, dynamic>? data) {
    if (data == null) return const NotificationSetting();

    try {
      final setting = NotificationSetting.fromJson(data);
      return setting.copyWith(
        hour: setting.hour.clamp(0, 23),
        minute: setting.minute.clamp(0, 59),
      );
    } catch (e, s) {
      logger.w('NotificationSetting.fromMap failed', error: e, stackTrace: s);
      return const NotificationSetting();
    }
  }
}
