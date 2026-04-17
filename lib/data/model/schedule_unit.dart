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
}
