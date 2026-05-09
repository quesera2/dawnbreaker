import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/task_history_stats.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
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
    @override DialogMessage? dialogMessage,
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

  int? _calculateDaysSinceLastExecution(TaskItem task) {
    final last = task.lastExecutedAt?.truncateTime;
    if (last == null) return null;
    final now = DateTime.now().truncateTime;
    return now.difference(last).inDays;
  }
}
