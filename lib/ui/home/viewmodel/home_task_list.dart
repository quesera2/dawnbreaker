import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';

class HomeTaskList {
  HomeTaskList._({
    required this.overdueTasks,
    required this.upcomingTasks,
  });

  factory HomeTaskList.from({
    required List<TaskItem> tasks,
    required String searchQuery,
    required HomeFilter filter,
    DateTime? now,
  }) {
    // 検索絞り込み
    final searched = searchQuery.isEmpty
        ? tasks
        : tasks.where((t) {
            final q = searchQuery.toLowerCase();
            return t.name.toLowerCase().contains(q) || t.furigana.contains(q);
          });

    // フィルタ絞り込み
    final filtered = switch (filter) {
      HomeFilter.all => searched,
      HomeFilter.overdue => searched.where((t) {
        final p = t.computeProgress(now);
        return p is DueDate && p.isOverdue;
      }),
      HomeFilter.today => searched.where((t) {
        final p = t.computeProgress(now);
        return p is DueDate && !p.isOverdue && p.isToday;
      }),
      HomeFilter.week => searched.where((t) {
        final p = t.computeProgress(now);
        return p is DueDate && !p.isOverdue && p.isCurrentWeek;
      }),
      HomeFilter.irregular => searched.where((t) {
        final p = t.computeProgress(now);
        return p is NoDueDate;
      }),
    };

    final divideByOverdue = filtered.groupListsBy((t) {
      final p = t.computeProgress(now);
      return p is DueDate && p.isOverdue;
    });

    return HomeTaskList._(
      overdueTasks: divideByOverdue[true] ?? [],
      upcomingTasks: divideByOverdue[false] ?? [],
    );
  }

  final List<TaskItem> overdueTasks;
  final List<TaskItem> upcomingTasks;

  bool get hasTasks => overdueTasks.isNotEmpty || upcomingTasks.isNotEmpty;
}
