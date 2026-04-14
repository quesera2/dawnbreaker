import 'package:dawnbreaker/data/database/tables/task_definitions_table.dart';
import 'package:drift/drift.dart';

class TaskExecutions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskDefinitionId =>
      integer().references(TaskDefinitions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get executedAt => dateTime()();
}
