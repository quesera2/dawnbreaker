// coverage:ignore-file

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

extension DateTimeUtil on DateTime {
  DateTime get truncateTime => DateTime(year, month, day);

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
