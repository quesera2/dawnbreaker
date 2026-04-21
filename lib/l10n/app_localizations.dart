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

  /// No description provided for @homeReRegister.
  ///
  /// In ja, this message translates to:
  /// **'再登録'**
  String get homeReRegister;

  /// No description provided for @homeFilterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get homeFilterAll;

  /// No description provided for @homeFilterOverdue.
  ///
  /// In ja, this message translates to:
  /// **'超過'**
  String get homeFilterOverdue;

  /// No description provided for @homeFilterToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get homeFilterToday;

  /// No description provided for @homeFilterWeek.
  ///
  /// In ja, this message translates to:
  /// **'7日以内'**
  String get homeFilterWeek;

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

  /// No description provided for @homeDueToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get homeDueToday;

  /// No description provided for @homeAddTask.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加'**
  String get homeAddTask;

  /// No description provided for @homeSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get homeSettings;

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

  /// No description provided for @errorTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorTitle;

  /// No description provided for @errorUnknown.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました'**
  String get errorUnknown;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

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

  /// No description provided for @editorLabelName.
  ///
  /// In ja, this message translates to:
  /// **'タスク名'**
  String get editorLabelName;

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

  /// No description provided for @editorLabelSpan.
  ///
  /// In ja, this message translates to:
  /// **'実行スパン'**
  String get editorLabelSpan;

  /// No description provided for @editorLabelIcon.
  ///
  /// In ja, this message translates to:
  /// **'アイコン'**
  String get editorLabelIcon;

  /// No description provided for @editorChangeIcon.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを変更する'**
  String get editorChangeIcon;

  /// No description provided for @editorTypeIrregular.
  ///
  /// In ja, this message translates to:
  /// **'予定日を表示しない'**
  String get editorTypeIrregular;

  /// No description provided for @editorTypeIrregularDesc.
  ///
  /// In ja, this message translates to:
  /// **'不定期に実行するタスクで予定日を表示しません'**
  String get editorTypeIrregularDesc;

  /// No description provided for @editorTypePeriod.
  ///
  /// In ja, this message translates to:
  /// **'自動的に周期を判定'**
  String get editorTypePeriod;

  /// No description provided for @editorTypePeriodDesc.
  ///
  /// In ja, this message translates to:
  /// **'タスクの実行履歴から次の予定日を表示します'**
  String get editorTypePeriodDesc;

  /// No description provided for @editorTypeScheduled.
  ///
  /// In ja, this message translates to:
  /// **'周期を指定'**
  String get editorTypeScheduled;

  /// No description provided for @editorTypeScheduledDesc.
  ///
  /// In ja, this message translates to:
  /// **'次の予定日までの間隔を手動で設定します'**
  String get editorTypeScheduledDesc;

  /// No description provided for @editorSpanDay.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get editorSpanDay;

  /// No description provided for @editorSpanWeek.
  ///
  /// In ja, this message translates to:
  /// **'週'**
  String get editorSpanWeek;

  /// No description provided for @editorSpanMonth.
  ///
  /// In ja, this message translates to:
  /// **'ヶ月'**
  String get editorSpanMonth;

  /// No description provided for @editorSpanLabel.
  ///
  /// In ja, this message translates to:
  /// **'{value}{unit}ごと'**
  String editorSpanLabel(String value, String unit);

  /// No description provided for @editorSaveNew.
  ///
  /// In ja, this message translates to:
  /// **'登録'**
  String get editorSaveNew;

  /// No description provided for @editorSaveEdit.
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get editorSaveEdit;

  /// No description provided for @editorIconDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを選択'**
  String get editorIconDialogTitle;

  /// No description provided for @editorColorNone.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get editorColorNone;

  /// No description provided for @editorColorNote.
  ///
  /// In ja, this message translates to:
  /// **'色を選択することでタスクのグループ分けに使えます'**
  String get editorColorNote;

  /// No description provided for @editorNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例：歯医者の予約'**
  String get editorNameHint;
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
