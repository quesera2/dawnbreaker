import 'package:dawnbreaker/data/database/tables/task_definitions_table.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_task_executions_task_definition_id_executed_at',
  columns: {#taskDefinitionId, #executedAt},
)
class TaskExecutions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskDefinitionId =>
      integer().references(TaskDefinitions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get executedAt => dateTime()();

  TextColumn get comment => text().nullable()();
}
