import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_ui_state.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;
    late EditorViewModel viewModel;
    late EditorUiState viewState;

    void setUpContainer() {
      fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWith((_) => fakeRepository),
        ],
      );
    }

    Future<void> setUpLoaded({int? taskId}) async {
      setUpContainer();
      final p = editorViewModelProvider(taskId: taskId);
      await waitUntil(container, p, (s) => !s.isLoading);
      viewModel = container.read(p.notifier);
      container.listen(p, (_, next) => viewState = next, fireImmediately: true);
    }

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('新規作成モード', () {
      setUp(() {
        setUpContainer();
        final p = editorViewModelProvider();
        viewModel = container.read(p.notifier);
        container.listen(p, (_, next) => viewState = next, fireImmediately: true);
      });

      test('初期状態が正しい', () {
        expect(viewState.isLoading, false);
        expect(viewState.icon, '📝');
        expect(viewState.name, '');
        expect(viewState.type, TaskType.period);
        expect(viewState.color, TaskColor.none);
        expect(viewState.isSaved, false);
        expect(viewState.dialogMessage, isNull);
      });

      test('name が空のとき canSave は false', () {
        expect(viewState.canSave, false);
      });

      test('名前を入力すると canSave が true になる', () {
        viewModel.updateName('散髪');
        expect(viewState.name, '散髪');
        expect(viewState.canSave, true);
      });

      test('アイコンを変更できる', () {
        viewModel.updateIcon('✂️');
        expect(viewState.icon, '✂️');
      });

      test('タスク種別を変更できる', () {
        viewModel.updateType(TaskType.scheduled);
        expect(viewState.type, TaskType.scheduled);
      });

      test('カラーを変更できる', () {
        viewModel.updateColor(TaskColor.blue);
        expect(viewState.color, TaskColor.blue);
      });

      test('スケジュール間隔を変更できる', () {
        viewModel.updateScheduleValue(3);
        expect(viewState.scheduleValue, 3);
      });

      test('スケジュール単位を変更できる', () {
        viewModel.updateScheduleUnit(ScheduleUnit.week);
        expect(viewState.scheduleUnit, ScheduleUnit.week);
      });

      test('name が空のとき save() は何もしない', () async {
        await viewModel.save();
        expect(viewState.isSaved, false);
        expect(viewState.isLoading, false);
      });

      test('period タスクを save() すると isSaved: true になる', () async {
        viewModel.updateName('散髪');
        await viewModel.save();
        expect(viewState.isSaved, true);
      });

      test('scheduled タスクを save() すると isSaved: true になる', () async {
        viewModel
          ..updateName('虫避け交換')
          ..updateType(TaskType.scheduled);
        await viewModel.save();
        expect(viewState.isSaved, true);
      });

      test('save() 成功後に作成完了の通知がセットされる', () async {
        viewModel.updateName('散髪');
        await viewModel.save();
        expect(viewState.snackBarMessage, isA<TaskCreateSuccess>());
        expect((viewState.snackBarMessage as TaskCreateSuccess).taskName, '散髪');
        expect(viewState.snackBarMessage!.handler, isNotNull);
      });

      test('create の undo ハンドラを実行するとタスクがリポジトリから削除される', () async {
        viewModel.updateName('散髪');
        await viewModel.save();
        expect(viewState.snackBarMessage, isA<TaskCreateSuccess>());

        // undo 前はタスクが存在する
        expect(fakeRepository.containsTask(100), true);

        await viewState.snackBarMessage!.handler!();

        expect(fakeRepository.containsTask(100), false);
      });

      test('save() でリポジトリがエラーを返すと errorMessage が設定される', () async {
        final throwingRepo = FakeTaskRepository(shouldThrow: true);
        final c = ProviderContainer(
          overrides: [taskRepositoryProvider.overrideWith((_) => throwingRepo)],
        );
        final p = editorViewModelProvider();
        EditorUiState? localState;
        c.listen(p, (_, next) => localState = next, fireImmediately: true);
        addTearDown(() {
          c.dispose();
          throwingRepo.dispose();
        });
        final n = c.read(p.notifier);
        n.updateName('散髪');
        await n.save();
        expect(localState!.isSaved, false);
        expect(localState!.isSaving, false);
        expect(localState!.dialogMessage, isNotNull);
      });
    });

    group('編集モード', () {
      group('初期状態', () {
        setUp(setUpContainer);

        test('データ取得中である', () {
          final state = container.read(editorViewModelProvider(taskId: 1));
          expect(state.isLoading, true);
        });
      });

      group('ロード後', () {
        group('period タスク', () {
          setUp(() async => setUpLoaded(taskId: 1));

          test('タスクの内容が反映される', () {
            expect(viewState.isLoading, false);
            expect(viewState.name, '歯ブラシ交換');
            expect(viewState.icon, '🪥');
            expect(viewState.type, TaskType.period);
            expect(viewState.color, TaskColor.blue);
            expect(viewState.taskHistory, hasLength(1));
          });
        });

        group('scheduled タスク', () {
          setUp(() async => setUpLoaded(taskId: 2));

          test('スケジュール設定が反映される', () {
            expect(viewState.isLoading, false);
            expect(viewState.type, TaskType.scheduled);
            expect(viewState.scheduleValue, 2);
            expect(viewState.scheduleUnit, ScheduleUnit.week);
          });
        });

        group('タスクが存在しない場合', () {
          setUp(() async => setUpLoaded(taskId: 999));

          test('読み込みエラーが通知される', () {
            expect(viewState.isLoading, false);
            expect(viewState.dialogMessage, isNotNull);
          });
        });

        group('save', () {
          setUp(() async => setUpLoaded(taskId: 1));

          group('正常系', () {
            test('編集内容を保存できる', () async {
              viewModel.updateColor(TaskColor.green);
              await viewModel.save();
              expect(viewState.isSaved, true);
            });

            test('保存成功後に更新完了の通知がセットされる', () async {
              viewModel.updateName('新しい名前');
              await viewModel.save();
              expect(viewState.snackBarMessage, isA<TaskUpdateSuccess>());
              expect(
                (viewState.snackBarMessage as TaskUpdateSuccess).taskName,
                '新しい名前',
              );
              expect(viewState.snackBarMessage!.handler, isNotNull);
            });

            test('undo ハンドラを実行すると元のタスクの状態に戻る', () async {
              viewModel.updateName('新しい名前');
              viewModel.updateColor(TaskColor.green);
              await viewModel.save();

              expect(viewState.snackBarMessage, isA<TaskUpdateSuccess>());

              // undo 前は更新後の値
              expect(fakeRepository.taskById(1)?.name, '新しい名前');
              expect(fakeRepository.taskById(1)?.color, TaskColor.green);

              await viewState.snackBarMessage!.handler!();

              // undo 後は元の値に戻っている
              expect(fakeRepository.taskById(1)?.name, '歯ブラシ交換');
              expect(fakeRepository.taskById(1)?.color, TaskColor.blue);
            });
          });
        });
      });
    });
  });
}

final _testTasks = [
  TaskItem.period(
    id: 1,
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '🪥',
    color: TaskColor.blue,
    taskHistory: [
      TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1), comment: null),
    ],
  ),
  TaskItem.scheduled(
    id: 2,
    name: '虫避け交換',
    furigana: 'むしよけこうかん',
    icon: '🐝',
    color: TaskColor.orange,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.week,
    taskHistory: [
      TaskHistory(id: 2, executedAt: DateTime(2026, 1, 1), comment: null),
    ],
  ),
];
