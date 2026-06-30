import 'dart:convert';

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

  String encode() => jsonEncode(toJson());

  /// [encoded] が空文字・不正な JSON・範囲外の値を含む場合はデフォルト値を返す。
  static NotificationSetting decode(String encoded) {
    // 何も保存されていない場合、初期設定を返す
    if (encoded.isEmpty) {
      return const NotificationSetting();
    }

    try {
      final setting = NotificationSetting.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      return setting.copyWith(
        hour: setting.hour.clamp(0, 23),
        minute: setting.minute.clamp(0, 59),
      );
    } catch (e, s) {
      logger.w('NotificationSetting.decode failed', error: e, stackTrace: s);
      return const NotificationSetting();
    }
  }
}
