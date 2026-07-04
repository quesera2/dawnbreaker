import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/fake_task_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

extension _HomeTaskListExt on HomeTaskList {
  List<TaskItem> get overdueTasks =>
      taskItemMap[HomeTaskListType.overdueTasks] ?? [];

  List<TaskItem> get upcomingTasks =>
      taskItemMap[HomeTaskListType.upcomingTasks] ?? [];

  List<TaskItem> colorGroup(HomeTaskListType type) => taskItemMap[type] ?? [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 超過: 10日前実行, 5日スケジュール → scheduledAt = 5日前
  // 今日: 7日前実行, 7日スケジュール → scheduledAt = 今日
  // 今週(今日以外): 4日前実行, 7日スケジュール → scheduledAt = 3日後
  // 将来: 今日実行, 14日スケジュール → scheduledAt = 14日後
  // 不定期: period 履歴なし → NoDueDate
  final now = DateTime.now();
  final classificationTasks = [
    TaskItem.scheduled(
      id: 'task-10',
      name: '超過',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 5,
      scheduleUnit: ScheduleUnit.day,
      lastExecutedAt: now.subtract(const Duration(days: 10)),
    ),
    TaskItem.scheduled(
      id: 'task-11',
      name: '今日',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 7,
      scheduleUnit: ScheduleUnit.day,
      lastExecutedAt: now.subtract(const Duration(days: 7)),
    ),
    TaskItem.scheduled(
      id: 'task-12',
      name: '今週',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 7,
      scheduleUnit: ScheduleUnit.day,
      lastExecutedAt: now.subtract(const Duration(days: 4)),
    ),
    TaskItem.scheduled(
      id: 'task-13',
      name: '将来',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 14,
      scheduleUnit: ScheduleUnit.day,
      lastExecutedAt: now,
    ),
    const TaskItem.period(
      id: 'task-14',
      name: '不定期',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      lastExecutedAt: null,
      cachedScheduledAt: null,
    ),
  ];

  group('HomeViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;
    late HomeViewModel viewModel;
    late HomeUiState viewState;

    void setUpContainer({
      List<TaskItem>? tasks,
      FakeSettingsRepository? settings,
    }) {
      fakeRepository = FakeTaskRepository(initialTasks: tasks ?? _testTasks);
      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWith((_) => fakeRepository),
          settingsRepositoryProvider.overrideWith(
            (_) => settings ?? FakeSettingsRepository(),
          ),
        ],
      );
    }

    Future<void> setUpLoaded({
      List<TaskItem>? tasks,
      FakeSettingsRepository? settings,
    }) async {
      setUpContainer(tasks: tasks, settings: settings);
      await waitUntilAsync(
        container,
        homeViewModelProvider,
        (s) => !s.isLoading,
      );
      viewModel = container.read(homeViewModelProvider.notifier);
      container.listen(homeViewModelProvider, (_, next) {
        if (next.hasValue) viewState = next.requireValue;
      }, fireImmediately: true);
    }

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('初期状態', () {
      setUp(setUpContainer);

      test('ローディング中でタスクが表示されない', () {
        final state = container.read(homeViewModelProvider);
        expect(state.isLoading, true);
        expect(state.value?.tasks ?? [], isEmpty);
        expect(state.value?.searchQuery ?? '', '');
      });

      test('タスクがない', () {
        expect(
          container.read(homeViewModelProvider).value?.hasTasks ?? false,
          false,
        );
      });
    });

    group('ロード後', () {
      setUp(() async => setUpLoaded());

      test('タスクが読み込まれる', () {
        expect(viewState.isLoading, false);
        expect(viewState.tasks, _testTasks);
      });

      test('hasTasks は true', () {
        expect(viewState.hasTasks, true);
      });

      test('searchQuery が空のとき全タスクを返す', () {
        final tl = viewState.taskList;
        expect([...tl.overdueTasks, ...tl.upcomingTasks], _testTasks);
      });

      group('updateSearchQuery', () {
        test('一致するタスクに絞り込まれる', () {
          viewModel.updateSearchQuery('歯');
          final tl = viewState.taskList;
          final all = [...tl.overdueTasks, ...tl.upcomingTasks];
          expect(all.isNotEmpty, true);
          expect(all.every((t) => t.name.contains('歯')), true);
        });

        test('一致しない場合は taskList が空になる', () {
          viewModel.updateSearchQuery('zzz');
          final tl = viewState.taskList;
          expect(tl.overdueTasks, isEmpty);
          expect(tl.upcomingTasks, isEmpty);
          expect(tl.isEmpty, true);
        });

        test('検索クエリが更新される', () {
          viewModel.updateSearchQuery('歯');
          expect(viewState.searchQuery, '歯');
        });

        test('同じ値を渡してもステートが変わらない', () {
          viewModel.updateSearchQuery('歯');
          final stateBefore = viewState;

          viewModel.updateSearchQuery('歯');
          final stateAfter = viewState;

          expect(identical(stateBefore, stateAfter), true);
        });
      });

      group('updateFilter', () {
        test('フィルターが切り替わる', () {
          viewModel.updateFilter(HomeFilter.overdue);
          expect(viewState.selectedFilter, HomeFilter.overdue);
        });

        test('同じフィルタを渡してもステートが変わらない', () {
          final before = viewState;
          viewModel.updateFilter(HomeFilter.all);
          expect(identical(viewState, before), true);
        });

        test('overdue フィルタ: 期日のないタスクは除外される', () {
          viewModel.updateFilter(HomeFilter.overdue);
          final tl = viewState.taskList;
          expect(tl.overdueTasks, isEmpty);
          expect(tl.upcomingTasks, isEmpty);
        });

        test('irregular フィルタ: 期日のないタスクが upcoming に返る', () {
          viewModel.updateFilter(HomeFilter.irregular);
          final tl = viewState.taskList;
          expect(tl.upcomingTasks, _testTasks);
        });
      });

      group('recordExecution', () {
        group('正常系', () {
          test('成功時はエラーなし', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.dialogMessage, isNull);
          });

          test('成功時に実行完了の通知がセットされる', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            final msg = viewState.snackBarMessage;
            expect(msg, isA<TaskCompleteSuccess>());
            expect((msg as TaskCompleteSuccess).taskName, _testTasks[0].name);
          });

          test('成功時の通知に undo ハンドラがある', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.snackBarMessage?.handler, isNotNull);
          });

          test('undo ハンドラを呼び出してもエラーが発生しない', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            final handler = viewState.snackBarMessage?.handler;
            expect(handler, isNotNull);
            await handler!();
            expect(viewState.dialogMessage, isNull);
          });

          for (final (comment, expectedComment, description) in [
            (null, null, 'コメントなし'),
            ('良い感じ', '良い感じ', 'コメントあり'),
          ]) {
            test('$descriptionで記録するとリポジトリにコメントが渡される', () async {
              await viewModel.recordExecution(
                _testTasks[0],
                DateTime(2026, 4, 1),
                comment,
              );
              expect(fakeRepository.lastRecordedComment, expectedComment);
              expect(viewState.snackBarMessage, isA<TaskCompleteSuccess>());
            });
          }
        });

        group('異常系', () {
          setUp(() => fakeRepository.shouldThrow = true);

          test('リポジトリがエラーを返すと dialogMessage がセットされる', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.dialogMessage, isA<TaskSaveErrorMessage>());
          });

          test('ハンドラを呼び出すと再実行を試みる', () async {
            await viewModel.recordExecution(
              _testTasks[0],
              DateTime(2026, 4, 1),
              null,
            );
            fakeRepository.shouldThrow = false;
            final previousId = viewState.dialogMessage!.id;
            viewState.dialogMessage!.primaryHandler!.call();
            await pumpEventQueue();
            // 同一IDの場合は新たなエラーダイアログが表示されていない
            expect(viewState.dialogMessage!.id, previousId);
            expect(viewState.snackBarMessage, isA<TaskCompleteSuccess>());
          });
        });
      });
    });

    group('taskList 分類', () {
      setUp(() async => setUpLoaded(tasks: classificationTasks));

      test('all フィルタ: 超過タスクが overdue、それ以外が upcoming に入る', () {
        final tl = viewState.taskList;
        expect(tl.overdueTasks.length, 1);
        expect(tl.overdueTasks.first.name, '超過');
        expect(tl.upcomingTasks.length, 4);
      });

      test('overdue フィルタ: 超過タスクのみ残る', () {
        viewModel.updateFilter(HomeFilter.overdue);
        final tl = viewState.taskList;
        expect(tl.overdueTasks.map((t) => t.name), ['超過']);
        expect(tl.upcomingTasks, isEmpty);
      });

      test('today フィルタ: 今日期限タスクのみ upcoming に入る', () {
        viewModel.updateFilter(HomeFilter.today);
        final tl = viewState.taskList;
        expect(tl.overdueTasks, isEmpty);
        expect(tl.upcomingTasks.map((t) => t.name), ['今日']);
      });

      test('week フィルタ: 今日を含む今週内タスクが upcoming に入る', () {
        viewModel.updateFilter(HomeFilter.week);
        final tl = viewState.taskList;
        expect(tl.overdueTasks, isEmpty);
        expect(tl.upcomingTasks.map((t) => t.name), ['今日', '今週']);
      });

      test('irregular フィルタ: 期日のないタスクのみ upcoming に入る', () {
        viewModel.updateFilter(HomeFilter.irregular);
        final tl = viewState.taskList;
        expect(tl.overdueTasks, isEmpty);
        expect(tl.upcomingTasks.map((t) => t.name), ['不定期']);
      });

      test('タスクがあるとき isEmpty は false', () {
        expect(viewState.taskList.isEmpty, isFalse);
      });

      test('一致しない検索クエリのとき isEmpty は true', () {
        viewModel.updateSearchQuery('zzz');
        expect(viewState.taskList.isEmpty, isTrue);
      });
    });

    group('byColor モード', () {
      setUp(
        () async => setUpLoaded(
          tasks: _colorTasks,
          settings: FakeSettingsRepository(
            initialDisplayMode: HomeDisplayMode.byColor,
          ),
        ),
      );

      test('色ごとにグループ化される', () {
        final tl = viewState.taskList;
        expect(tl.colorGroup(.red).map((t) => t.name), ['レッドA', 'レッドB']);
        expect(tl.colorGroup(.blue).map((t) => t.name), ['ブルー']);
        expect(tl.colorGroup(.none).map((t) => t.name), ['グレー']);
      });

      test('タスクのない色はグループが存在しない', () {
        final tl = viewState.taskList;
        expect(tl.taskItemMap.containsKey(HomeTaskListType.yellow), isFalse);
        expect(tl.taskItemMap.containsKey(HomeTaskListType.green), isFalse);
        expect(tl.taskItemMap.containsKey(HomeTaskListType.orange), isFalse);
      });

      test('タスクがあるとき isEmpty は false', () {
        expect(viewState.taskList.isEmpty, isFalse);
      });

      test('一致しない検索クエリのとき isEmpty は true', () {
        viewModel.updateSearchQuery('zzz');
        expect(viewState.taskList.isEmpty, isTrue);
      });

      test('検索クエリで絞り込まれる', () {
        viewModel.updateSearchQuery('レッド');
        final tl = viewState.taskList;
        expect(tl.colorGroup(.red).length, 2);
        expect(tl.colorGroup(.blue), isEmpty);
        expect(tl.colorGroup(.none), isEmpty);
      });
    });

    group('taskCount', () {
      setUp(() async => setUpLoaded(tasks: classificationTasks));

      test('all は全タスク数を返す', () {
        expect(viewState.taskCount.all, 5);
      });

      test('overdue は超過タスクのみカウントする', () {
        expect(viewState.taskCount.overdue, 1);
      });

      test('today は今日期限タスクのみカウントする', () {
        expect(viewState.taskCount.today, 1);
      });

      test('week は today を含む今週内タスクをカウントする', () {
        expect(viewState.taskCount.week, 2);
      });

      test('irregular は期日のないタスクのみカウントする', () {
        expect(viewState.taskCount.irregular, 1);
      });
    });
  });
}

final _colorTasks = [
  const TaskItem.period(
    id: 'task-30',
    name: 'レッドA',
    furigana: 'れっどえー',
    icon: '📝',
    color: TaskColor.red,
    lastExecutedAt: null,
    cachedScheduledAt: null,
  ),
  const TaskItem.period(
    id: 'task-31',
    name: 'レッドB',
    furigana: 'れっどびー',
    icon: '📝',
    color: TaskColor.red,
    lastExecutedAt: null,
    cachedScheduledAt: null,
  ),
  const TaskItem.period(
    id: 'task-32',
    name: 'ブルー',
    furigana: 'ぶるー',
    icon: '📝',
    color: TaskColor.blue,
    lastExecutedAt: null,
    cachedScheduledAt: null,
  ),
  const TaskItem.period(
    id: 'task-33',
    name: 'グレー',
    furigana: 'ぐれー',
    icon: '📝',
    color: TaskColor.none,
    lastExecutedAt: null,
    cachedScheduledAt: null,
  ),
];

final _testTasks = [
  TaskItem.period(
    id: 'task-1',
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '📝',
    color: TaskColor.blue,
    lastExecutedAt: DateTime(2026, 1, 1),
    cachedScheduledAt: null,
  ),
  TaskItem.period(
    id: 'task-2',
    name: '散髪',
    furigana: 'さんぱつ',
    icon: '📝',
    color: TaskColor.none,
    lastExecutedAt: DateTime(2026, 1, 1),
    cachedScheduledAt: null,
  ),
];
