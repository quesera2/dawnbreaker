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
  String get homeFilterAll => 'すべて';

  @override
  String get homeFilterOverdue => '超過';

  @override
  String get homeFilterToday => '今日';

  @override
  String get homeFilterWeek => '今週';

  @override
  String get homeFilterIrregular => '不定期';

  @override
  String get homeSectionOverdue => '超過';

  @override
  String get homeSectionUpcoming => '今後の予定';

  @override
  String get homeComplete => '完了';

  @override
  String get homeCompleteSheetTitle => 'タスクを完了';

  @override
  String get homeCompleteRecord => '完了を記録';

  @override
  String get homeCompleteCommentPlaceholder => 'コメントを入力（任意）';

  @override
  String homeCompleteSuccess(String name) {
    return '「$name」の完了を記録しました';
  }

  @override
  String get homeDueToday => '今日';

  @override
  String get homeAddTask => 'タスクを追加';

  @override
  String get homeSettings => '設定';

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

  @override
  String get undo => '取り消し';

  @override
  String get editorTitleNew => '新規タスクを追加';

  @override
  String get editorTitleEdit => 'タスクを編集';

  @override
  String get editorSectionBasic => '基本情報';

  @override
  String get editorLabelName => 'タスク名';

  @override
  String get editorLabelType => 'タスク種別';

  @override
  String get editorLabelColor => 'カラー';

  @override
  String get editorLabelSpan => '実行スパン';

  @override
  String get editorLabelIcon => 'アイコン';

  @override
  String get editorChangeIcon => 'アイコンを変更';

  @override
  String get editorTypeIrregular => '予定日を表示しない';

  @override
  String get editorTypeIrregularDesc => '不定期に実行するタスク';

  @override
  String get editorTypePeriod => '自動的に周期を判定';

  @override
  String get editorTypePeriodDesc => '実行履歴から次回予定日を予測';

  @override
  String get editorTypeScheduled => '周期を指定';

  @override
  String get editorTypeScheduledDesc => '次回予定日までの間隔を手動で設定';

  @override
  String get editorSpanPickerTitle => '繰り返し間隔';

  @override
  String get editorSpanDay => '日';

  @override
  String get editorSpanWeek => '週';

  @override
  String get editorSpanMonth => 'ヶ月';

  @override
  String editorSpanLabel(String value, String unit) {
    return '$value$unitごと';
  }

  @override
  String get editorSaveNew => '登録する';

  @override
  String get editorSaveEdit => '更新する';

  @override
  String editorSaveNewSuccess(String name) {
    return '「$name」を登録しました';
  }

  @override
  String editorSaveEditSuccess(String name) {
    return '「$name」を更新しました';
  }

  @override
  String get editorIconDialogTitle => 'アイコンを選択';

  @override
  String get editorColorNone => 'なし';

  @override
  String get editorColorNote => '色でタスクをグループ分けできます';

  @override
  String get editorNameHint => 'タスク名を入力';

  @override
  String get appDetailTitle => '実行履歴';

  @override
  String get appDetailEdit => '編集';

  @override
  String appDetailDeleteSuccess(String name) {
    return '「$name」を削除しました';
  }

  @override
  String get appDetailStatsDaysSince => '前回から';

  @override
  String get appDetailStatsAvgInterval => '平均間隔';

  @override
  String get appDetailStatsDay => '日';

  @override
  String get appDetailHistorySection => '履歴';

  @override
  String appDetailDaysInterval(int days) {
    return '前回から$days日';
  }

  @override
  String get appDetailTypeBadgeIrregular => '不定期';

  @override
  String get appDetailTypeBadgePeriod => '自動周期';

  @override
  String appDetailTypeBadgeScheduled(int value, String unit) {
    return '定期 $value$unit';
  }
}
