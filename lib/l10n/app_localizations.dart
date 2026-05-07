import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @title.
  ///
  /// In ja, this message translates to:
  /// **'Dawnbreaker'**
  String get title;

  /// No description provided for @homeBarAdd.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get homeBarAdd;

  /// No description provided for @homeBarSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get homeBarSettings;

  /// No description provided for @homeSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'タスクを検索'**
  String get homeSearchHint;

  /// No description provided for @homeNoTasksYet.
  ///
  /// In ja, this message translates to:
  /// **'タスクがまだありません'**
  String get homeNoTasksYet;

  /// No description provided for @homeNoTasksFound.
  ///
  /// In ja, this message translates to:
  /// **'一致するタスクが見つかりません'**
  String get homeNoTasksFound;

  /// No description provided for @homeFilterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get homeFilterAll;

  /// No description provided for @homeFilterToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get homeFilterToday;

  /// No description provided for @homeFilterWeek.
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get homeFilterWeek;

  /// No description provided for @homeFilterIrregular.
  ///
  /// In ja, this message translates to:
  /// **'不定期'**
  String get homeFilterIrregular;

  /// No description provided for @homeSectionOverdue.
  ///
  /// In ja, this message translates to:
  /// **'超過'**
  String get homeSectionOverdue;

  /// No description provided for @homeSectionUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'今後の予定'**
  String get homeSectionUpcoming;

  /// No description provided for @homeComplete.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get homeComplete;

  /// No description provided for @homeCompleteSheetTitle.
  ///
  /// In ja, this message translates to:
  /// **'タスクを完了'**
  String get homeCompleteSheetTitle;

  /// No description provided for @homeCompleteRecord.
  ///
  /// In ja, this message translates to:
  /// **'完了を記録'**
  String get homeCompleteRecord;

  /// No description provided for @homeCompleteDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'完了日'**
  String get homeCompleteDateLabel;

  /// No description provided for @homeCompleteCommentLabel.
  ///
  /// In ja, this message translates to:
  /// **'コメント'**
  String get homeCompleteCommentLabel;

  /// No description provided for @homeCompleteCommentPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'コメントを入力（任意）'**
  String get homeCompleteCommentPlaceholder;

  /// No description provided for @homeCompleteSuccess.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」の完了を記録しました'**
  String homeCompleteSuccess(String name);

  /// No description provided for @commonToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get commonToday;

  /// No description provided for @commonOk.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get commonRetry;

  /// No description provided for @commonUndo.
  ///
  /// In ja, this message translates to:
  /// **'取り消し'**
  String get commonUndo;

  /// No description provided for @commonDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get commonDelete;

  /// No description provided for @commonConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get commonConfirmTitle;

  /// No description provided for @commonErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorUnknown.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました'**
  String get commonErrorUnknown;

  /// No description provided for @commonClose.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get commonClose;

  /// No description provided for @commonUnitDay.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get commonUnitDay;

  /// No description provided for @commonUnitWeek.
  ///
  /// In ja, this message translates to:
  /// **'週'**
  String get commonUnitWeek;

  /// No description provided for @commonUnitMonth.
  ///
  /// In ja, this message translates to:
  /// **'ヶ月'**
  String get commonUnitMonth;

  /// No description provided for @homeDaysOverdue.
  ///
  /// In ja, this message translates to:
  /// **'{days}日超過'**
  String homeDaysOverdue(int days);

  /// No description provided for @homeDaysRemaining.
  ///
  /// In ja, this message translates to:
  /// **'残り{days}日'**
  String homeDaysRemaining(int days);

  /// No description provided for @taskErrorLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'読み込みに失敗しました'**
  String get taskErrorLoadFailed;

  /// No description provided for @taskErrorNotFound.
  ///
  /// In ja, this message translates to:
  /// **'タスクが見つかりません'**
  String get taskErrorNotFound;

  /// No description provided for @taskErrorSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました'**
  String get taskErrorSaveFailed;

  /// No description provided for @taskErrorUpdateFailed.
  ///
  /// In ja, this message translates to:
  /// **'更新に失敗しました'**
  String get taskErrorUpdateFailed;

  /// No description provided for @taskErrorDeleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get taskErrorDeleteFailed;

  /// No description provided for @taskErrorInvalidArgument.
  ///
  /// In ja, this message translates to:
  /// **'入力内容が正しくありません'**
  String get taskErrorInvalidArgument;

  /// No description provided for @onboardingErrorSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'設定の保存に失敗しました'**
  String get onboardingErrorSaveFailed;

  /// No description provided for @editorTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'新規タスクを追加'**
  String get editorTitleNew;

  /// No description provided for @editorTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'タスクを編集'**
  String get editorTitleEdit;

  /// No description provided for @editorSectionBasic.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get editorSectionBasic;

  /// No description provided for @editorLabelType.
  ///
  /// In ja, this message translates to:
  /// **'タスク種別'**
  String get editorLabelType;

  /// No description provided for @editorLabelColor.
  ///
  /// In ja, this message translates to:
  /// **'カラー'**
  String get editorLabelColor;

  /// No description provided for @editorChangeIcon.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを変更'**
  String get editorChangeIcon;

  /// No description provided for @editorTypeIrregular.
  ///
  /// In ja, this message translates to:
  /// **'予定日を表示しない'**
  String get editorTypeIrregular;

  /// No description provided for @editorTypeIrregularDesc.
  ///
  /// In ja, this message translates to:
  /// **'不定期に実行するタスク'**
  String get editorTypeIrregularDesc;

  /// No description provided for @editorTypePeriod.
  ///
  /// In ja, this message translates to:
  /// **'自動的に周期を判定'**
  String get editorTypePeriod;

  /// No description provided for @editorTypePeriodDesc.
  ///
  /// In ja, this message translates to:
  /// **'実行履歴から次回予定日を予測'**
  String get editorTypePeriodDesc;

  /// No description provided for @editorTypeScheduled.
  ///
  /// In ja, this message translates to:
  /// **'周期を指定'**
  String get editorTypeScheduled;

  /// No description provided for @editorTypeScheduledDesc.
  ///
  /// In ja, this message translates to:
  /// **'次回予定日までの間隔を手動で設定'**
  String get editorTypeScheduledDesc;

  /// No description provided for @editorSpanPickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'繰り返し間隔'**
  String get editorSpanPickerTitle;

  /// No description provided for @editorSpanLabel.
  ///
  /// In ja, this message translates to:
  /// **'{value}{unit}ごと'**
  String editorSpanLabel(String value, String unit);

  /// No description provided for @editorSaveNew.
  ///
  /// In ja, this message translates to:
  /// **'登録する'**
  String get editorSaveNew;

  /// No description provided for @editorSaveEdit.
  ///
  /// In ja, this message translates to:
  /// **'更新する'**
  String get editorSaveEdit;

  /// No description provided for @editorSaveNewSuccess.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を登録しました'**
  String editorSaveNewSuccess(String name);

  /// No description provided for @editorSaveEditSuccess.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を更新しました'**
  String editorSaveEditSuccess(String name);

  /// No description provided for @editorColorNote.
  ///
  /// In ja, this message translates to:
  /// **'色でタスクをグループ分けできます'**
  String get editorColorNote;

  /// No description provided for @editorNameHint.
  ///
  /// In ja, this message translates to:
  /// **'タスク名を入力'**
  String get editorNameHint;

  /// No description provided for @appDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'タスク詳細'**
  String get appDetailTitle;

  /// No description provided for @appDetailEdit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get appDetailEdit;

  /// No description provided for @appDetailDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get appDetailDelete;

  /// No description provided for @appDetailDeleteSuccess.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を削除しました'**
  String appDetailDeleteSuccess(String name);

  /// No description provided for @appDetailStatsDaysSince.
  ///
  /// In ja, this message translates to:
  /// **'前回から'**
  String get appDetailStatsDaysSince;

  /// No description provided for @appDetailStatsAvgInterval.
  ///
  /// In ja, this message translates to:
  /// **'平均間隔'**
  String get appDetailStatsAvgInterval;

  /// No description provided for @appDetailHistorySection.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get appDetailHistorySection;

  /// No description provided for @appDetailDaysInterval.
  ///
  /// In ja, this message translates to:
  /// **'前回から{days}日'**
  String appDetailDaysInterval(int days);

  /// No description provided for @appDetailTypeBadgeIrregular.
  ///
  /// In ja, this message translates to:
  /// **'不定期'**
  String get appDetailTypeBadgeIrregular;

  /// No description provided for @appDetailTypeBadgePeriod.
  ///
  /// In ja, this message translates to:
  /// **'自動周期'**
  String get appDetailTypeBadgePeriod;

  /// No description provided for @appDetailTypeBadgeScheduled.
  ///
  /// In ja, this message translates to:
  /// **'定期 {value}{unit}'**
  String appDetailTypeBadgeScheduled(int value, String unit);

  /// No description provided for @appDetailUpdateHistorySuccess.
  ///
  /// In ja, this message translates to:
  /// **'履歴を更新しました'**
  String get appDetailUpdateHistorySuccess;

  /// No description provided for @appDetailTaskDeleteConfirm.
  ///
  /// In ja, this message translates to:
  /// **'タスク「{name}」を削除しますか？'**
  String appDetailTaskDeleteConfirm(String name);

  /// No description provided for @onboardingPage1Title.
  ///
  /// In ja, this message translates to:
  /// **'いつやるんだっけ？　の悩みをなくす'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In ja, this message translates to:
  /// **'洗車、フィルター掃除、歯ブラシ交換……いつやるか忘れがちなことを登録しておくだけです。'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In ja, this message translates to:
  /// **'次はいつごろだっけ？　の悩みをなくす'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In ja, this message translates to:
  /// **'過去の登録から間隔を算出して、どのくらいの頻度でやっているのかを可視化します。'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In ja, this message translates to:
  /// **'色でまとめると、見つけやすくなります'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリや場所などでタスクを色分けできます。一覧がひと目でわかりやすくなります。'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingColorRed.
  ///
  /// In ja, this message translates to:
  /// **'キッチン'**
  String get onboardingColorRed;

  /// No description provided for @onboardingColorBlue.
  ///
  /// In ja, this message translates to:
  /// **'エアコン'**
  String get onboardingColorBlue;

  /// No description provided for @onboardingColorGreen.
  ///
  /// In ja, this message translates to:
  /// **'庭'**
  String get onboardingColorGreen;

  /// No description provided for @onboardingColorOrange.
  ///
  /// In ja, this message translates to:
  /// **'ベランダ'**
  String get onboardingColorOrange;

  /// No description provided for @onboardingColorYellow.
  ///
  /// In ja, this message translates to:
  /// **'食品'**
  String get onboardingColorYellow;

  /// No description provided for @onboardingColorNone.
  ///
  /// In ja, this message translates to:
  /// **'車両'**
  String get onboardingColorNone;

  /// No description provided for @onboardingDemoTask1.
  ///
  /// In ja, this message translates to:
  /// **'ベランダの虫除け'**
  String get onboardingDemoTask1;

  /// No description provided for @onboardingDemoTask2.
  ///
  /// In ja, this message translates to:
  /// **'オイル交換'**
  String get onboardingDemoTask2;

  /// No description provided for @onboardingDemoTask3.
  ///
  /// In ja, this message translates to:
  /// **'歯ブラシ交換'**
  String get onboardingDemoTask3;

  /// No description provided for @onboardingDemoTask4.
  ///
  /// In ja, this message translates to:
  /// **'お風呂の防カビ剤'**
  String get onboardingDemoTask4;

  /// No description provided for @onboardingDemoTask5.
  ///
  /// In ja, this message translates to:
  /// **'スニーカーの洗濯'**
  String get onboardingDemoTask5;

  /// No description provided for @onboardingNext.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In ja, this message translates to:
  /// **'最初のタスクを登録する'**
  String get onboardingStart;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In ja, this message translates to:
  /// **'情報'**
  String get settingsSectionInfo;

  /// No description provided for @settingsVersion.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get settingsVersion;

  /// No description provided for @settingsTutorial.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアル'**
  String get settingsTutorial;

  /// No description provided for @settingsLicense.
  ///
  /// In ja, this message translates to:
  /// **'オープンソースライセンス'**
  String get settingsLicense;

  /// No description provided for @settingsSectionDebug.
  ///
  /// In ja, this message translates to:
  /// **'デバッグ'**
  String get settingsSectionDebug;

  /// No description provided for @settingsDebugGenerateDummyTasks.
  ///
  /// In ja, this message translates to:
  /// **'ダミータスクを生成'**
  String get settingsDebugGenerateDummyTasks;

  /// No description provided for @settingsDebugDummyTasksGenerated.
  ///
  /// In ja, this message translates to:
  /// **'ダミータスクを生成しました'**
  String get settingsDebugDummyTasksGenerated;

  /// No description provided for @settingsDebugDeleteAllTasks.
  ///
  /// In ja, this message translates to:
  /// **'すべてのタスクを削除'**
  String get settingsDebugDeleteAllTasks;

  /// No description provided for @settingsDebugAllTasksDeleted.
  ///
  /// In ja, this message translates to:
  /// **'すべてのタスクを削除しました'**
  String get settingsDebugAllTasksDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
