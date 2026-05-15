import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

extension _HomeTaskListExt on HomeTaskList {
  List<TaskItem> get overdueTasks =>
      taskItemMap[HomeTaskListType.overdueTasks] ?? [];

  List<TaskItem> get upcomingTasks =>
      taskItemMap[HomeTaskListType.upcomingTasks] ?? [];
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
      id: 10,
      name: '超過',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 5,
      scheduleUnit: ScheduleUnit.day,
      taskHistory: [
        TaskHistory(
          id: 10,
          executedAt: now.subtract(const Duration(days: 10)),
          comment: null,
        ),
      ],
    ),
    TaskItem.scheduled(
      id: 11,
      name: '今日',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 7,
      scheduleUnit: ScheduleUnit.day,
      taskHistory: [
        TaskHistory(
          id: 11,
          executedAt: now.subtract(const Duration(days: 7)),
          comment: null,
        ),
      ],
    ),
    TaskItem.scheduled(
      id: 12,
      name: '今週',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 7,
      scheduleUnit: ScheduleUnit.day,
      taskHistory: [
        TaskHistory(
          id: 12,
          executedAt: now.subtract(const Duration(days: 4)),
          comment: null,
        ),
      ],
    ),
    TaskItem.scheduled(
      id: 13,
      name: '将来',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      scheduleValue: 14,
      scheduleUnit: ScheduleUnit.day,
      taskHistory: [TaskHistory(id: 13, executedAt: now, comment: null)],
    ),
    const TaskItem.period(
      id: 14,
      name: '不定期',
      furigana: '',
      icon: '📝',
      color: TaskColor.none,
      taskHistory: [],
    ),
  ];

  group('HomeViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;
    late HomeViewModel viewModel;
    late HomeUiState viewState;

    void setUpContainer({List<TaskItem>? tasks}) {
      fakeRepository = FakeTaskRepository(initialTasks: tasks ?? _testTasks);
      container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWith((_) => fakeRepository)],
      );
    }

    Future<void> setUpLoaded({List<TaskItem>? tasks}) async {
      setUpContainer(tasks: tasks);
      await waitUntil(container, homeViewModelProvider, (s) => !s.isLoading);
      viewModel = container.read(homeViewModelProvider.notifier);
      container.listen(
        homeViewModelProvider,
        (_, next) => viewState = next,
        fireImmediately: true,
      );
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
        expect(state.tasks, isEmpty);
        expect(state.searchQuery, '');
      });

      test('タスクがない', () {
        expect(container.read(homeViewModelProvider).hasTasks, false);
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

final _testTasks = [
  TaskItem.period(
    id: 1,
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '📝',
    color: TaskColor.blue,
    taskHistory: [
      TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1), comment: null),
    ],
  ),
  TaskItem.period(
    id: 2,
    name: '散髪',
    furigana: 'さんぱつ',
    icon: '📝',
    color: TaskColor.none,
    taskHistory: [
      TaskHistory(id: 2, executedAt: DateTime(2026, 1, 1), comment: null),
    ],
  ),
];
