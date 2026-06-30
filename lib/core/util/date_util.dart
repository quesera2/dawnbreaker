// coverage:ignore-file

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

int compareNullableDateAsc(DateTime? a, DateTime? b) {
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

extension DateTimeUtil on DateTime {
  DateTime get truncateTime => DateTime.utc(year, month, day);

  /// "2024年1月1日(月)" のように曜日つきでフォーマット
  String localizedWithWeekday(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).format(this);
  }

  /// "2024年1月1日" のように日付のみフォーマット
  String localized(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(this);
  }
}
