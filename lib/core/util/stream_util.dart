import 'dart:async';

typedef CancelCallback = Future<void> Function();

// combineLatest3/4 と異なり、値そのものではなく受信済みフラグで「まだ来ていない」を
// 判定する。ストリームの値が nullable な場合（null を正当な値として流す場合）に
// 誤判定しないようにするため
CancelCallback combineLatest2<T, S>(
  Stream<T> stream1,
  Stream<S> stream2,
  void Function(T, S) combiner, {
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  late T v1;
  late S v2;
  var hasV1 = false;
  var hasV2 = false;

  void tryEmit() {
    if (!hasV1 || !hasV2) return;
    combiner(v1, v2);
  }

  final sub1 = stream1.listen(
    (v) {
      v1 = v;
      hasV1 = true;
      tryEmit();
    },
    onError: onError,
  );
  final sub2 = stream2.listen(
    (v) {
      v2 = v;
      hasV2 = true;
      tryEmit();
    },
    onError: onError,
  );

  return () async {
    await sub1.cancel();
    await sub2.cancel();
  };
}

CancelCallback combineLatest4<T, S, U, V>(
  Stream<T> stream1,
  Stream<S> stream2,
  Stream<U> stream3,
  Stream<V> stream4,
  void Function(T, S, U, V) combiner,
) {
  T? v1;
  S? v2;
  U? v3;
  V? v4;

  void tryEmit() {
    final a = v1;
    final b = v2;
    final c = v3;
    final d = v4;
    if (a == null || b == null || c == null || d == null) return;
    combiner(a, b, c, d);
  }

  final sub1 = stream1.listen((v) {
    v1 = v;
    tryEmit();
  });
  final sub2 = stream2.listen((v) {
    v2 = v;
    tryEmit();
  });
  final sub3 = stream3.listen((v) {
    v3 = v;
    tryEmit();
  });
  final sub4 = stream4.listen((v) {
    v4 = v;
    tryEmit();
  });

  return () async {
    await sub1.cancel();
    await sub2.cancel();
    await sub3.cancel();
    await sub4.cancel();
  };
}

CancelCallback combineLatest3<T, S, U>(
  Stream<T> stream1,
  Stream<S> stream2,
  Stream<U> stream3,
  void Function(T, S, U) combiner,
) {
  T? v1;
  S? v2;
  U? v3;

  void tryEmit() {
    final a = v1;
    final b = v2;
    final c = v3;
    if (a == null || b == null || c == null) return;
    combiner(a, b, c);
  }

  final sub1 = stream1.listen((v) {
    v1 = v;
    tryEmit();
  });
  final sub2 = stream2.listen((v) {
    v2 = v;
    tryEmit();
  });
  final sub3 = stream3.listen((v) {
    v3 = v;
    tryEmit();
  });

  return () async {
    await sub1.cancel();
    await sub2.cancel();
    await sub3.cancel();
  };
}
