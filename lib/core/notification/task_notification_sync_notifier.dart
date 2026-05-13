import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'task_notification_sync.dart';

part 'task_notification_sync_notifier.g.dart';

/// すべてのタスクを監視して変化があったときに通知を登録する
///
/// 通知の有効・無効を切り替えると[build]が再実行され、すべての通知を再登録する。
@Riverpod(keepAlive: true)
class TaskNotificationSyncNotifier extends _$TaskNotificationSyncNotifier {
  @override
  Future<void> build() async {
    final enabled = await ref.watch(notificationEnabledProvider.future);
    final service = await ref.read(notificationServiceProvider.future);
    final syncLogic = TaskNotificationSync(service);
    final repository = ref.read(taskRepositoryProvider);

    final sub = repository
        .allTaskItems()
        .distinct(
          (prev, curr) => const IterableEquality<TaskItem>().equals(prev, curr),
        )
        .pairwise(initialValue: [])
        .listen((pair) {
          syncLogic.updateNotifications(
            enabled: enabled,
            previous: pair.$1,
            current: pair.$2,
          );
        });

    ref.onDispose(sub.cancel);
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
