import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncateTime', () {
    // 米国東部時間の夏時間切り替え日 (2025-03-09→10) をまたぐと
    // ローカル midnight 間が 23 時間になり inDays が 0 になる
    // TZ=America/New_York で実行することでこのケースを再現できる
    test('夏時間の切り替え日をまたいでも差分が1日になる', () {
      final a = DateTime(2025, 3, 9, 15, 0);
      final b = DateTime(2025, 3, 10, 9, 0);
      expect(b.truncateTime.difference(a.truncateTime).inDays, 1);
    });

    test('同じ日の異なる時刻は差分が0日になる', () {
      final a = DateTime(2025, 6, 1, 8, 0);
      final b = DateTime(2025, 6, 1, 23, 59);
      expect(b.truncateTime.difference(a.truncateTime).inDays, 0);
    });

    test('戻り値は UTC DateTime である', () {
      final dt = DateTime(2025, 6, 1, 15, 30);
      expect(dt.truncateTime.isUtc, isTrue);
    });
  });
}
