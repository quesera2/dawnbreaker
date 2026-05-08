import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<void> waitUntil<T>(
  ProviderContainer container,
  ProviderListenable<T> provider,
  bool Function(T) condition,
) async {
  final completer = Completer<void>();
  final sub = container.listen(provider, (_, next) {
    if (condition(next) && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future;
  sub.close();
}
