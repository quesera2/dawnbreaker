import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting.freezed.dart';

enum NotifyDay {
  today,
  yesterday;

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

  String encode() => jsonEncode({
    'enabled': enabled,
    'notifyDay': notifyDay.name,
    'hour': hour,
    'minute': minute,
  });

  static NotificationSetting decode(String encoded) {
    try {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      return NotificationSetting(
        enabled: map['enabled'] as bool? ?? false,
        notifyDay: NotifyDay.values.byName(
          map['notifyDay'] as String? ?? NotifyDay.today.name,
        ),
        hour: map['hour'] as int? ?? 9,
        minute: map['minute'] as int? ?? 0,
      );
    } catch (_) {
      return const NotificationSetting();
    }
  }
}
