import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_history.freezed.dart';

@freezed
abstract class TaskHistory with _$TaskHistory {
  const factory TaskHistory({required int id, required DateTime executedAt}) =
      _TaskHistory;
}
