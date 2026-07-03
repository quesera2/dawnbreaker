import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/core/util/iterable_util.dart';
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
    // watchTaskHistory から届く直近件数のみの履歴（新しい順ではなく実行日時の昇順）
    @Default([]) List<TaskHistory> recentHistory,
    TaskHistoryStats? historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
    // recentHistory より過去の履歴。スクロールで追加取得したページを保持する
    @Default([]) List<TaskHistory> olderHistory,
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

  AppDetailUiState updateRecentHistory(List<TaskHistory> recentHistory) {
    final historyStats = TaskHistoryStats.from(recentHistory);
    return copyWith(
      recentHistory: recentHistory,
      historyStats: historyStats,
      averageIntervalDays: historyStats.averageIntervalDays?.round(),
    );
  }

  // recentHistory（直近のリアルタイム反映分）と olderHistory（追加ロード分）を
  // idで重複排除したうえで executedAt により全体を再ソートした、画面表示用の履歴一覧。
  // 「どちらの配列に入っているか」に依存せず、実際の日付で正しい順序になる。
  // recentHistory（headの最新情報）を後に渡し、同idの場合はそちらを優先する。
  List<TaskHistory> get mergedAscendingHistory {
    if (task == null) return [];
    return distinctBy([...olderHistory, ...recentHistory], (h) => h.id)
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
