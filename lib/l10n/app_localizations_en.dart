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
  String get homeFilterAll => 'All';

  @override
  String get homeFilterOverdue => 'Overdue';

  @override
  String get homeFilterToday => 'Today';

  @override
  String get homeFilterWeek => 'Next 7 days';

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
  String homeCompleteSuccess(String name) {
    return 'Marked \"$name\" as complete';
  }

  @override
  String get homeDueToday => 'Today';

  @override
  String get homeAddTask => 'Add task';

  @override
  String get homeSettings => 'Settings';

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
  String get errorTitle => 'Error';

  @override
  String get errorUnknown => 'An unexpected error occurred';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get undo => 'Undo';

  @override
  String get editorTitleNew => 'Add Task';

  @override
  String get editorTitleEdit => 'Edit Task';

  @override
  String get editorSectionBasic => 'Basic info';

  @override
  String get editorLabelName => 'Task name';

  @override
  String get editorLabelType => 'Task type';

  @override
  String get editorLabelColor => 'Color';

  @override
  String get editorLabelSpan => 'Interval';

  @override
  String get editorLabelIcon => 'Icon';

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
  String get editorSpanDay => 'days';

  @override
  String get editorSpanWeek => 'weeks';

  @override
  String get editorSpanMonth => 'months';

  @override
  String editorSpanLabel(String value, String unit) {
    return 'Every $value $unit';
  }

  @override
  String get editorSaveNew => 'Register';

  @override
  String get editorSaveEdit => 'Update';

  @override
  String get editorIconDialogTitle => 'Select icon';

  @override
  String get editorColorNone => 'None';

  @override
  String get editorColorNote => 'Use colors to group your tasks';

  @override
  String get editorNameHint => 'Enter task name';
}
