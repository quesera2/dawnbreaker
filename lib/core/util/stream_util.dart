typedef CancelCallback = void Function();

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

  return () {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
    sub4.cancel();
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

  return () {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
  };
}
