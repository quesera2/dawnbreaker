import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:drift/drift.dart';

class TaskTypeConverter extends TypeConverter<TaskType, String> {
  const TaskTypeConverter();

  @override
  TaskType fromSql(String fromDb) => TaskType.values.byName(fromDb);

  @override
  String toSql(TaskType value) => value.name;
}

class ScheduleUnitConverter extends TypeConverter<ScheduleUnit, String> {
  const ScheduleUnitConverter();

  @override
  ScheduleUnit fromSql(String fromDb) => ScheduleUnit.values.byName(fromDb);

  @override
  String toSql(ScheduleUnit value) => value.name;
}

class TaskColorConverter extends TypeConverter<TaskColor, String> {
  const TaskColorConverter();

  @override
  TaskColor fromSql(String fromDb) => TaskColor.values.byName(fromDb);

  @override
  String toSql(TaskColor value) => value.name;
}
