// coverage:ignore-file
import 'dart:math';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_schedule.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

List<(TaskItem, List<TaskHistory>)> buildDummyTasks({
  required DateTime now,
  required Random random,
}) {
  final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
  final items = <(TaskItem, List<TaskHistory>)>[];
  var taskId = 1;

  for (final def in _dummyTaskDefinition) {
    final dates = _generateDates(
      start: oneYearAgo,
      baseIntervalDays: def.baseIntervalDays,
      varianceDays: def.varianceDays,
      until: now,
      random: random,
    );
    if (dates.isEmpty) continue;

    final taskIdStr = taskId.toString();
    final history = [
      for (final (index, date) in dates.indexed)
        TaskHistory(
          id: '$taskIdStr-${index + 1}',
          executedAt: date,
          comment: null,
        ),
    ];
    final lastExecutedAt = computeLastExecutedAt(history);

    final item = switch (def.taskType) {
      TaskType.irregular => TaskItem.irregular(
        id: taskIdStr,
        name: def.name,
        furigana: def.furigana,
        icon: def.icon,
        color: def.color,
        lastExecutedAt: lastExecutedAt,
      ),
      TaskType.period => TaskItem.period(
        id: taskIdStr,
        name: def.name,
        furigana: def.furigana,
        icon: def.icon,
        color: def.color,
        lastExecutedAt: lastExecutedAt,
        cachedScheduledAt: computeScheduledAt(
          taskType: TaskType.period,
          ascendingHistory: history,
        ),
      ),
      TaskType.scheduled => TaskItem.scheduled(
        id: taskIdStr,
        name: def.name,
        furigana: def.furigana,
        icon: def.icon,
        color: def.color,
        scheduleValue: def.scheduleValue!,
        scheduleUnit: def.scheduleUnit!,
        lastExecutedAt: lastExecutedAt,
      ),
    };

    items.add((item, history));
    taskId++;
  }

  return items;
}

List<DateTime> _generateDates({
  required DateTime start,
  required int baseIntervalDays,
  required int varianceDays,
  required DateTime until,
  required Random random,
}) {
  final dates = <DateTime>[];
  var current = start;
  while (!current.isAfter(until)) {
    dates.add(current);
    final variance = varianceDays > 0
        ? random.nextInt(varianceDays * 2 + 1) - varianceDays
        : 0;
    current = current.add(Duration(days: baseIntervalDays + variance));
  }
  return dates;
}

const _dummyTaskDefinition = [
  (
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    icon: '🪥',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 30,
    varianceDays: 3,
  ),
  (
    name: 'エアコンフィルター清掃',
    furigana: 'えあこんふぃるたーせいそう',
    icon: '🌬️',
    color: TaskColor.blue,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 60,
    varianceDays: 5,
  ),
  (
    name: 'エアコン本体クリーニング',
    furigana: 'えあこんほんたいくりーにんぐ',
    icon: '❄️',
    color: TaskColor.blue,
    taskType: TaskType.scheduled,
    scheduleValue: 6,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 180,
    varianceDays: 7,
  ),
  (
    name: 'オイル交換',
    furigana: 'おいるこうかん',
    icon: '🔧',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 3,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 90,
    varianceDays: 7,
  ),
  (
    name: '洗車',
    furigana: 'せんしゃ',
    icon: '🚗',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.week,
    baseIntervalDays: 14,
    varianceDays: 2,
  ),
  (
    name: 'タイヤローテーション',
    furigana: 'たいやろーてーしょん',
    icon: '🔩',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 6,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 180,
    varianceDays: 14,
  ),
  (
    name: 'スニーカー洗濯',
    furigana: 'すにーかーせんたく',
    icon: '👟',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.week,
    baseIntervalDays: 14,
    varianceDays: 3,
  ),
  (
    name: 'ベランダ掃除',
    furigana: 'べらんだそうじ',
    icon: '🧹',
    color: TaskColor.orange,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 30,
    varianceDays: 4,
  ),
  (
    name: 'お風呂の防カビ剤交換',
    furigana: 'おふろのぼうかびざいこうかん',
    icon: '🛁',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 60,
    varianceDays: 5,
  ),
  (
    name: '植物への施肥',
    furigana: 'しょくぶつへのせひ',
    icon: '🌱',
    color: TaskColor.green,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.week,
    baseIntervalDays: 14,
    varianceDays: 2,
  ),
  (
    name: '冷蔵庫の霜取り',
    furigana: 'れいぞうこのしもとり',
    icon: '🧊',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 30,
    varianceDays: 5,
  ),
  (
    name: '排水口パイプ掃除',
    furigana: 'はいすいこうぱいぷそうじ',
    icon: '💧',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.week,
    baseIntervalDays: 7,
    varianceDays: 1,
  ),
  (
    name: '美容院',
    furigana: 'びよういん',
    icon: '✂️',
    color: TaskColor.none,
    taskType: TaskType.period,
    scheduleValue: null,
    scheduleUnit: null,
    baseIntervalDays: 40,
    varianceDays: 5,
  ),
  (
    name: '窓ガラスの拭き掃除',
    furigana: 'まどがらすのふきそうじ',
    icon: '🪟',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 30,
    varianceDays: 5,
  ),
  (
    name: '健康診断',
    furigana: 'けんこうしんだん',
    icon: '🏥',
    color: TaskColor.red,
    taskType: TaskType.scheduled,
    scheduleValue: 6,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 180,
    varianceDays: 14,
  ),
  (
    name: '虫除けスプレー交換',
    furigana: 'むしよけすぷれーこうかん',
    icon: '🦟',
    color: TaskColor.orange,
    taskType: TaskType.scheduled,
    scheduleValue: 2,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 60,
    varianceDays: 5,
  ),
  (
    name: '猫の健康診断',
    furigana: 'ねこのけんこうしんだん',
    icon: '🐱',
    color: TaskColor.none,
    taskType: TaskType.scheduled,
    scheduleValue: 1,
    scheduleUnit: ScheduleUnit.month,
    baseIntervalDays: 30,
    varianceDays: 4,
  ),
  (
    name: '布団干し',
    furigana: 'ふとんほし',
    icon: '☀️',
    color: TaskColor.yellow,
    taskType: TaskType.period,
    scheduleValue: null,
    scheduleUnit: null,
    baseIntervalDays: 14,
    varianceDays: 5,
  ),
  (
    name: '冬服クリーニング',
    furigana: 'ふゆふくくりーにんぐ',
    icon: '🧥',
    color: TaskColor.blue,
    taskType: TaskType.irregular,
    scheduleValue: null,
    scheduleUnit: null,
    baseIntervalDays: 180,
    varianceDays: 20,
  ),
  (
    name: '財布の残高チェック',
    furigana: 'さいふのざんだかちぇっく',
    icon: '👛',
    color: TaskColor.none,
    taskType: TaskType.irregular,
    scheduleValue: null,
    scheduleUnit: null,
    baseIntervalDays: 90,
    varianceDays: 14,
  ),
];
