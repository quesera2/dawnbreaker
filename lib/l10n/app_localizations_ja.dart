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

  @override
  String get taskErrorLoadFailed => '読み込みに失敗しました';

  @override
  String get taskErrorNotFound => 'タスクが見つかりません';

  @override
  String get taskErrorSaveFailed => '保存に失敗しました';

  @override
  String get taskErrorUpdateFailed => '更新に失敗しました';

  @override
  String get taskErrorDeleteFailed => '削除に失敗しました';

  @override
  String get taskErrorInvalidArgument => '入力内容が正しくありません';

  @override
  String get errorTitle => 'エラー';

  @override
  String get errorUnknown => '予期しないエラーが発生しました';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get retry => '再試行';
}
