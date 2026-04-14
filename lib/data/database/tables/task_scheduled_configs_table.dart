import 'package:dawnbreaker/data/database/converters.dart';
import 'package:dawnbreaker/data/database/tables/task_definitions_table.dart';
import 'package:drift/drift.dart';

class TaskScheduledConfigs extends Table {
  IntColumn get taskDefinitionId =>
      integer().references(TaskDefinitions, #id, onDelete: KeyAction.cascade)();

  IntColumn get scheduleValue => integer()();

  TextColumn get scheduleUnit => text().map(const ScheduleUnitConverter())();

  @override
  Set<Column> get primaryKey => {taskDefinitionId};
}
