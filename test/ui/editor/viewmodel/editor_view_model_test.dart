import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('新規作成モード', () {
      late ProviderSubscription<EditorViewModel> sub;
      late EditorViewModel viewModel;

      setUp(() {
        fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
        container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => fakeRepository),
          ],
        );
        sub = container.listen(editorViewModelProvider().notifier, (_, _) {});
        viewModel = container.read(editorViewModelProvider().notifier);
      });

      tearDown(() => sub.close());

      test('初期状態が正しい', () {
        final state = container.read(editorViewModelProvider());
        expect(state.isLoading, false);
        expect(state.icon, '📝');
        expect(state.name, '');
        expect(state.type, TaskType.period);
        expect(state.color, TaskColor.none);
        expect(state.isSaved, false);
        expect(state.errorMessage, isNull);
      });

      test('name が空のとき canSave は false', () {
        expect(container.read(editorViewModelProvider()).canSave, false);
      });

      test('updateName で name が更新され canSave が true になる', () {
        viewModel.updateName('散髪');
        final state = container.read(editorViewModelProvider());
        expect(state.name, '散髪');
        expect(state.canSave, true);
      });

      test('updateIcon で icon が更新される', () {
        viewModel.updateIcon('✂️');
        expect(container.read(editorViewModelProvider()).icon, '✂️');
      });

      test('updateType で type が更新される', () {
        viewModel.updateType(TaskType.scheduled);
        expect(
          container.read(editorViewModelProvider()).type,
          TaskType.scheduled,
        );
      });

      test('updateColor で color が更新される', () {
        viewModel.updateColor(TaskColor.blue);
        expect(container.read(editorViewModelProvider()).color, TaskColor.blue);
      });

      test('updateScheduleValue で scheduleValue が更新される', () {
        viewModel.updateScheduleValue(3);
        expect(container.read(editorViewModelProvider()).scheduleValue, 3);
      });

      test('updateScheduleUnit で scheduleUnit が更新される', () {
        viewModel.updateScheduleUnit(ScheduleUnit.week);
        expect(
          container.read(editorViewModelProvider()).scheduleUnit,
          ScheduleUnit.week,
        );
      });

      test('name が空のとき save() は何もしない', () async {
        await viewModel.save();
        final state = container.read(editorViewModelProvider());
        expect(state.isSaved, false);
        expect(state.isLoading, false);
      });

      test('period タスクを save() すると isSaved: true になる', () async {
        viewModel.updateName('散髪');
        await viewModel.save();
        expect(container.read(editorViewModelProvider()).isSaved, true);
      });

      test('scheduled タスクを save() すると isSaved: true になる', () async {
        viewModel
          ..updateName('虫避け交換')
          ..updateType(TaskType.scheduled);
        await viewModel.save();
        expect(container.read(editorViewModelProvider()).isSaved, true);
      });

      test(
        'save() 成功後に snackBarMessage が TaskCreateSuccessSnackMessage になる',
        () async {
          viewModel.updateName('散髪');
          await viewModel.save();
          final state = container.read(editorViewModelProvider());
          expect(state.snackBarMessage, isA<TaskCreateSuccessSnackMessage>());
          expect(
            (state.snackBarMessage as TaskCreateSuccessSnackMessage).taskName,
            '散髪',
          );
          expect(state.snackBarMessage!.handler, isNotNull);
        },
      );

      test('create の undo ハンドラを実行するとタスクがリポジトリから削除される', () async {
        viewModel.updateName('散髪');
        await viewModel.save();
        final snackMsg = container
            .read(editorViewModelProvider())
            .snackBarMessage;
        expect(snackMsg, isA<TaskCreateSuccessSnackMessage>());

        // undo 前はタスクが存在する
        expect(fakeRepository.containsTask(100), true);

        await snackMsg!.handler!();

        expect(fakeRepository.containsTask(100), false);
      });

      test('save() でリポジトリがエラーを返すと errorMessage が設定される', () async {
        final throwingRepo = FakeTaskRepository(shouldThrow: true);
        final c = ProviderContainer(
          overrides: [taskRepositoryProvider.overrideWith((_) => throwingRepo)],
        );
        final s = c.listen(editorViewModelProvider().notifier, (_, _) {});
        addTearDown(() {
          s.close();
          c.dispose();
          throwingRepo.dispose();
        });
        final n = c.read(editorViewModelProvider().notifier);
        n.updateName('散髪');
        await n.save();
        final state = c.read(editorViewModelProvider());
        expect(state.isSaved, false);
        expect(state.isSaving, false);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('編集モード', () {
      setUp(() {
        fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
        container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => fakeRepository),
          ],
        );
      });

      group('初期状態', () {
        test('データ取得中である', () {
          final state = container.read(editorViewModelProvider(taskId: 1));
          expect(state.isLoading, true);
        });
      });

      group('ロード後', () {
        test('period タスクの内容が反映される', () async {
          await _waitUntilLoaded(container, taskId: 1);
          final state = container.read(editorViewModelProvider(taskId: 1));
          expect(state.isLoading, false);
          expect(state.name, '歯ブラシ交換');
          expect(state.icon, '🪥');
          expect(state.type, TaskType.period);
          expect(state.color, TaskColor.blue);
          expect(state.taskHistory, hasLength(1));
        });

        test('scheduled タスクのスケジュール設定が反映される', () async {
          await _waitUntilLoaded(container, taskId: 2);
          final state = container.read(editorViewModelProvider(taskId: 2));
          expect(state.isLoading, false);
          expect(state.type, TaskType.scheduled);
          expect(state.scheduleValue, 2);
          expect(state.scheduleUnit, ScheduleUnit.week);
        });

        test('存在しないタスクのとき errorMessage が設定される', () async {
          await _waitUntilLoaded(container, taskId: 999);
          final state = container.read(editorViewModelProvider(taskId: 999));
          expect(state.isLoading, false);
          expect(state.errorMessage, isNotNull);
        });

        group('save', () {
          group('正常系', () {
            test('編集内容を保存できる', () async {
              await _waitUntilLoaded(container, taskId: 1);
              final notifier = container.read(
                editorViewModelProvider(taskId: 1).notifier,
              );
              notifier.updateColor(TaskColor.green);
              await notifier.save();
              expect(
                container.read(editorViewModelProvider(taskId: 1)).isSaved,
                true,
              );
            });

            test('保存成功後に更新完了の通知がセットされる', () async {
              await _waitUntilLoaded(container, taskId: 1);
              final notifier = container.read(
                editorViewModelProvider(taskId: 1).notifier,
              );
              notifier.updateName('新しい名前');
              await notifier.save();
              final state = container.read(editorViewModelProvider(taskId: 1));
              expect(
                state.snackBarMessage,
                isA<TaskUpdateSuccessSnackMessage>(),
              );
              expect(
                (state.snackBarMessage as TaskUpdateSuccessSnackMessage)
                    .taskName,
                '新しい名前',
              );
              expect(state.snackBarMessage!.handler, isNotNull);
            });

            test('undo ハンドラを実行すると元のタスクの状態に戻る', () async {
              await _waitUntilLoaded(container, taskId: 1);
              final notifier = container.read(
                editorViewModelProvider(taskId: 1).notifier,
              );

              notifier.updateName('新しい名前');
              notifier.updateColor(TaskColor.green);
              await notifier.save();

              final snackMsg = container
                  .read(editorViewModelProvider(taskId: 1))
                  .snackBarMessage;
              expect(snackMsg, isA<TaskUpdateSuccessSnackMessage>());

              // undo 前は更新後の値
              expect(fakeRepository.taskById(1)?.name, '新しい名前');
              expect(fakeRepository.taskById(1)?.color, TaskColor.green);

              await snackMsg!.handler!();

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

Future<void> _waitUntilLoaded(
  ProviderContainer container, {
  required int taskId,
}) async {
  final completer = Completer<void>();
  final sub = container.listen(editorViewModelProvider(taskId: taskId), (
    _,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future;
  sub.close();
}
