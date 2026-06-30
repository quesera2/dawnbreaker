import 'package:dawnbreaker/core/notification/task_notification_sync.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  late FakeNotificationService service;
  late TaskNotificationSync sync;

  const enabledSetting = NotificationSetting(enabled: true);
  const disabledSetting = NotificationSetting(enabled: false);

  setUp(() {
    service = FakeNotificationService();
    sync = TaskNotificationSync(service);
  });

  group('updateNotifications', () {
    group('通知が有効な場合', () {
      group('タスク追加', () {
        test('scheduledAt があるタスクは通知が登録される', () async {
          final task = _makeScheduled(id: '1');
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [],
            current: [task],
          );

          expect(service.registered, [task]);
          expect(service.removed, isEmpty);
        });

        test('scheduledAt がないタスクは通知が削除される', () async {
          final task = _makeIrregular(id: '1');
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [],
            current: [task],
          );

          expect(service.registered, isEmpty);
          expect(service.removed, [task]);
        });

        test('scheduledAt ありとなしが混在する場合に正しく分類される', () async {
          final s1 = _makeScheduled(id: '1');
          final s2 = _makeScheduled(id: '2');
          final i1 = _makeIrregular(id: '3');
          final i2 = _makeIrregular(id: '4');
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [],
            current: [s1, s2, i1, i2],
          );

          expect(service.registered, containsAll([s1, s2]));
          expect(service.removed, containsAll([i1, i2]));
        });
      });

      group('タスク削除', () {
        test('削除されたタスクの通知が削除される', () async {
          final task = _makeScheduled(id: '1');
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [task],
            current: [],
          );

          expect(service.removed, [task]);
          expect(service.registered, isEmpty);
        });

        test('複数タスクのうち一部だけ削除された場合、削除分のみ解除される', () async {
          final keep = _makeScheduled(id: '1');
          final remove = _makeScheduled(id: '2');
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [keep, remove],
            current: [keep],
          );

          expect(service.removed, [remove]);
          expect(service.registered, isEmpty);
        });
      });

      group('タスク更新', () {
        test('スケジュールが変わったタスクは旧通知が削除されて新通知が登録される', () async {
          final old = _makeScheduled(id: '1', scheduleValue: 7);
          final updated = _makeScheduled(id: '1', scheduleValue: 14);
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [old],
            current: [updated],
          );

          expect(service.removed, [old]);
          expect(service.registered, [updated]);
        });

        test('変更されたタスクと変更されていないタスクが混在する場合、変更分のみ処理される', () async {
          final unchanged = _makeScheduled(id: '1');
          final old = _makeScheduled(id: '2', scheduleValue: 7);
          final updated = _makeScheduled(id: '2', scheduleValue: 14);
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: [unchanged, old],
            current: [unchanged, updated],
          );

          expect(service.removed, [old]);
          expect(service.registered, [updated]);
        });
      });

      group('変化なし', () {
        test('同じリストを渡した場合、通知メソッドは呼ばれない', () async {
          final tasks = [_makeScheduled(id: '1'), _makeScheduled(id: '2')];
          await sync.updateNotifications(
            setting: enabledSetting,
            previous: tasks,
            current: tasks,
          );

          expect(service.registered, isEmpty);
          expect(service.removed, isEmpty);
        });
      });
    });

    group('通知が無効な場合', () {
      test('すべての通知が削除される', () async {
        await sync.updateNotifications(
          setting: disabledSetting,
          previous: [
            _makeScheduled(id: '1'),
            _makeIrregular(id: '2'),
          ],
          current: [
            _makeScheduled(id: '3'),
            _makeIrregular(id: '4'),
          ],
        );

        expect(service.callRemovedAll, isTrue);
        expect(service.registered, isEmpty);
      });
    });
  });
}

TaskItem _makeScheduled({
  required String id,
  int scheduleValue = 7,
  int daysAgo = 7,
}) => TaskItem.scheduled(
  id: id,
  name: 'タスク$id',
  furigana: '',
  icon: '📝',
  color: TaskColor.none,
  scheduleValue: scheduleValue,
  scheduleUnit: ScheduleUnit.day,
  taskHistory: [
    TaskHistory(
      taskId: 'task-1',
      id: id * 10,
      executedAt: DateTime.now().truncateTime.subtract(Duration(days: daysAgo)),
      comment: null,
    ),
  ],
);

TaskItem _makeIrregular({required String id}) => TaskItem.irregular(
  id: id,
  name: 'タスク$id',
  furigana: '',
  icon: '📝',
  color: TaskColor.none,
  taskHistory: [],
);
