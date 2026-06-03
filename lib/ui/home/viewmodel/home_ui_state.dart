import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_count.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_ui_state.freezed.dart';

enum HomeFilter { all, overdue, today, week, irregular }

@freezed
abstract class HomeUiState with _$HomeUiState implements BaseUiState {
  const HomeUiState._();

  const factory HomeUiState({
    @Default(false) bool isLoading,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
    @Default([]) List<TaskItem> tasks,
    @Default('') String searchQuery,
    @Default(HomeFilter.all) HomeFilter selectedFilter,
    @Default(HomeDisplayMode.timeline) HomeDisplayMode displayMode,
    @Default([]) List<ColorSetting> colorSettings,
    @Default(true) bool progressBarAnimationEnabled,
  }) = _HomeUiState;

  bool get hasTasks => tasks.isNotEmpty;

  HomeTaskCount get taskCount => HomeTaskCount.from(tasks: tasks);

  HomeTaskList get taskList => HomeTaskList.from(
    displayMode: displayMode,
    tasks: tasks,
    searchQuery: searchQuery,
    filter: selectedFilter,
    colorSettings: colorSettings,
  );
}
