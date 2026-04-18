// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Dawnbreaker';

  @override
  String get homeSearchHint => 'Search tasks';

  @override
  String get homeNoTasksYet => 'No tasks yet';

  @override
  String get homeNoTasksFound => 'No matching tasks found';

  @override
  String get homeReRegister => 'Re-register';

  @override
  String homeDaysOverdue(int days) {
    return '${days}d overdue';
  }

  @override
  String homeDaysRemaining(int days) {
    return '${days}d remaining';
  }
}
