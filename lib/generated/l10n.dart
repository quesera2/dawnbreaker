// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Dawnbreaker`
  String get title {
    return Intl.message('Dawnbreaker', name: 'title', desc: '', args: []);
  }

  /// `タスクを検索`
  String get homeSearchHint {
    return Intl.message('タスクを検索', name: 'homeSearchHint', desc: '', args: []);
  }

  /// `タスクがまだありません`
  String get homeNoTasksYet {
    return Intl.message(
      'タスクがまだありません',
      name: 'homeNoTasksYet',
      desc: '',
      args: [],
    );
  }

  /// `一致するタスクが見つかりません`
  String get homeNoTasksFound {
    return Intl.message(
      '一致するタスクが見つかりません',
      name: 'homeNoTasksFound',
      desc: '',
      args: [],
    );
  }

  /// `すべて`
  String get homeFilterAll {
    return Intl.message('すべて', name: 'homeFilterAll', desc: '', args: []);
  }

  /// `今日`
  String get homeFilterToday {
    return Intl.message('今日', name: 'homeFilterToday', desc: '', args: []);
  }

  /// `今週`
  String get homeFilterWeek {
    return Intl.message('今週', name: 'homeFilterWeek', desc: '', args: []);
  }

  /// `不定期`
  String get homeFilterIrregular {
    return Intl.message('不定期', name: 'homeFilterIrregular', desc: '', args: []);
  }

  /// `超過`
  String get homeSectionOverdue {
    return Intl.message('超過', name: 'homeSectionOverdue', desc: '', args: []);
  }

  /// `今後の予定`
  String get homeSectionUpcoming {
    return Intl.message(
      '今後の予定',
      name: 'homeSectionUpcoming',
      desc: '',
      args: [],
    );
  }

  /// `完了`
  String get homeComplete {
    return Intl.message('完了', name: 'homeComplete', desc: '', args: []);
  }

  /// `タスクを完了`
  String get homeCompleteSheetTitle {
    return Intl.message(
      'タスクを完了',
      name: 'homeCompleteSheetTitle',
      desc: '',
      args: [],
    );
  }

  /// `完了を記録`
  String get homeCompleteRecord {
    return Intl.message(
      '完了を記録',
      name: 'homeCompleteRecord',
      desc: '',
      args: [],
    );
  }

  /// `コメントを入力（任意）`
  String get homeCompleteCommentPlaceholder {
    return Intl.message(
      'コメントを入力（任意）',
      name: 'homeCompleteCommentPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `「{name}」の完了を記録しました`
  String homeCompleteSuccess(String name) {
    return Intl.message(
      '「$name」の完了を記録しました',
      name: 'homeCompleteSuccess',
      desc: '',
      args: [name],
    );
  }

  /// `今日`
  String get commonToday {
    return Intl.message('今日', name: 'commonToday', desc: '', args: []);
  }

  /// `OK`
  String get commonOk {
    return Intl.message('OK', name: 'commonOk', desc: '', args: []);
  }

  /// `キャンセル`
  String get commonCancel {
    return Intl.message('キャンセル', name: 'commonCancel', desc: '', args: []);
  }

  /// `再試行`
  String get commonRetry {
    return Intl.message('再試行', name: 'commonRetry', desc: '', args: []);
  }

  /// `取り消し`
  String get commonUndo {
    return Intl.message('取り消し', name: 'commonUndo', desc: '', args: []);
  }

  /// `エラー`
  String get commonErrorTitle {
    return Intl.message('エラー', name: 'commonErrorTitle', desc: '', args: []);
  }

  /// `予期しないエラーが発生しました`
  String get commonErrorUnknown {
    return Intl.message(
      '予期しないエラーが発生しました',
      name: 'commonErrorUnknown',
      desc: '',
      args: [],
    );
  }

  /// `閉じる`
  String get commonClose {
    return Intl.message('閉じる', name: 'commonClose', desc: '', args: []);
  }

  /// `日`
  String get commonUnitDay {
    return Intl.message('日', name: 'commonUnitDay', desc: '', args: []);
  }

  /// `週`
  String get commonUnitWeek {
    return Intl.message('週', name: 'commonUnitWeek', desc: '', args: []);
  }

  /// `ヶ月`
  String get commonUnitMonth {
    return Intl.message('ヶ月', name: 'commonUnitMonth', desc: '', args: []);
  }

  /// `{days}日超過`
  String homeDaysOverdue(int days) {
    return Intl.message(
      '$days日超過',
      name: 'homeDaysOverdue',
      desc: '',
      args: [days],
    );
  }

  /// `残り{days}日`
  String homeDaysRemaining(int days) {
    return Intl.message(
      '残り$days日',
      name: 'homeDaysRemaining',
      desc: '',
      args: [days],
    );
  }

  /// `読み込みに失敗しました`
  String get taskErrorLoadFailed {
    return Intl.message(
      '読み込みに失敗しました',
      name: 'taskErrorLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `タスクが見つかりません`
  String get taskErrorNotFound {
    return Intl.message(
      'タスクが見つかりません',
      name: 'taskErrorNotFound',
      desc: '',
      args: [],
    );
  }

  /// `保存に失敗しました`
  String get taskErrorSaveFailed {
    return Intl.message(
      '保存に失敗しました',
      name: 'taskErrorSaveFailed',
      desc: '',
      args: [],
    );
  }

  /// `更新に失敗しました`
  String get taskErrorUpdateFailed {
    return Intl.message(
      '更新に失敗しました',
      name: 'taskErrorUpdateFailed',
      desc: '',
      args: [],
    );
  }

  /// `削除に失敗しました`
  String get taskErrorDeleteFailed {
    return Intl.message(
      '削除に失敗しました',
      name: 'taskErrorDeleteFailed',
      desc: '',
      args: [],
    );
  }

  /// `入力内容が正しくありません`
  String get taskErrorInvalidArgument {
    return Intl.message(
      '入力内容が正しくありません',
      name: 'taskErrorInvalidArgument',
      desc: '',
      args: [],
    );
  }

  /// `設定の保存に失敗しました`
  String get onboardingErrorSaveFailed {
    return Intl.message(
      '設定の保存に失敗しました',
      name: 'onboardingErrorSaveFailed',
      desc: '',
      args: [],
    );
  }

  /// `新規タスクを追加`
  String get editorTitleNew {
    return Intl.message('新規タスクを追加', name: 'editorTitleNew', desc: '', args: []);
  }

  /// `タスクを編集`
  String get editorTitleEdit {
    return Intl.message('タスクを編集', name: 'editorTitleEdit', desc: '', args: []);
  }

  /// `基本情報`
  String get editorSectionBasic {
    return Intl.message('基本情報', name: 'editorSectionBasic', desc: '', args: []);
  }

  /// `タスク種別`
  String get editorLabelType {
    return Intl.message('タスク種別', name: 'editorLabelType', desc: '', args: []);
  }

  /// `カラー`
  String get editorLabelColor {
    return Intl.message('カラー', name: 'editorLabelColor', desc: '', args: []);
  }

  /// `アイコンを変更`
  String get editorChangeIcon {
    return Intl.message(
      'アイコンを変更',
      name: 'editorChangeIcon',
      desc: '',
      args: [],
    );
  }

  /// `予定日を表示しない`
  String get editorTypeIrregular {
    return Intl.message(
      '予定日を表示しない',
      name: 'editorTypeIrregular',
      desc: '',
      args: [],
    );
  }

  /// `不定期に実行するタスク`
  String get editorTypeIrregularDesc {
    return Intl.message(
      '不定期に実行するタスク',
      name: 'editorTypeIrregularDesc',
      desc: '',
      args: [],
    );
  }

  /// `自動的に周期を判定`
  String get editorTypePeriod {
    return Intl.message(
      '自動的に周期を判定',
      name: 'editorTypePeriod',
      desc: '',
      args: [],
    );
  }

  /// `実行履歴から次回予定日を予測`
  String get editorTypePeriodDesc {
    return Intl.message(
      '実行履歴から次回予定日を予測',
      name: 'editorTypePeriodDesc',
      desc: '',
      args: [],
    );
  }

  /// `周期を指定`
  String get editorTypeScheduled {
    return Intl.message(
      '周期を指定',
      name: 'editorTypeScheduled',
      desc: '',
      args: [],
    );
  }

  /// `次回予定日までの間隔を手動で設定`
  String get editorTypeScheduledDesc {
    return Intl.message(
      '次回予定日までの間隔を手動で設定',
      name: 'editorTypeScheduledDesc',
      desc: '',
      args: [],
    );
  }

  /// `繰り返し間隔`
  String get editorSpanPickerTitle {
    return Intl.message(
      '繰り返し間隔',
      name: 'editorSpanPickerTitle',
      desc: '',
      args: [],
    );
  }

  /// `{value}{unit}ごと`
  String editorSpanLabel(String value, String unit) {
    return Intl.message(
      '$value$unitごと',
      name: 'editorSpanLabel',
      desc: '',
      args: [value, unit],
    );
  }

  /// `登録する`
  String get editorSaveNew {
    return Intl.message('登録する', name: 'editorSaveNew', desc: '', args: []);
  }

  /// `更新する`
  String get editorSaveEdit {
    return Intl.message('更新する', name: 'editorSaveEdit', desc: '', args: []);
  }

  /// `「{name}」を登録しました`
  String editorSaveNewSuccess(String name) {
    return Intl.message(
      '「$name」を登録しました',
      name: 'editorSaveNewSuccess',
      desc: '',
      args: [name],
    );
  }

  /// `「{name}」を更新しました`
  String editorSaveEditSuccess(String name) {
    return Intl.message(
      '「$name」を更新しました',
      name: 'editorSaveEditSuccess',
      desc: '',
      args: [name],
    );
  }

  /// `色でタスクをグループ分けできます`
  String get editorColorNote {
    return Intl.message(
      '色でタスクをグループ分けできます',
      name: 'editorColorNote',
      desc: '',
      args: [],
    );
  }

  /// `タスク名を入力`
  String get editorNameHint {
    return Intl.message('タスク名を入力', name: 'editorNameHint', desc: '', args: []);
  }

  /// `タスク詳細`
  String get appDetailTitle {
    return Intl.message('タスク詳細', name: 'appDetailTitle', desc: '', args: []);
  }

  /// `編集`
  String get appDetailEdit {
    return Intl.message('編集', name: 'appDetailEdit', desc: '', args: []);
  }

  /// `削除`
  String get appDetailDelete {
    return Intl.message('削除', name: 'appDetailDelete', desc: '', args: []);
  }

  /// `「{name}」を削除しました`
  String appDetailDeleteSuccess(String name) {
    return Intl.message(
      '「$name」を削除しました',
      name: 'appDetailDeleteSuccess',
      desc: '',
      args: [name],
    );
  }

  /// `前回から`
  String get appDetailStatsDaysSince {
    return Intl.message(
      '前回から',
      name: 'appDetailStatsDaysSince',
      desc: '',
      args: [],
    );
  }

  /// `平均間隔`
  String get appDetailStatsAvgInterval {
    return Intl.message(
      '平均間隔',
      name: 'appDetailStatsAvgInterval',
      desc: '',
      args: [],
    );
  }

  /// `履歴`
  String get appDetailHistorySection {
    return Intl.message(
      '履歴',
      name: 'appDetailHistorySection',
      desc: '',
      args: [],
    );
  }

  /// `前回から{days}日`
  String appDetailDaysInterval(int days) {
    return Intl.message(
      '前回から$days日',
      name: 'appDetailDaysInterval',
      desc: '',
      args: [days],
    );
  }

  /// `不定期`
  String get appDetailTypeBadgeIrregular {
    return Intl.message(
      '不定期',
      name: 'appDetailTypeBadgeIrregular',
      desc: '',
      args: [],
    );
  }

  /// `自動周期`
  String get appDetailTypeBadgePeriod {
    return Intl.message(
      '自動周期',
      name: 'appDetailTypeBadgePeriod',
      desc: '',
      args: [],
    );
  }

  /// `定期 {value}{unit}`
  String appDetailTypeBadgeScheduled(int value, String unit) {
    return Intl.message(
      '定期 $value$unit',
      name: 'appDetailTypeBadgeScheduled',
      desc: '',
      args: [value, unit],
    );
  }

  /// `履歴を更新しました`
  String get appDetailUpdateHistorySuccess {
    return Intl.message(
      '履歴を更新しました',
      name: 'appDetailUpdateHistorySuccess',
      desc: '',
      args: [],
    );
  }

  /// `いつやるんだっけ？　の悩みをなくす`
  String get onboardingPage1Title {
    return Intl.message(
      'いつやるんだっけ？　の悩みをなくす',
      name: 'onboardingPage1Title',
      desc: '',
      args: [],
    );
  }

  /// `洗車、フィルター掃除、歯ブラシ交換……いつやるか忘れがちなことを登録しておくだけです。`
  String get onboardingPage1Body {
    return Intl.message(
      '洗車、フィルター掃除、歯ブラシ交換……いつやるか忘れがちなことを登録しておくだけです。',
      name: 'onboardingPage1Body',
      desc: '',
      args: [],
    );
  }

  /// `次はいつごろだっけ？　の悩みをなくす`
  String get onboardingPage2Title {
    return Intl.message(
      '次はいつごろだっけ？　の悩みをなくす',
      name: 'onboardingPage2Title',
      desc: '',
      args: [],
    );
  }

  /// `過去の登録から間隔を算出して、どのくらいの頻度でやっているのかを可視化します。`
  String get onboardingPage2Body {
    return Intl.message(
      '過去の登録から間隔を算出して、どのくらいの頻度でやっているのかを可視化します。',
      name: 'onboardingPage2Body',
      desc: '',
      args: [],
    );
  }

  /// `色でまとめると、見つけやすくなります`
  String get onboardingPage3Title {
    return Intl.message(
      '色でまとめると、見つけやすくなります',
      name: 'onboardingPage3Title',
      desc: '',
      args: [],
    );
  }

  /// `カテゴリや場所などでタスクを色分けできます。一覧がひと目でわかりやすくなります。`
  String get onboardingPage3Body {
    return Intl.message(
      'カテゴリや場所などでタスクを色分けできます。一覧がひと目でわかりやすくなります。',
      name: 'onboardingPage3Body',
      desc: '',
      args: [],
    );
  }

  /// `キッチン`
  String get onboardingColorRed {
    return Intl.message('キッチン', name: 'onboardingColorRed', desc: '', args: []);
  }

  /// `エアコン`
  String get onboardingColorBlue {
    return Intl.message(
      'エアコン',
      name: 'onboardingColorBlue',
      desc: '',
      args: [],
    );
  }

  /// `庭`
  String get onboardingColorGreen {
    return Intl.message('庭', name: 'onboardingColorGreen', desc: '', args: []);
  }

  /// `ベランダ`
  String get onboardingColorOrange {
    return Intl.message(
      'ベランダ',
      name: 'onboardingColorOrange',
      desc: '',
      args: [],
    );
  }

  /// `食品`
  String get onboardingColorYellow {
    return Intl.message(
      '食品',
      name: 'onboardingColorYellow',
      desc: '',
      args: [],
    );
  }

  /// `車両`
  String get onboardingColorNone {
    return Intl.message('車両', name: 'onboardingColorNone', desc: '', args: []);
  }

  /// `ベランダの虫除け`
  String get onboardingDemoTask1 {
    return Intl.message(
      'ベランダの虫除け',
      name: 'onboardingDemoTask1',
      desc: '',
      args: [],
    );
  }

  /// `オイル交換`
  String get onboardingDemoTask2 {
    return Intl.message(
      'オイル交換',
      name: 'onboardingDemoTask2',
      desc: '',
      args: [],
    );
  }

  /// `歯ブラシ交換`
  String get onboardingDemoTask3 {
    return Intl.message(
      '歯ブラシ交換',
      name: 'onboardingDemoTask3',
      desc: '',
      args: [],
    );
  }

  /// `お風呂の防カビ剤`
  String get onboardingDemoTask4 {
    return Intl.message(
      'お風呂の防カビ剤',
      name: 'onboardingDemoTask4',
      desc: '',
      args: [],
    );
  }

  /// `スニーカーの洗濯`
  String get onboardingDemoTask5 {
    return Intl.message(
      'スニーカーの洗濯',
      name: 'onboardingDemoTask5',
      desc: '',
      args: [],
    );
  }

  /// `次へ`
  String get onboardingNext {
    return Intl.message('次へ', name: 'onboardingNext', desc: '', args: []);
  }

  /// `スキップ`
  String get onboardingSkip {
    return Intl.message('スキップ', name: 'onboardingSkip', desc: '', args: []);
  }

  /// `最初のタスクを登録する`
  String get onboardingStart {
    return Intl.message(
      '最初のタスクを登録する',
      name: 'onboardingStart',
      desc: '',
      args: [],
    );
  }

  /// `設定`
  String get settingsTitle {
    return Intl.message('設定', name: 'settingsTitle', desc: '', args: []);
  }

  /// `情報`
  String get settingsSectionInfo {
    return Intl.message('情報', name: 'settingsSectionInfo', desc: '', args: []);
  }

  /// `バージョン`
  String get settingsVersion {
    return Intl.message('バージョン', name: 'settingsVersion', desc: '', args: []);
  }

  /// `チュートリアル`
  String get settingsTutorial {
    return Intl.message(
      'チュートリアル',
      name: 'settingsTutorial',
      desc: '',
      args: [],
    );
  }

  /// `オープンソースライセンス`
  String get settingsLicense {
    return Intl.message(
      'オープンソースライセンス',
      name: 'settingsLicense',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
