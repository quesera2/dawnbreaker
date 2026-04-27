import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';

class HomeTaskCount {
  HomeTaskCount._({
    required this.all,
    required this.overdue,
    required this.today,
    required this.week,
    required this.irregular,
  });

  final int all;
  final int overdue;
  final int today;

  /// today を含む
  final int week;

  final int irregular;

  factory HomeTaskCount.from({required List<TaskItem> tasks, DateTime? now}) {
    int overdue = 0, today = 0, week = 0, irregular = 0;

    for (final task in tasks) {
      final p = task.computeProgress(now);
      if (p is NoDueDate) {
        irregular++;
      } else if (p is DueDate) {
        if (p.isOverdue) {
          overdue++;
        } else {
          if (p.isToday) today++;
          if (p.isCurrentWeek) week++;
        }
      }
    }

    return HomeTaskCount._(
      all: tasks.length,
      overdue: overdue,
      today: today,
      week: week,
      irregular: irregular,
    );
  }
}
