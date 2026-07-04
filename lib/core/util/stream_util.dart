import 'dart:async';

typedef CancelCallback = Future<void> Function();

// combineLatest3/4 と同様、値そのもの（null かどうか）で「まだ来ていない」を
// 判定する。ストリームが null を正当な値として流す場合は、呼び出し側で
// 事前にフィルタしてから渡すこと（null 値も扱いたい場合はこの関数を使わない）
CancelCallback combineLatest2<T, S>(
  Stream<T> stream1,
  Stream<S> stream2,
  void Function(T, S) combiner, {
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  T? v1;
  S? v2;

  void tryEmit() {
    final a = v1;
    final b = v2;
    if (a == null || b == null) return;
    combiner(a, b);
  }

  final sub1 = stream1.listen(
    (v) {
      v1 = v;
      tryEmit();
    },
    onError: onError,
  );
  final sub2 = stream2.listen(
    (v) {
      v2 = v;
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
