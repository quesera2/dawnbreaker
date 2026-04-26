import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 21, 12, 0, 0);

  // scheduledAt = lastExecutedAt + intervalDays日
  TaskItem makeScheduled({
    required int id,
    required String name,
    required DateTime lastExecutedAt,
    required int intervalDays,
  }) => TaskItem.scheduled(
    id: id,
    name: name,
    furigana: '',
    icon: '📝',
    color: TaskColor.none,
    scheduleValue: intervalDays,
    scheduleUnit: ScheduleUnit.day,
    taskHistory: [TaskHistory(id: id, executedAt: lastExecutedAt, comment: null)],
  );

  // 超過: 10日前が最後、5日周期 → scheduledAt は5日前
  final overdueTask = makeScheduled(
    id: 1, name: '超過タスク',
    lastExecutedAt: now.subtract(const Duration(days: 10)),
    intervalDays: 5,
  );

  // 今日: 7日前が最後、7日周期 → scheduledAt = now (正午)
  final todayTask = makeScheduled(
    id: 2, name: '今日のタスク',
    lastExecutedAt: now.subtract(const Duration(days: 7)),
    intervalDays: 7,
  );

  // 今週内（今日ではない）: 4日前が最後、7日周期 → scheduledAt は3日後
  final weekTask = makeScheduled(
    id: 3, name: '今週のタスク',
    lastExecutedAt: now.subtract(const Duration(days: 4)),
    intervalDays: 7,
  );

  // 今週外: 今日が最後、14日周期 → scheduledAt は14日後
  final futureTask = makeScheduled(
    id: 4, name: '将来のタスク',
    lastExecutedAt: now,
    intervalDays: 14,
  );

  // 予定なし (履歴なし period)
  const noDateTask = TaskItem.period(
    id: 5, name: '予定なしタスク', furigana: '',
    icon: '📝', color: TaskColor.none, taskHistory: [],
  );

  // 不定期タスク (IrregularTaskItem は常に NoDueDate)
  const irregularTask = TaskItem.irregular(
    id: 6, name: '不定期タスク', furigana: '',
    icon: '📝', color: TaskColor.none, taskHistory: [],
  );

  final allTasks = [overdueTask, todayTask, weekTask, futureTask, noDateTask, irregularTask];

  group('HomeTaskList overdueTasks / upcomingTasks', () {
    test('all フィルタ: overdueTasks に超過タスク、upcomingTasks にそれ以外', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.all, now: now,
      );
      expect(tl.overdueTasks, [overdueTask]);
      expect(tl.upcomingTasks, [todayTask, weekTask, futureTask, noDateTask, irregularTask]);
    });

    test('overdue フィルタ: overdueTasks のみ', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.overdue, now: now,
      );
      expect(tl.overdueTasks, [overdueTask]);
      expect(tl.upcomingTasks, isEmpty);
    });

    test('today フィルタ: 今日期限のタスクのみ upcomingTasks に入る', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.today, now: now,
      );
      expect(tl.overdueTasks, isEmpty);
      expect(tl.upcomingTasks, [todayTask]);
    });

    test('week フィルタ: 今日を含む7日以内が upcomingTasks に入る', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.week, now: now,
      );
      expect(tl.overdueTasks, isEmpty);
      expect(tl.upcomingTasks, [todayTask, weekTask]);
    });
  });

  group('HomeTaskList irregular フィルタ', () {
    test('irregular フィルタ: NoDueDate タスクのみ upcomingTasks に入る', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.irregular, now: now,
      );
      expect(tl.overdueTasks, isEmpty);
      expect(tl.upcomingTasks, [noDateTask, irregularTask]);
    });

    test('irregular フィルタ: DueDate タスクは除外される', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.irregular, now: now,
      );
      expect(tl.upcomingTasks, isNot(contains(overdueTask)));
      expect(tl.upcomingTasks, isNot(contains(todayTask)));
      expect(tl.upcomingTasks, isNot(contains(weekTask)));
      expect(tl.upcomingTasks, isNot(contains(futureTask)));
    });
  });

  group('HomeTaskList 検索', () {
    test('searchQuery で名前一致するタスクのみ残る', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '超過', filter: HomeFilter.all, now: now,
      );
      expect(tl.overdueTasks, [overdueTask]);
      expect(tl.upcomingTasks, isEmpty);
    });

    test('searchQuery が空のとき全件返す', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: '', filter: HomeFilter.all, now: now,
      );
      expect(tl.overdueTasks.length + tl.upcomingTasks.length, 6);
    });

    test('一致しない searchQuery のとき両リストが空', () {
      final tl = HomeTaskList.from(
        tasks: allTasks, searchQuery: 'zzz', filter: HomeFilter.all, now: now,
      );
      expect(tl.overdueTasks, isEmpty);
      expect(tl.upcomingTasks, isEmpty);
    });
  });
}
