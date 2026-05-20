typedef CancelCallback = void Function();

CancelCallback combineLatest<T, S>(
  Stream<T> stream1,
  Stream<S> stream2,
  void Function(T, S) combiner,
) {
  T? v1;
  S? v2;

  void tryEmit() {
    final a = v1;
    final b = v2;
    if (a == null || b == null) return;
    combiner(a, b);
  }

  final sub1 = stream1.listen((v) {
    v1 = v;
    tryEmit();
  });
  final sub2 = stream2.listen((v) {
    v2 = v;
    tryEmit();
  });

  return () {
    sub1.cancel();
    sub2.cancel();
  };
}
