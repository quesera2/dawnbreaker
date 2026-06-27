import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  AsyncValue<T> update(T Function(T) updater) =>
      AsyncData(updater(requireValue));
}
