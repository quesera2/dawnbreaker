// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(days) => "${days}d from prev";

  static String m1(name) => "Deleted \"${name}\"";

  static String m2(value, unit) => "Every ${value} ${unit}";

  static String m3(name) => "\"${name}\" updated";

  static String m4(name) => "\"${name}\" registered";

  static String m5(value, unit) => "Every ${value} ${unit}";

  static String m6(name) => "Marked \"${name}\" as complete";

  static String m7(days) => "${days}d overdue";

  static String m8(days) => "${days}d remaining";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appDetailDaysInterval": m0,
    "appDetailDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "appDetailDeleteSuccess": m1,
    "appDetailEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "appDetailHistorySection": MessageLookupByLibrary.simpleMessage("History"),
    "appDetailStatsAvgInterval": MessageLookupByLibrary.simpleMessage(
      "Avg interval",
    ),
    "appDetailStatsDaysSince": MessageLookupByLibrary.simpleMessage(
      "Days since",
    ),
    "appDetailTitle": MessageLookupByLibrary.simpleMessage("Task Detail"),
    "appDetailTypeBadgeIrregular": MessageLookupByLibrary.simpleMessage(
      "Irregular",
    ),
    "appDetailTypeBadgePeriod": MessageLookupByLibrary.simpleMessage(
      "Auto interval",
    ),
    "appDetailTypeBadgeScheduled": m2,
    "appDetailUpdateHistorySuccess": MessageLookupByLibrary.simpleMessage(
      "History updated",
    ),
    "commonCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "commonClose": MessageLookupByLibrary.simpleMessage("Close"),
    "commonErrorTitle": MessageLookupByLibrary.simpleMessage("Error"),
    "commonErrorUnknown": MessageLookupByLibrary.simpleMessage(
      "An unexpected error occurred",
    ),
    "commonOk": MessageLookupByLibrary.simpleMessage("OK"),
    "commonRetry": MessageLookupByLibrary.simpleMessage("Retry"),
    "commonToday": MessageLookupByLibrary.simpleMessage("Today"),
    "commonUndo": MessageLookupByLibrary.simpleMessage("Undo"),
    "commonUnitDay": MessageLookupByLibrary.simpleMessage("d"),
    "commonUnitMonth": MessageLookupByLibrary.simpleMessage("months"),
    "commonUnitWeek": MessageLookupByLibrary.simpleMessage("weeks"),
    "editorChangeIcon": MessageLookupByLibrary.simpleMessage("Change icon"),
    "editorColorNote": MessageLookupByLibrary.simpleMessage(
      "Use colors to group your tasks",
    ),
    "editorLabelColor": MessageLookupByLibrary.simpleMessage("Color"),
    "editorLabelType": MessageLookupByLibrary.simpleMessage("Task type"),
    "editorNameHint": MessageLookupByLibrary.simpleMessage("Enter task name"),
    "editorSaveEdit": MessageLookupByLibrary.simpleMessage("Update"),
    "editorSaveEditSuccess": m3,
    "editorSaveNew": MessageLookupByLibrary.simpleMessage("Register"),
    "editorSaveNewSuccess": m4,
    "editorSectionBasic": MessageLookupByLibrary.simpleMessage("Basic info"),
    "editorSpanLabel": m5,
    "editorSpanPickerTitle": MessageLookupByLibrary.simpleMessage(
      "Repeat interval",
    ),
    "editorTitleEdit": MessageLookupByLibrary.simpleMessage("Edit Task"),
    "editorTitleNew": MessageLookupByLibrary.simpleMessage("Add Task"),
    "editorTypeIrregular": MessageLookupByLibrary.simpleMessage("No due date"),
    "editorTypeIrregularDesc": MessageLookupByLibrary.simpleMessage(
      "For tasks without a fixed schedule",
    ),
    "editorTypePeriod": MessageLookupByLibrary.simpleMessage(
      "Auto-detect interval",
    ),
    "editorTypePeriodDesc": MessageLookupByLibrary.simpleMessage(
      "Predicts next due date from history",
    ),
    "editorTypeScheduled": MessageLookupByLibrary.simpleMessage("Set interval"),
    "editorTypeScheduledDesc": MessageLookupByLibrary.simpleMessage(
      "Manually set the interval to the next due date",
    ),
    "homeComplete": MessageLookupByLibrary.simpleMessage("Done"),
    "homeCompleteCommentPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Add a comment (optional)",
    ),
    "homeCompleteRecord": MessageLookupByLibrary.simpleMessage(
      "Record completion",
    ),
    "homeCompleteSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Complete task",
    ),
    "homeCompleteSuccess": m6,
    "homeDaysOverdue": m7,
    "homeDaysRemaining": m8,
    "homeFilterAll": MessageLookupByLibrary.simpleMessage("All"),
    "homeFilterIrregular": MessageLookupByLibrary.simpleMessage("Irregular"),
    "homeFilterToday": MessageLookupByLibrary.simpleMessage("Today"),
    "homeFilterWeek": MessageLookupByLibrary.simpleMessage("Current week"),
    "homeNoTasksFound": MessageLookupByLibrary.simpleMessage(
      "No matching tasks found",
    ),
    "homeNoTasksYet": MessageLookupByLibrary.simpleMessage("No tasks yet"),
    "homeSearchHint": MessageLookupByLibrary.simpleMessage("Search tasks"),
    "homeSectionOverdue": MessageLookupByLibrary.simpleMessage("Overdue"),
    "homeSectionUpcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "onboardingColorBlue": MessageLookupByLibrary.simpleMessage("AC"),
    "onboardingColorGreen": MessageLookupByLibrary.simpleMessage("Garden"),
    "onboardingColorNone": MessageLookupByLibrary.simpleMessage("Vehicle"),
    "onboardingColorOrange": MessageLookupByLibrary.simpleMessage("Balcony"),
    "onboardingColorRed": MessageLookupByLibrary.simpleMessage("Kitchen"),
    "onboardingColorYellow": MessageLookupByLibrary.simpleMessage("Food"),
    "onboardingDemoTask1": MessageLookupByLibrary.simpleMessage(
      "Balcony bug repellent",
    ),
    "onboardingDemoTask2": MessageLookupByLibrary.simpleMessage("Oil change"),
    "onboardingDemoTask3": MessageLookupByLibrary.simpleMessage(
      "Toothbrush replacement",
    ),
    "onboardingDemoTask4": MessageLookupByLibrary.simpleMessage(
      "Bath mold spray",
    ),
    "onboardingDemoTask5": MessageLookupByLibrary.simpleMessage("Sneaker wash"),
    "onboardingErrorSaveFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to save settings",
    ),
    "onboardingNext": MessageLookupByLibrary.simpleMessage("Next"),
    "onboardingPage1Body": MessageLookupByLibrary.simpleMessage(
      "Car wash, filter cleaning, toothbrush replacement... just register things you tend to forget.",
    ),
    "onboardingPage1Title": MessageLookupByLibrary.simpleMessage(
      "Never forget \"when was I supposed to do this?\"",
    ),
    "onboardingPage2Body": MessageLookupByLibrary.simpleMessage(
      "Intervals are calculated from past records to visualize how often you\'re actually doing each task.",
    ),
    "onboardingPage2Title": MessageLookupByLibrary.simpleMessage(
      "Never wonder \"when should I do this next?\"",
    ),
    "onboardingPage3Body": MessageLookupByLibrary.simpleMessage(
      "Color-code tasks by category or location to make your list easy to scan at a glance.",
    ),
    "onboardingPage3Title": MessageLookupByLibrary.simpleMessage(
      "Group by color to find tasks faster",
    ),
    "onboardingSkip": MessageLookupByLibrary.simpleMessage("Skip"),
    "onboardingStart": MessageLookupByLibrary.simpleMessage(
      "Register your first task",
    ),
    "settingsLicense": MessageLookupByLibrary.simpleMessage(
      "Open Source Licenses",
    ),
    "settingsSectionInfo": MessageLookupByLibrary.simpleMessage("Info"),
    "settingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsTutorial": MessageLookupByLibrary.simpleMessage("Tutorial"),
    "settingsVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "taskErrorDeleteFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to delete",
    ),
    "taskErrorInvalidArgument": MessageLookupByLibrary.simpleMessage(
      "Invalid input",
    ),
    "taskErrorLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load",
    ),
    "taskErrorNotFound": MessageLookupByLibrary.simpleMessage("Task not found"),
    "taskErrorSaveFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to save",
    ),
    "taskErrorUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to update",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Dawnbreaker"),
  };
}
