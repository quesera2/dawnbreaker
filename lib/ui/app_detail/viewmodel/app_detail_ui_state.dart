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
    TaskHistoryStats? historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
    // task.taskHistory（直近件のみ）より過去の履歴。スクロールで追加取得したページを保持する
    @Default([]) List<TaskHistory> olderHistory,
    @Default(true) bool hasMoreHistory,
    @Default(false) bool isLoadingMoreHistory,
    @Default(false) bool shouldPop,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
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

  // task.taskHistory（直近のリアルタイム反映分）と olderHistory（追加ロード分）を
  // idで重複排除したうえで executedAt により全体を再ソートした、画面表示用の履歴一覧。
  // 「どちらの配列に入っているか」に依存せず、実際の日付で正しい順序になる。
  List<TaskHistory> get mergedAscendingHistory {
    final currentTask = task;
    if (currentTask == null) return [];
    final byId = <String, TaskHistory>{};
    for (final h in olderHistory) {
      byId[h.id] = h;
    }
    // taskHistory（headの最新情報）が同idの場合は優先して上書きする
    for (final h in currentTask.taskHistory) {
      byId[h.id] = h;
    }
    return byId.values.toList()
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
  }

  List<(TaskHistory, int?)> get displayedHistoryAndInterval =>
      historyAndIntervalPairs(mergedAscendingHistory);

  int? _calculateDaysSinceLastExecution(TaskItem task) {
    final last = task.lastExecutedAt?.truncateTime;
    if (last == null) return null;
    final now = DateTime.now().truncateTime;
    return now.difference(last).inDays;
  }
}
