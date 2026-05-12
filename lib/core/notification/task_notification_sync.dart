import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_notification_sync.g.dart';

/// すべてのタスクを監視して変化があったときに通知を登録する
@Riverpod(keepAlive: true)
class TaskNotificationSync extends _$TaskNotificationSync {
  @override
  Future<void> build() async {
    final repository = ref.read(taskRepositoryProvider);
    final service = await ref.read(notificationServiceProvider.future);

    final sub = repository
        .allTaskItems()
        .distinct(
          (prev, curr) => const IterableEquality<TaskItem>().equals(prev, curr),
        )
        .pairwise(initialValue: [])
        .listen((pair) {
          updateNotifications(service, previous: pair.$1, current: pair.$2);
        });

    ref.onDispose(sub.cancel);
  }
}

@visibleForTesting
void updateNotifications(
  NotificationService service, {
  required List<TaskItem> previous,
  required List<TaskItem> current,
}) {
  final previousSet = previous.toSet();
  final currentSet = current.toSet();

  for (final task in previousSet.difference(currentSet)) {
    service.removeNotification(task);
  }

  for (final task in currentSet.difference(previousSet)) {
    if (task.scheduledAt != null) {
      service.registerNotification(task);
    } else {
      service.removeNotification(task);
    }
  }
}

extension _PairwiseExtension<T> on Stream<T> {
  Stream<(T, T)> pairwise({required T initialValue}) async* {
    var prev = initialValue;
    await for (final element in this) {
      yield (prev, element);
      prev = element;
    }
  }
}
