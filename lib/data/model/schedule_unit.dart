import 'package:dawnbreaker/generated/l10n.dart';
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
    ScheduleUnit.day => S.of(context).commonUnitDay,
    ScheduleUnit.week => S.of(context).commonUnitWeek,
    ScheduleUnit.month => S.of(context).commonUnitMonth,
  };
}
