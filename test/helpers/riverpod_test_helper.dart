import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

/// [condition] を満たす状態が流れてくるまで待つ。
///
/// Provider の build が失敗すると値が一度も流れてこない。待つだけだとテストが
/// 原因不明のままハングするため、タイムアウトを設けて原因の分かる失敗にする
Future<void> waitUntil<T>(
  ProviderContainer container,
  ProviderListenable<T> provider,
  bool Function(T) condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final completer = Completer<void>();
  final sub = container.listen(provider, (_, next) {
    if (condition(next) && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  try {
    await completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'condition was not met, the provider may have failed to build',
        timeout,
      ),
    );
  } finally {
    sub.close();
  }
}
