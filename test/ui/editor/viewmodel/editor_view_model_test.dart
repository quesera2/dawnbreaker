import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
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

    group('新規作成モード (taskId: null)', () {
      setUp(() {
        fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
        container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => fakeRepository),
          ],
        );
      });

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
        container.read(editorViewModelProvider().notifier).updateName('散髪');
        final state = container.read(editorViewModelProvider());
        expect(state.name, '散髪');
        expect(state.canSave, true);
      });

      test('updateIcon で icon が更新される', () {
        container.read(editorViewModelProvider().notifier).updateIcon('✂️');
        expect(container.read(editorViewModelProvider()).icon, '✂️');
      });

      test('updateType で type が更新される', () {
        container
            .read(editorViewModelProvider().notifier)
            .updateType(TaskType.scheduled);
        expect(
          container.read(editorViewModelProvider()).type,
          TaskType.scheduled,
        );
      });

      test('updateColor で color が更新される', () {
        container
            .read(editorViewModelProvider().notifier)
            .updateColor(TaskColor.blue);
        expect(
          container.read(editorViewModelProvider()).color,
          TaskColor.blue,
        );
      });

      test('updateScheduleValue で scheduleValue が更新される', () {
        container
            .read(editorViewModelProvider().notifier)
            .updateScheduleValue(3);
        expect(container.read(editorViewModelProvider()).scheduleValue, 3);
      });

      test('updateScheduleUnit で scheduleUnit が更新される', () {
        container
            .read(editorViewModelProvider().notifier)
            .updateScheduleUnit(ScheduleUnit.week);
        expect(
          container.read(editorViewModelProvider()).scheduleUnit,
          ScheduleUnit.week,
        );
      });

      test('name が空のとき save() は何もしない', () async {
        await container.read(editorViewModelProvider().notifier).save();
        final state = container.read(editorViewModelProvider());
        expect(state.isSaved, false);
        expect(state.isLoading, false);
      });

      test('period タスクを save() すると isSaved: true になる', () async {
        final notifier = container.read(editorViewModelProvider().notifier);
        notifier.updateName('散髪');
        await notifier.save();
        expect(container.read(editorViewModelProvider()).isSaved, true);
      });

      test('scheduled タスクを save() すると isSaved: true になる', () async {
        final notifier = container.read(editorViewModelProvider().notifier);
        notifier.updateName('虫避け交換');
        notifier.updateType(TaskType.scheduled);
        await notifier.save();
        expect(container.read(editorViewModelProvider()).isSaved, true);
      });

      test('save() でリポジトリがエラーを返すと errorMessage が設定される', () async {
        fakeRepository = _ThrowingFakeTaskRepository();
        container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => fakeRepository),
          ],
        );
        final notifier = container.read(editorViewModelProvider().notifier);
        notifier.updateName('散髪');
        await notifier.save();
        final state = container.read(editorViewModelProvider());
        expect(state.isSaved, false);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('編集モード (taskId: non-null)', () {
      setUp(() {
        fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
        container = ProviderContainer(
          overrides: [
            taskRepositoryProvider.overrideWith((_) => fakeRepository),
          ],
        );
      });

      test('初期状態は isLoading: true', () {
        final state = container.read(editorViewModelProvider(taskId: 1));
        expect(state.isLoading, true);
      });

      test('period タスクのロード後: 各フィールドが反映される', () async {
        await _waitUntilLoaded(container, taskId: 1);
        final state = container.read(editorViewModelProvider(taskId: 1));
        expect(state.isLoading, false);
        expect(state.name, '歯ブラシ交換');
        expect(state.icon, '🪥');
        expect(state.type, TaskType.period);
        expect(state.color, TaskColor.blue);
        expect(state.taskHistory, hasLength(1));
      });

      test('scheduled タスクのロード後: scheduleValue/scheduleUnit が反映される',
          () async {
        await _waitUntilLoaded(container, taskId: 2);
        final state = container.read(editorViewModelProvider(taskId: 2));
        expect(state.isLoading, false);
        expect(state.type, TaskType.scheduled);
        expect(state.scheduleValue, 2);
        expect(state.scheduleUnit, ScheduleUnit.week);
      });

      test('存在しない taskId のとき errorMessage が設定される', () async {
        await _waitUntilLoaded(container, taskId: 999);
        final state = container.read(editorViewModelProvider(taskId: 999));
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });

      test('編集して save() すると isSaved: true になる', () async {
        await _waitUntilLoaded(container, taskId: 1);
        final notifier =
            container.read(editorViewModelProvider(taskId: 1).notifier);
        notifier.updateColor(TaskColor.green);
        await notifier.save();
        expect(
          container.read(editorViewModelProvider(taskId: 1)).isSaved,
          true,
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
    icon: '🪥',
    color: TaskColor.blue,
    taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1))],
  ),
  TaskItem.scheduled(
    id: 2,
    name: '虫避け交換',
    furigana: 'むしよけこうかん',
    icon: '🐝',
    color: TaskColor.orange,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.week,
    taskHistory: [TaskHistory(id: 2, executedAt: DateTime(2026, 1, 1))],
  ),
];

Future<void> _waitUntilLoaded(
  ProviderContainer container, {
  required int taskId,
}) async {
  final completer = Completer<void>();
  final sub = container.listen(
    editorViewModelProvider(taskId: taskId),
    (_, next) {
      if (!next.isLoading && !completer.isCompleted) completer.complete();
    },
    fireImmediately: true,
  );
  await completer.future;
  sub.close();
}

class _ThrowingFakeTaskRepository extends FakeTaskRepository {
  @override
  Future<int> addPeriodTask({
    required String name,
    required String icon,
    required TaskColor color,
    required DateTime executedAt,
  }) async => throw TaskRepositoryException('テストエラー');

  @override
  Future<int> addScheduledTask({
    required String name,
    required String icon,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required DateTime executedAt,
  }) async => throw TaskRepositoryException('テストエラー');
}
