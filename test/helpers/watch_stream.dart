import 'dart:async';

/// 現在値を流してから、以降の変化を流すストリームを作る。
///
/// `async*` で現在値を `yield` してから broadcast を `yield*` すると、`yield` で
/// 止まっている間に流れた変化が落ちる。本物（Firestore / SharedPreferences）は
/// 取りこぼさないため、購読はこの関数を呼んだ時点で張り、テストの都合で消えないようにする
Stream<T> watchWithCurrent<T>(T current, Stream<T> changes) {
  final controller = StreamController<T>();
  controller.add(current);
  final subscription = changes.listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  controller.onCancel = subscription.cancel;
  return controller.stream;
}
