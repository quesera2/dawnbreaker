import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

@riverpod
class CurrentUser extends _$CurrentUser {
  /// 初期値は `getUser()` が同期で供給するため `AsyncNotifier` にする理由がない。
  /// `listen()` のコールバックは Stream の配送がマイクロタスク以降になるため、
  /// `build()` の実行中に `state` へ代入されることはない
  @override
  AppUser build() {
    final repository = ref.watch(userRepositoryProvider);
    final subscription = repository.watchUser().listen((user) => state = user);
    ref.onDispose(subscription.cancel);
    return repository.getUser();
  }
}
