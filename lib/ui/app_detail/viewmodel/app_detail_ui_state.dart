import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';
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
    // 実行日時の昇順（新しい順ではない）。fetchTaskHistory でページを読み込むたびに先頭へ追加する
    @Default([]) List<TaskHistory> history,
    TaskHistoryStats? historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
    @Default(true) bool hasMoreHistory,
    @Default(false) bool isLoadingMoreHistory,
    @Default(false) bool shouldPop,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _AppDetailUiState;

  AppDetailUiState updateTaskItem(TaskItem taskItem) => copyWith(
    isLoading: false,
    task: taskItem,
    daysSinceLastExecution: _calculateDaysSinceLastExecution(taskItem),
  );

  AppDetailUiState updateHistory(List<TaskHistory> history) {
    final historyStats = TaskHistoryStats.from(history);
    return copyWith(
      isLoading: false,
      history: history,
      historyStats: historyStats,
      averageIntervalDays: historyStats.averageIntervalDays?.round(),
    );
  }

  List<(TaskHistory, int?)> get displayedHistoryAndInterval =>
      historyAndIntervalPairs(history);

  int? _calculateDaysSinceLastExecution(TaskItem task) {
    final last = task.lastExecutedAt?.truncateTime;
    if (last == null) return null;
    final now = DateTime.now().truncateTime;
    return now.difference(last).inDays;
  }
}
