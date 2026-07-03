/// 同じ key を持つ要素をまとめ、後に出現した要素で上書きする。
/// 元の並び順は保持されない（呼び出し側でソートすること）。
List<T> distinctBy<T, K>(Iterable<T> items, K Function(T item) key) {
  final byKey = <K, T>{};
  for (final item in items) {
    byKey[key(item)] = item;
  }
  return byKey.values.toList();
}
