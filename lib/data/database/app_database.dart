import 'package:dawnbreaker/data/database/tables/task_definitions_table.dart';
import 'package:dawnbreaker/data/database/tables/task_executions_table.dart';
import 'package:dawnbreaker/data/database/tables/task_scheduled_configs_table.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TaskDefinitions,
    TaskScheduledConfigs,
    TaskExecutions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'app_database');
  }
}
