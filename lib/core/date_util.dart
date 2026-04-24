import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static String format(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).format(date);
  }
}

extension DateTimeUtil on DateTime {
  DateTime get truncateTime => DateTime(year, month, day);
}
