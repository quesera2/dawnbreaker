// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(days) => "前回から${days}日";

  static String m1(name) => "「${name}」を削除しました";

  static String m2(name) => "タスク「${name}」を削除しますか？";

  static String m3(value, unit) => "定期 ${value}${unit}";

  static String m4(name) => "「${name}」を更新しました";

  static String m5(name) => "「${name}」を登録しました";

  static String m6(value, unit) => "${value}${unit}ごと";

  static String m7(name) => "「${name}」の完了を記録しました";

  static String m8(days) => "${days}日超過";

  static String m9(days) => "残り${days}日";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appDetailDaysInterval": m0,
    "appDetailDelete": MessageLookupByLibrary.simpleMessage("削除"),
    "appDetailDeleteSuccess": m1,
    "appDetailEdit": MessageLookupByLibrary.simpleMessage("編集"),
    "appDetailHistorySection": MessageLookupByLibrary.simpleMessage("履歴"),
    "appDetailStatsAvgInterval": MessageLookupByLibrary.simpleMessage("平均間隔"),
    "appDetailStatsDaysSince": MessageLookupByLibrary.simpleMessage("前回から"),
    "appDetailTaskDeleteConfirm": m2,
    "appDetailTitle": MessageLookupByLibrary.simpleMessage("タスク詳細"),
    "appDetailTypeBadgeIrregular": MessageLookupByLibrary.simpleMessage("不定期"),
    "appDetailTypeBadgePeriod": MessageLookupByLibrary.simpleMessage("自動周期"),
    "appDetailTypeBadgeScheduled": m3,
    "appDetailUpdateHistorySuccess": MessageLookupByLibrary.simpleMessage(
      "履歴を更新しました",
    ),
    "commonCancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "commonClose": MessageLookupByLibrary.simpleMessage("閉じる"),
    "commonConfirmTitle": MessageLookupByLibrary.simpleMessage("確認"),
    "commonDelete": MessageLookupByLibrary.simpleMessage("削除"),
    "commonErrorTitle": MessageLookupByLibrary.simpleMessage("エラー"),
    "commonErrorUnknown": MessageLookupByLibrary.simpleMessage(
      "予期しないエラーが発生しました",
    ),
    "commonOk": MessageLookupByLibrary.simpleMessage("OK"),
    "commonRetry": MessageLookupByLibrary.simpleMessage("再試行"),
    "commonToday": MessageLookupByLibrary.simpleMessage("今日"),
    "commonUndo": MessageLookupByLibrary.simpleMessage("取り消し"),
    "commonUnitDay": MessageLookupByLibrary.simpleMessage("日"),
    "commonUnitMonth": MessageLookupByLibrary.simpleMessage("ヶ月"),
    "commonUnitWeek": MessageLookupByLibrary.simpleMessage("週"),
    "editorChangeIcon": MessageLookupByLibrary.simpleMessage("アイコンを変更"),
    "editorColorNote": MessageLookupByLibrary.simpleMessage("色でタスクをグループ分けできます"),
    "editorLabelColor": MessageLookupByLibrary.simpleMessage("カラー"),
    "editorLabelType": MessageLookupByLibrary.simpleMessage("タスク種別"),
    "editorNameHint": MessageLookupByLibrary.simpleMessage("タスク名を入力"),
    "editorSaveEdit": MessageLookupByLibrary.simpleMessage("更新する"),
    "editorSaveEditSuccess": m4,
    "editorSaveNew": MessageLookupByLibrary.simpleMessage("登録する"),
    "editorSaveNewSuccess": m5,
    "editorSectionBasic": MessageLookupByLibrary.simpleMessage("基本情報"),
    "editorSpanLabel": m6,
    "editorSpanPickerTitle": MessageLookupByLibrary.simpleMessage("繰り返し間隔"),
    "editorTitleEdit": MessageLookupByLibrary.simpleMessage("タスクを編集"),
    "editorTitleNew": MessageLookupByLibrary.simpleMessage("新規タスクを追加"),
    "editorTypeIrregular": MessageLookupByLibrary.simpleMessage("予定日を表示しない"),
    "editorTypeIrregularDesc": MessageLookupByLibrary.simpleMessage(
      "不定期に実行するタスク",
    ),
    "editorTypePeriod": MessageLookupByLibrary.simpleMessage("自動的に周期を判定"),
    "editorTypePeriodDesc": MessageLookupByLibrary.simpleMessage(
      "実行履歴から次回予定日を予測",
    ),
    "editorTypeScheduled": MessageLookupByLibrary.simpleMessage("周期を指定"),
    "editorTypeScheduledDesc": MessageLookupByLibrary.simpleMessage(
      "次回予定日までの間隔を手動で設定",
    ),
    "homeComplete": MessageLookupByLibrary.simpleMessage("完了"),
    "homeCompleteCommentPlaceholder": MessageLookupByLibrary.simpleMessage(
      "コメントを入力（任意）",
    ),
    "homeCompleteRecord": MessageLookupByLibrary.simpleMessage("完了を記録"),
    "homeCompleteSheetTitle": MessageLookupByLibrary.simpleMessage("タスクを完了"),
    "homeCompleteSuccess": m7,
    "homeDaysOverdue": m8,
    "homeDaysRemaining": m9,
    "homeFilterAll": MessageLookupByLibrary.simpleMessage("すべて"),
    "homeFilterIrregular": MessageLookupByLibrary.simpleMessage("不定期"),
    "homeFilterToday": MessageLookupByLibrary.simpleMessage("今日"),
    "homeFilterWeek": MessageLookupByLibrary.simpleMessage("今週"),
    "homeNoTasksFound": MessageLookupByLibrary.simpleMessage("一致するタスクが見つかりません"),
    "homeNoTasksYet": MessageLookupByLibrary.simpleMessage("タスクがまだありません"),
    "homeSearchHint": MessageLookupByLibrary.simpleMessage("タスクを検索"),
    "homeSectionOverdue": MessageLookupByLibrary.simpleMessage("超過"),
    "homeSectionUpcoming": MessageLookupByLibrary.simpleMessage("今後の予定"),
    "onboardingColorBlue": MessageLookupByLibrary.simpleMessage("エアコン"),
    "onboardingColorGreen": MessageLookupByLibrary.simpleMessage("庭"),
    "onboardingColorNone": MessageLookupByLibrary.simpleMessage("車両"),
    "onboardingColorOrange": MessageLookupByLibrary.simpleMessage("ベランダ"),
    "onboardingColorRed": MessageLookupByLibrary.simpleMessage("キッチン"),
    "onboardingColorYellow": MessageLookupByLibrary.simpleMessage("食品"),
    "onboardingDemoTask1": MessageLookupByLibrary.simpleMessage("ベランダの虫除け"),
    "onboardingDemoTask2": MessageLookupByLibrary.simpleMessage("オイル交換"),
    "onboardingDemoTask3": MessageLookupByLibrary.simpleMessage("歯ブラシ交換"),
    "onboardingDemoTask4": MessageLookupByLibrary.simpleMessage("お風呂の防カビ剤"),
    "onboardingDemoTask5": MessageLookupByLibrary.simpleMessage("スニーカーの洗濯"),
    "onboardingErrorSaveFailed": MessageLookupByLibrary.simpleMessage(
      "設定の保存に失敗しました",
    ),
    "onboardingNext": MessageLookupByLibrary.simpleMessage("次へ"),
    "onboardingPage1Body": MessageLookupByLibrary.simpleMessage(
      "洗車、フィルター掃除、歯ブラシ交換……いつやるか忘れがちなことを登録しておくだけです。",
    ),
    "onboardingPage1Title": MessageLookupByLibrary.simpleMessage(
      "いつやるんだっけ？　の悩みをなくす",
    ),
    "onboardingPage2Body": MessageLookupByLibrary.simpleMessage(
      "過去の登録から間隔を算出して、どのくらいの頻度でやっているのかを可視化します。",
    ),
    "onboardingPage2Title": MessageLookupByLibrary.simpleMessage(
      "次はいつごろだっけ？　の悩みをなくす",
    ),
    "onboardingPage3Body": MessageLookupByLibrary.simpleMessage(
      "カテゴリや場所などでタスクを色分けできます。一覧がひと目でわかりやすくなります。",
    ),
    "onboardingPage3Title": MessageLookupByLibrary.simpleMessage(
      "色でまとめると、見つけやすくなります",
    ),
    "onboardingSkip": MessageLookupByLibrary.simpleMessage("スキップ"),
    "onboardingStart": MessageLookupByLibrary.simpleMessage("最初のタスクを登録する"),
    "settingsLicense": MessageLookupByLibrary.simpleMessage("オープンソースライセンス"),
    "settingsSectionInfo": MessageLookupByLibrary.simpleMessage("情報"),
    "settingsTitle": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsTutorial": MessageLookupByLibrary.simpleMessage("チュートリアル"),
    "settingsVersion": MessageLookupByLibrary.simpleMessage("バージョン"),
    "taskErrorDeleteFailed": MessageLookupByLibrary.simpleMessage("削除に失敗しました"),
    "taskErrorInvalidArgument": MessageLookupByLibrary.simpleMessage(
      "入力内容が正しくありません",
    ),
    "taskErrorLoadFailed": MessageLookupByLibrary.simpleMessage("読み込みに失敗しました"),
    "taskErrorNotFound": MessageLookupByLibrary.simpleMessage("タスクが見つかりません"),
    "taskErrorSaveFailed": MessageLookupByLibrary.simpleMessage("保存に失敗しました"),
    "taskErrorUpdateFailed": MessageLookupByLibrary.simpleMessage("更新に失敗しました"),
    "title": MessageLookupByLibrary.simpleMessage("Dawnbreaker"),
  };
}
