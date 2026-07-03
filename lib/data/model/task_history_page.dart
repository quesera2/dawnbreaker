import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_history_page.freezed.dart';

@freezed
abstract class TaskHistoryPage with _$TaskHistoryPage {
  const factory TaskHistoryPage({
    required List<TaskHistory> items,
    required bool hasMore,
  }) = _TaskHistoryPage;
}
