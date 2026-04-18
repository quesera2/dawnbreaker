// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get title => 'Dawnbreaker';

  @override
  String get homeSearchHint => 'タスクを検索';

  @override
  String get homeNoTasksYet => 'タスクがまだありません';

  @override
  String get homeNoTasksFound => '一致するタスクが見つかりません';

  @override
  String get homeReRegister => '再登録';

  @override
  String homeDaysOverdue(int days) {
    return '$days日超過';
  }

  @override
  String homeDaysRemaining(int days) {
    return '残り$days日';
  }
}
