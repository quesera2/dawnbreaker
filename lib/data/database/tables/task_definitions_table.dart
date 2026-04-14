import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:drift/drift.dart';

class TaskDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get taskType =>
      text().map(EnumNameConverter(TaskType.values))();

  TextColumn get name => text()();

  TextColumn get furigana => text()();

  TextColumn get color =>
      text().map(EnumNameConverter(TaskColor.values))();
}
