import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/task_history.dart';

List<int> intervalDaysForHistory(List<TaskHistory> ascendingHistory) {
  if (ascendingHistory.length < 2) return [];
  return ascendingHistory.skip(1).indexed.map((item) {
    final (index, current) = item;
    final aDate = ascendingHistory[index].executedAt.truncateTime;
    final bDate = current.executedAt.truncateTime;
    return bDate.difference(aDate).inDays;
  }).toList();
}

List<(TaskHistory, int?)> historyAndIntervalPairs(
  List<TaskHistory> ascendingHistory,
) {
  final intervals = intervalDaysForHistory(ascendingHistory);
  final reversedHistory = ascendingHistory.reversed;
  final reversedIntervals = intervals.reversed;
  return reversedHistory
      .mapIndexed(
        (index, history) => (history, reversedIntervals.elementAtOrNull(index)),
      )
      .toList();
}
