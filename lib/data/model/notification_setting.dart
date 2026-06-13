import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting.freezed.dart';

@freezed
abstract class NotificationSetting with _$NotificationSetting {
  const NotificationSetting._();

  const factory NotificationSetting({
    @Default(false) bool enabled,
    // 0=当日, -1=前日
    @Default(0) int dayOffset,
    @Default(9) int hour,
    @Default(0) int minute,
  }) = _NotificationSetting;

  static final _pattern = RegExp(r'^(true|false):(-?\d+):(\d+):(\d+)$');

  String encode() => '$enabled:$dayOffset:$hour:$minute';

  static NotificationSetting decode(String encoded) {
    final match = _pattern.firstMatch(encoded);
    if (match == null) return const NotificationSetting();
    return NotificationSetting(
      enabled: match.group(1) == 'true',
      dayOffset: int.parse(match.group(2)!),
      hour: int.parse(match.group(3)!),
      minute: int.parse(match.group(4)!),
    );
  }
}
