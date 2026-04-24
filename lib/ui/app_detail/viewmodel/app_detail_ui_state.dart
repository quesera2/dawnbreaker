import 'package:dawnbreaker/data/model/task_history_stats.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_detail_ui_state.freezed.dart';

@freezed
abstract class AppDetailUiState with _$AppDetailUiState implements BaseUiState {
  const AppDetailUiState._();

  const factory AppDetailUiState({
    @Default(true) bool isLoading,
    TaskItem? task,
    TaskHistoryStats? historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
    @Default(false) bool shouldPop,
    @override ErrorMessage? errorMessage,
    @override SnackBarMessage? snackBarMessage,
  }) = _AppDetailUiState;

  AppDetailUiState updateTaskItem(TaskItem taskItem) {
    final historyStats = TaskHistoryStats.from(taskItem);
    return copyWith(
      isLoading: false,
      task: taskItem,
      historyStats: historyStats,
      daysSinceLastExecution: _calculateDaysSinceLastExecution(taskItem),
      averageIntervalDays: historyStats.averageIntervalDays?.round(),
    );
  }

  AppDetailUiState clearTaskItem() => copyWith(
    isLoading: false,
    task: null,
    historyStats: null,
    daysSinceLastExecution: null,
    averageIntervalDays: null,
  );

  int? _calculateDaysSinceLastExecution(TaskItem task) {
    final last = task.lastExecutedAt;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }
}
