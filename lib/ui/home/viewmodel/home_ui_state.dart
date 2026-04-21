import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_ui_state.freezed.dart';

enum HomeFilter { all, overdue, today, week }

@freezed
abstract class HomeUiState with _$HomeUiState implements BaseUiState {
  const HomeUiState._();

  const factory HomeUiState({
    @Default(false) bool isLoading,
    ErrorMessage? errorMessage,
    SnackBarMessage? snackBarMessage,
    @Default([]) List<TaskItem> tasks,
    @Default('') String searchQuery,
    @Default(HomeFilter.all) HomeFilter selectedFilter,
  }) = _HomeUiState;

  int get allCount => tasks.length;

  int get overdueCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && p.isOverdue;
  }).length;

  int get todayCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && !p.isOverdue && p.isToday;
  }).length;

  int get weekCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && !p.isOverdue && p.isCurrentWeek;
  }).length;

  HomeTaskList get taskList => HomeTaskList.from(
    tasks: tasks,
    searchQuery: searchQuery,
    filter: selectedFilter,
  );
}
