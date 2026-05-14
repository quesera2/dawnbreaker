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
  String get homeBarAdd => '追加';

  @override
  String get homeBarSettings => '設定';

  @override
  String get homeSearchHint => 'タスクを検索';

  @override
  String get homeNoTasksYet => 'タスクがまだありません';

  @override
  String get homeNoTasksFound => '一致するタスクが見つかりません';

  @override
  String get homeFilterAll => 'すべて';

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
  String get homeCompleteDateLabel => '完了日';

  @override
  String get homeCompleteCommentLabel => 'コメント';

  @override
  String get homeCompleteCommentPlaceholder => 'コメントを入力（任意）';

  @override
  String homeCompleteSuccess(String name) {
    return '「$name」の完了を記録しました';
  }

  @override
  String get commonToday => '今日';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonUndo => '取り消し';

  @override
  String get commonDelete => '削除';

  @override
  String get commonConfirmTitle => '確認';

  @override
  String get commonErrorTitle => 'エラー';

  @override
  String get commonErrorUnknown => '予期しないエラーが発生しました';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonUnitDay => '日';

  @override
  String get commonUnitWeek => '週';

  @override
  String get commonUnitMonth => 'ヶ月';

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
  String get taskErrorSaveFailed => '保存に失敗しました';

  @override
  String get taskErrorUpdateFailed => '更新に失敗しました';

  @override
  String get taskErrorDeleteFailed => '削除に失敗しました';

  @override
  String get taskErrorInvalidArgument => '入力内容が正しくありません';

  @override
  String get onboardingErrorSaveFailed => '設定の保存に失敗しました';

  @override
  String get editorTitleNew => '新規タスクを追加';

  @override
  String get editorTitleEdit => 'タスクを編集';

  @override
  String get editorSectionBasic => '基本情報';

  @override
  String get editorLabelType => 'タスク種別';

  @override
  String get editorLabelColor => 'カラー';

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
  String get editorColorNote => '色でタスクをグループ分けできます';

  @override
  String get editorNameHint => 'タスク名を入力';

  @override
  String get appDetailTitle => 'タスク詳細';

  @override
  String get appDetailEdit => '編集';

  @override
  String get appDetailDelete => '削除';

  @override
  String appDetailDeleteSuccess(String name) {
    return '「$name」を削除しました';
  }

  @override
  String get appDetailStatsDaysSince => '前回から';

  @override
  String get appDetailStatsAvgInterval => '平均間隔';

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

  @override
  String get appDetailRecordCompletion => 'タスクの完了を登録する';

  @override
  String get appDetailUpdateHistorySuccess => '履歴を更新しました';

  @override
  String appDetailTaskDeleteConfirm(String name) {
    return 'タスク「$name」を削除しますか？';
  }

  @override
  String appDetailDeleteHistorySuccess(String taskName, String date) {
    return '「$taskName」の$dateの記録を削除しました';
  }

  @override
  String get appDetailDeleteHistoryFailed => '記録を削除できませんでした';

  @override
  String get appDetailDeleteHistoryButton => '長押しで削除';

  @override
  String get appDetailNoHistory => 'まだ履歴がありません';

  @override
  String get onboardingPage1Title => 'いつやるんだっけ？　の悩みをなくす';

  @override
  String get onboardingPage1Body =>
      'オイル交換、フィルター掃除、歯ブラシ交換……いつやるか忘れがちなことを登録しておくだけです。';

  @override
  String get onboardingPage2Title => '次はいつごろだっけ？　の悩みをなくす';

  @override
  String get onboardingPage2Body => '過去の登録から間隔を算出して、どのくらいの頻度でやっているのかを可視化します。';

  @override
  String get onboardingPage4Title => '色でまとめると、見つけやすくなります';

  @override
  String get onboardingPage4Body => 'カテゴリや場所などでタスクを色分けできます。一覧がひと目でわかりやすくなります。';

  @override
  String get onboardingColorRed => 'キッチン';

  @override
  String get onboardingColorBlue => '家電';

  @override
  String get onboardingColorGreen => '植物';

  @override
  String get onboardingColorOrange => 'ベランダ';

  @override
  String get onboardingColorYellow => '消耗品';

  @override
  String get onboardingColorNone => '車両';

  @override
  String get onboardingDemoTask1 => 'ベランダの虫除け';

  @override
  String get onboardingDemoTask2 => 'オイル交換';

  @override
  String get onboardingDemoTask3 => '歯ブラシ交換';

  @override
  String get onboardingDemoTask4 => 'お風呂の防カビ剤';

  @override
  String get onboardingDemoTask5 => 'スニーカーの洗濯';

  @override
  String get onboardingPage3Title => '通知でタイムリーに気づく';

  @override
  String get onboardingPage3Body => 'スケジュールのタイミングで通知を受け取れます。';

  @override
  String get onboardingEnableNotification => '通知をONにする';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingStart => '最初のタスクを登録する';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionNotification => '通知';

  @override
  String get settingsNotificationTitle => '予定日に通知';

  @override
  String get settingsNotificationSubtitle => '朝 9:00 に通知が届きます';

  @override
  String get settingsSectionInfo => '情報';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsTutorial => 'チュートリアル';

  @override
  String get settingsLicense => 'オープンソースライセンス';

  @override
  String get settingsSectionDebug => 'デバッグ';

  @override
  String get settingsDebugGenerateDummyTasks => 'ダミータスクを生成';

  @override
  String get settingsDebugDummyTasksGenerated => 'ダミータスクを生成しました';

  @override
  String get settingsDebugDeleteAllTasks => 'すべてのタスクを削除';

  @override
  String get settingsDebugAllTasksDeleted => 'すべてのタスクを削除しました';

  @override
  String get settingsDebugResetTutorialFlag => 'チュートリアルフラグをリセット';

  @override
  String get settingsDebugTutorialFlagReset => 'チュートリアルフラグをリセットしました';

  @override
  String get notificationGroupTask => 'タスク通知';

  @override
  String get notificationChannelTask => '個別タスク通知';

  @override
  String get notificationTaskBody => '予定日になりました';
}
