import 'dart:async';

import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
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
        expect(container.read(homeViewModelProvider).taskList.hasTasks, false);
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
        expect(container.read(homeViewModelProvider).taskList.hasTasks, true);
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
  });
}

final _testTasks = [
  TaskItem.period(
    id: 1,
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '📝',
    color: TaskColor.blue,
    taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1))],
  ),
  TaskItem.period(
    id: 2,
    name: '散髪',
    furigana: 'さんぱつ',
    icon: '📝',
    color: TaskColor.none,
    taskHistory: [TaskHistory(id: 2, executedAt: DateTime(2026, 1, 1))],
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
