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
  String get homeBarAdd => 'Add';

  @override
  String get homeBarSettings => 'Settings';

  @override
  String get homeSearchHint => 'Search tasks';

  @override
  String get homeNoTasksYet => 'No tasks yet';

  @override
  String get homeNoTasksFound => 'No matching tasks found';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterToday => 'Today';

  @override
  String get homeFilterWeek => 'Current week';

  @override
  String get homeFilterIrregular => 'Irregular';

  @override
  String get homeSectionOverdue => 'Overdue';

  @override
  String get homeSectionUpcoming => 'Upcoming';

  @override
  String get homeComplete => 'Done';

  @override
  String get homeCompleteSheetTitle => 'Complete task';

  @override
  String get homeCompleteRecord => 'Record completion';

  @override
  String get homeCompleteDateLabel => 'Completion date';

  @override
  String get homeCompleteCommentLabel => 'Comment';

  @override
  String get homeCompleteCommentPlaceholder => 'Add a comment (optional)';

  @override
  String homeCompleteSuccess(String name) {
    return 'Marked \"$name\" as complete';
  }

  @override
  String get commonToday => 'Today';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirmTitle => 'Confirm';

  @override
  String get commonErrorTitle => 'Error';

  @override
  String get commonErrorUnknown => 'An unexpected error occurred';

  @override
  String get commonClose => 'Close';

  @override
  String get commonUnitDay => 'd';

  @override
  String get commonUnitWeek => 'weeks';

  @override
  String get commonUnitMonth => 'months';

  @override
  String homeDaysOverdue(int days) {
    return '${days}d overdue';
  }

  @override
  String homeDaysRemaining(int days) {
    return '${days}d remaining';
  }

  @override
  String get taskErrorLoadFailed => 'Failed to load';

  @override
  String get taskErrorNotFound => 'Task not found';

  @override
  String get taskErrorSaveFailed => 'Failed to save';

  @override
  String get taskErrorUpdateFailed => 'Failed to update';

  @override
  String get taskErrorDeleteFailed => 'Failed to delete';

  @override
  String get taskErrorInvalidArgument => 'Invalid input';

  @override
  String get onboardingErrorSaveFailed => 'Failed to save settings';

  @override
  String get editorTitleNew => 'Add Task';

  @override
  String get editorTitleEdit => 'Edit Task';

  @override
  String get editorSectionBasic => 'Basic info';

  @override
  String get editorLabelType => 'Task type';

  @override
  String get editorLabelColor => 'Color';

  @override
  String get editorChangeIcon => 'Change icon';

  @override
  String get editorTypeIrregular => 'No due date';

  @override
  String get editorTypeIrregularDesc => 'For tasks without a fixed schedule';

  @override
  String get editorTypePeriod => 'Auto-detect interval';

  @override
  String get editorTypePeriodDesc => 'Predicts next due date from history';

  @override
  String get editorTypeScheduled => 'Set interval';

  @override
  String get editorTypeScheduledDesc =>
      'Manually set the interval to the next due date';

  @override
  String get editorSpanPickerTitle => 'Repeat interval';

  @override
  String editorSpanLabel(String value, String unit) {
    return 'Every $value $unit';
  }

  @override
  String get editorSaveNew => 'Register';

  @override
  String get editorSaveEdit => 'Update';

  @override
  String editorSaveNewSuccess(String name) {
    return '\"$name\" registered';
  }

  @override
  String editorSaveEditSuccess(String name) {
    return '\"$name\" updated';
  }

  @override
  String get editorColorNote => 'Use colors to group your tasks';

  @override
  String get editorNameHint => 'Enter task name';

  @override
  String get appDetailTitle => 'Task Detail';

  @override
  String get appDetailEdit => 'Edit';

  @override
  String get appDetailDelete => 'Delete';

  @override
  String appDetailDeleteSuccess(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get appDetailStatsDaysSince => 'Days since';

  @override
  String get appDetailStatsAvgInterval => 'Avg interval';

  @override
  String get appDetailHistorySection => 'History';

  @override
  String appDetailDaysInterval(int days) {
    return '${days}d from prev';
  }

  @override
  String get appDetailTypeBadgeIrregular => 'Irregular';

  @override
  String get appDetailTypeBadgePeriod => 'Auto interval';

  @override
  String appDetailTypeBadgeScheduled(int value, String unit) {
    return 'Every $value $unit';
  }

  @override
  String get appDetailUpdateHistorySuccess => 'History updated';

  @override
  String appDetailTaskDeleteConfirm(String name) {
    return 'Delete task “$name”?';
  }

  @override
  String get onboardingPage1Title =>
      'Never forget \"when was I supposed to do this?\"';

  @override
  String get onboardingPage1Body =>
      'Car wash, filter cleaning, toothbrush replacement... just register things you tend to forget.';

  @override
  String get onboardingPage2Title =>
      'Never wonder \"when should I do this next?\"';

  @override
  String get onboardingPage2Body =>
      'Intervals are calculated from past records to visualize how often you\'re actually doing each task.';

  @override
  String get onboardingPage3Title => 'Group by color to find tasks faster';

  @override
  String get onboardingPage3Body =>
      'Color-code tasks by category or location to make your list easy to scan at a glance.';

  @override
  String get onboardingColorRed => 'Kitchen';

  @override
  String get onboardingColorBlue => 'AC';

  @override
  String get onboardingColorGreen => 'Garden';

  @override
  String get onboardingColorOrange => 'Balcony';

  @override
  String get onboardingColorYellow => 'Food';

  @override
  String get onboardingColorNone => 'Vehicle';

  @override
  String get onboardingDemoTask1 => 'Balcony bug repellent';

  @override
  String get onboardingDemoTask2 => 'Oil change';

  @override
  String get onboardingDemoTask3 => 'Toothbrush replacement';

  @override
  String get onboardingDemoTask4 => 'Bath mold spray';

  @override
  String get onboardingDemoTask5 => 'Sneaker wash';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Register your first task';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionInfo => 'Info';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsLicense => 'Open Source Licenses';

  @override
  String get settingsSectionDebug => 'Debug';

  @override
  String get settingsDebugGenerateDummyTasks => 'Generate dummy tasks';

  @override
  String get settingsDebugDummyTasksGenerated => 'Dummy tasks generated';

  @override
  String get settingsDebugDeleteAllTasks => 'Delete all tasks';

  @override
  String get settingsDebugAllTasksDeleted => 'All tasks deleted';
}
