import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_history_cursor.freezed.dart';

@freezed
abstract class TaskHistoryCursor with _$TaskHistoryCursor {
  const factory TaskHistoryCursor({
    required DateTime executedAt,
    required String id,
  }) = _TaskHistoryCursor;
}
