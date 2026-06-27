// ignore_for_file: prefer_const_constructors

import 'package:dawnbreaker/data/database/tables/task_definitions_table.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:drift/drift.dart';

class TaskScheduledConfigs extends Table {
  TextColumn get taskDefinitionId =>
      text().references(TaskDefinitions, #id, onDelete: KeyAction.cascade)();

  IntColumn get scheduleValue => integer()();

  TextColumn get scheduleUnit =>
      text().map(EnumNameConverter(ScheduleUnit.values))();

  @override
  Set<Column> get primaryKey => {taskDefinitionId};
}
