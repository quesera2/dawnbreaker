import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:flutter/widgets.dart';

enum ScheduleUnit {
  day,
  week,
  month;

  /// [value] 日後の DateTime を返す
  DateTime addTo(DateTime base, int value) => switch (this) {
    .day => base.add(Duration(days: value)),
    .week => base.add(Duration(days: value * 7)),
    .month => DateTime(
      base.year,
      base.month + value,
      base.day,
      base.hour,
      base.minute,
      base.second,
    ),
  };

  // coverage:ignore-start
  String label(BuildContext context) => switch (this) {
    .day => context.l10n.commonUnitDay,
    .week => context.l10n.commonUnitWeek,
    .month => context.l10n.commonUnitMonth,
  };
  // coverage:ignore-end
}
