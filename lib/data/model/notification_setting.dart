import 'dart:convert';

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

  static NotificationSetting decode(String encoded) {
    try {
      return NotificationSetting.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } catch (_) {
      return const NotificationSetting();
    }
  }
}
