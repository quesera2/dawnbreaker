import 'package:dawnbreaker/data/database/app_database.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_furigana_translate.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(
      db: db,
      furiganaTranslate: const FakeFuriganaTranslate({
        '散髪': 'さんぱつ',
        '歯ブラシ交換': 'はぶらしこうかん',
        '虫避け交換': 'むしよけこうかん',
      }),
    );
  });

  tearDown(() => db.close());

  group('addPeriodTask', () {
    test('タスクが追加され PeriodTaskItem として取得できる', () async {
      await repository.addPeriodTask(name: '散髪', color: TaskColor.none);
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<PeriodTaskItem>());
      expect(task.name, '散髪');
      expect(task.furigana, 'さんぱつ');
      expect(task.color, TaskColor.none);
      expect(task.taskHistory, hasLength(1)); // 登録時の初回実行
    });
  });

  group('addScheduledTask', () {
    test('タスクが追加され ScheduledTaskItem として取得できる', () async {
      await repository.addScheduledTask(
        name: '虫避け交換',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first as ScheduledTaskItem;
      expect(task.name, '虫避け交換');
      expect(task.furigana, 'むしよけこうかん');
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
      expect(task.taskHistory, hasLength(1));
    });
  });

  group('recordExecution', () {
    test('実行履歴が追加される', () async {
      final id = await repository.addPeriodTask(
        name: '散髪',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 6, 1));

      final tasks = await repository.allTaskItems().first;
      expect(tasks.first.taskHistory, hasLength(2)); // 初回 + 追加分
    });

    test('履歴が2件以上になると scheduledAt が算出される', () async {
      final id = await repository.addPeriodTask(
        name: '散髪',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 2, 1));

      final tasks = await repository.allTaskItems().first;
      expect(tasks.first.scheduledAt, isNotNull);
    });
  });

  group('deleteTask', () {
    test('指定したタスクが削除される', () async {
      final id = await repository.addPeriodTask(
        name: '散髪',
        color: TaskColor.none,
      );
      await repository.deleteTask(id);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, isEmpty);
    });

    test('複数タスクのうち指定したものだけ削除される', () async {
      final id1 = await repository.addPeriodTask(
        name: '散髪',
        color: TaskColor.none,
      );
      await repository.addPeriodTask(
        name: '歯ブラシ交換',
        color: TaskColor.blue,
      );
      await repository.deleteTask(id1);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, '歯ブラシ交換');
    });
  });
}