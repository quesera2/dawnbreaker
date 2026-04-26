import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
      container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWith((_) => fakeRepository)],
      );
    });

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('初期状態', () {
      test('isLoading: true でタスクが空', () {
        final state = container.read(homeViewModelProvider);
        expect(state.isLoading, true);
        expect(state.tasks, isEmpty);
        expect(state.searchQuery, '');
      });

      test('hasTasks は false', () {
        expect(container.read(homeViewModelProvider).hasTasks, false);
      });
    });

    group('ロード後', () {
      setUp(() async {
        await _waitUntilLoaded(container);
      });

      test('isLoading: false になりタスクが読み込まれる', () {
        final state = container.read(homeViewModelProvider);
        expect(state.isLoading, false);
        expect(state.tasks, _testTasks);
      });

      test('hasTasks は true', () {
        expect(container.read(homeViewModelProvider).hasTasks, true);
      });

      test('searchQuery が空のとき overdueTasks + upcomingTasks は全タスクを返す', () {
        final taskList = container.read(homeViewModelProvider).taskList;
        final all = [...taskList.overdueTasks, ...taskList.upcomingTasks];
        expect(all, _testTasks);
      });

      test('updateSearchQuery で絞り込まれる', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final taskList = container.read(homeViewModelProvider).taskList;
        final all = [...taskList.overdueTasks, ...taskList.upcomingTasks];
        expect(all.isNotEmpty, true);
        expect(all.every((t) => t.name.contains('歯')), true);
      });

      test('一致しない searchQuery のとき結果は空', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('zzz');
        final taskList = container.read(homeViewModelProvider).taskList;
        expect(taskList.overdueTasks, isEmpty);
        expect(taskList.upcomingTasks, isEmpty);
      });

      test('updateSearchQuery で searchQuery が更新される', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        expect(container.read(homeViewModelProvider).searchQuery, '歯');
      });

      test('updateSearchQuery に同じ値を渡してもステートが変わらない', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final stateBefore = container.read(homeViewModelProvider);

        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final stateAfter = container.read(homeViewModelProvider);

        expect(identical(stateBefore, stateAfter), true);
      });
    });

    group('updateFilter', () {
      setUp(() async {
        await _waitUntilLoaded(container);
      });

      test('selectedFilter が変わる', () {
        container
            .read(homeViewModelProvider.notifier)
            .updateFilter(HomeFilter.overdue);
        expect(
          container.read(homeViewModelProvider).selectedFilter,
          HomeFilter.overdue,
        );
      });

      test('同じフィルタを渡してもステートが変わらない', () {
        final before = container.read(homeViewModelProvider);
        container
            .read(homeViewModelProvider.notifier)
            .updateFilter(HomeFilter.all);
        expect(identical(container.read(homeViewModelProvider), before), true);
      });

      test('overdue フィルタ: DueDate でないタスクは除外される', () {
        // _testTasks は PeriodTask 履歴1件 → NoDueDate なので overdue では空
        container
            .read(homeViewModelProvider.notifier)
            .updateFilter(HomeFilter.overdue);
        final taskList = container.read(homeViewModelProvider).taskList;
        expect(taskList.overdueTasks, isEmpty);
        expect(taskList.upcomingTasks, isEmpty);
      });

      test('irregular フィルタ: NoDueDate タスクが upcomingTasks に返る', () {
        // _testTasks はいずれも NoDueDate
        container
            .read(homeViewModelProvider.notifier)
            .updateFilter(HomeFilter.irregular);
        final taskList = container.read(homeViewModelProvider).taskList;
        expect(taskList.upcomingTasks, _testTasks);
      });
    });

    group('recordCompletion', () {
      setUp(() async {
        await _waitUntilLoaded(container);
      });

      test('成功時はエラーなし', () async {
        await container
            .read(homeViewModelProvider.notifier)
            .recordCompletion(_testTasks[0], DateTime(2026, 4, 1));

        expect(container.read(homeViewModelProvider).errorMessage, isNull);
      });

      test('成功時に TaskCompleteSuccessSnackMessage がセットされる', () async {
        await container
            .read(homeViewModelProvider.notifier)
            .recordCompletion(_testTasks[0], DateTime(2026, 4, 1));

        final msg = container.read(homeViewModelProvider).snackBarMessage;
        expect(msg, isA<TaskCompleteSuccessSnackMessage>());
        expect(
          (msg as TaskCompleteSuccessSnackMessage).taskName,
          _testTasks[0].name,
        );
      });

      test('成功時の snackBarMessage に undo ハンドラがある', () async {
        await container
            .read(homeViewModelProvider.notifier)
            .recordCompletion(_testTasks[0], DateTime(2026, 4, 1));

        final msg = container.read(homeViewModelProvider).snackBarMessage;
        expect(msg?.handler, isNotNull);
      });

      test('リポジトリが例外を投げると errorMessage がセットされる', () async {
        final throwingRepo = FakeTaskRepository(shouldThrow: true);
        final c = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => throwingRepo),
          ],
        );
        addTearDown(() {
          c.dispose();
          throwingRepo.dispose();
        });
        await _waitUntilLoaded(c);

        await c
            .read(homeViewModelProvider.notifier)
            .recordCompletion(_testTasks[0], DateTime(2026, 4, 1));

        expect(c.read(homeViewModelProvider).errorMessage, isNotNull);
      });

      test('成功時の handler を呼び出してもエラーが発生しない', () async {
        await container
            .read(homeViewModelProvider.notifier)
            .recordCompletion(_testTasks[0], DateTime(2026, 4, 1));

        final handler =
            container.read(homeViewModelProvider).snackBarMessage?.handler;
        expect(handler, isNotNull);

        await handler!();

        expect(container.read(homeViewModelProvider).errorMessage, isNull);
      });
    });

    group('taskCount', () {
      final now = DateTime.now();

      // 超過: 10日前実行, 5日スケジュール → scheduledAt = 5日前
      // 今日: 7日前実行, 7日スケジュール → scheduledAt = 今日
      // 今週(今日以外): 4日前実行, 7日スケジュール → scheduledAt = 3日後
      // 将来: 今日実行, 14日スケジュール → scheduledAt = 14日後
      // 不定期: period 履歴なし → NoDueDate
      final countTasks = [
        TaskItem.scheduled(
          id: 10, name: '超過', furigana: '', icon: '📝', color: TaskColor.none,
          scheduleValue: 5, scheduleUnit: ScheduleUnit.day,
          taskHistory: [TaskHistory(id: 10, executedAt: now.subtract(const Duration(days: 10)), comment: null)],
        ),
        TaskItem.scheduled(
          id: 11, name: '今日', furigana: '', icon: '📝', color: TaskColor.none,
          scheduleValue: 7, scheduleUnit: ScheduleUnit.day,
          taskHistory: [TaskHistory(id: 11, executedAt: now.subtract(const Duration(days: 7)), comment: null)],
        ),
        TaskItem.scheduled(
          id: 12, name: '今週', furigana: '', icon: '📝', color: TaskColor.none,
          scheduleValue: 7, scheduleUnit: ScheduleUnit.day,
          taskHistory: [TaskHistory(id: 12, executedAt: now.subtract(const Duration(days: 4)), comment: null)],
        ),
        TaskItem.scheduled(
          id: 13, name: '将来', furigana: '', icon: '📝', color: TaskColor.none,
          scheduleValue: 14, scheduleUnit: ScheduleUnit.day,
          taskHistory: [TaskHistory(id: 13, executedAt: now, comment: null)],
        ),
        const TaskItem.period(
          id: 14, name: '不定期', furigana: '', icon: '📝',
          color: TaskColor.none, taskHistory: [],
        ),
      ];

      late ProviderContainer countContainer;
      late FakeTaskRepository countRepo;

      setUp(() async {
        countRepo = FakeTaskRepository(initialTasks: countTasks);
        countContainer = ProviderContainer(
          overrides: [taskRepositoryProvider.overrideWith((_) => countRepo)],
        );
        await _waitUntilLoaded(countContainer);
      });

      tearDown(() {
        countContainer.dispose();
        countRepo.dispose();
      });

      test('all は全タスク数を返す', () {
        expect(countContainer.read(homeViewModelProvider).taskCount.all, 5);
      });

      test('overdue は超過タスクのみカウントする', () {
        expect(countContainer.read(homeViewModelProvider).taskCount.overdue, 1);
      });

      test('today は今日期限タスクのみカウントする', () {
        expect(countContainer.read(homeViewModelProvider).taskCount.today, 1);
      });

      test('week は today を含む今週内タスクをカウントする', () {
        expect(countContainer.read(homeViewModelProvider).taskCount.week, 2);
      });

      test('irregular は NoDueDate タスクのみカウントする', () {
        expect(
          countContainer.read(homeViewModelProvider).taskCount.irregular,
          1,
        );
      });
    });
  });
}

final _testTasks = [
  TaskItem.period(
    id: 1,
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '📝',
    color: TaskColor.blue,
    taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1), comment: null)],
  ),
  TaskItem.period(
    id: 2,
    name: '散髪',
    furigana: 'さんぱつ',
    icon: '📝',
    color: TaskColor.none,
    taskHistory: [TaskHistory(id: 2, executedAt: DateTime(2026, 1, 1), comment: null)],
  ),
];

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(homeViewModelProvider, (_, next) {
    if (!next.isLoading && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future;
  sub.close();
}
