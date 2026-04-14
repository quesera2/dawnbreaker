import 'package:dawnbreaker/data/database/converters.dart';
import 'package:drift/drift.dart';

class TaskDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get taskType => text().map(const TaskTypeConverter())();

  TextColumn get name => text()();

  TextColumn get furigana => text()();

  TextColumn get color => text().map(const TaskColorConverter())();
}
