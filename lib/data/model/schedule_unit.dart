import 'package:dawnbreaker/core/context_extension.dart';
import 'package:flutter/widgets.dart';

enum ScheduleUnit {
  day,
  week,
  month;

  /// [value] 日後の DateTime を返す
  DateTime addTo(DateTime base, int value) => switch (this) {
    ScheduleUnit.day => base.add(Duration(days: value)),
    ScheduleUnit.week => base.add(Duration(days: value * 7)),
    ScheduleUnit.month => DateTime(
      base.year,
      base.month + value,
      base.day,
      base.hour,
      base.minute,
      base.second,
    ),
  };

  String label(BuildContext context) => switch (this) {
    ScheduleUnit.day => context.l10n.commonUnitDay,
    ScheduleUnit.week => context.l10n.commonUnitWeek,
    ScheduleUnit.month => context.l10n.commonUnitMonth,
  };
}
