import 'dart:async';

import 'package:dawnbreaker/core/util/stream_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('combineLatest', () {
    late List<StreamController<int>> controllers;
    late List<List<int>> emitted;
    late List<Object> errors;

    setUp(() {
      controllers = List.generate(4, (_) => StreamController<int>());
      emitted = [];
      errors = [];
    });

    // 購読されないものは close の完了を待つと終わらないため待たない
    tearDown(() {
      for (final controller in controllers) {
        unawaited(controller.close());
      }
    });

    void onError(Object error, StackTrace _) => errors.add(error);

    for (final (arity, combine) in <(int, CancelCallback Function())>[
      (
        2,
        () => combineLatest2(
          controllers[0].stream,
          controllers[1].stream,
          (int a, int b) => emitted.add([a, b]),
          onError: onError,
        ),
      ),
      (
        3,
        () => combineLatest3(
          controllers[0].stream,
          controllers[1].stream,
          controllers[2].stream,
          (int a, int b, int c) => emitted.add([a, b, c]),
          onError: onError,
        ),
      ),
      (
        4,
        () => combineLatest4(
          controllers[0].stream,
          controllers[1].stream,
          controllers[2].stream,
          controllers[3].stream,
          (int a, int b, int c, int d) => emitted.add([a, b, c, d]),
          onError: onError,
        ),
      ),
    ]) {
      group('$arity 本の場合', () {
        late CancelCallback cancel;

        setUp(() async {
          cancel = combine();
          for (var i = 0; i < arity; i++) {
            controllers[i].add(i);
          }
          await Future<void>.delayed(Duration.zero);
        });

        tearDown(() => cancel());

        test('すべてが揃うと値を組み合わせて流す', () {
          expect(emitted, [List.generate(arity, (i) => i)]);
        });

        test('どのストリームの失敗も onError に届く', () async {
          for (var i = 0; i < arity; i++) {
            controllers[i].addError('error-$i');
          }
          await Future<void>.delayed(Duration.zero);
          expect(errors, List.generate(arity, (i) => 'error-$i'));
        });

        test('失敗のあとも他の値の組み合わせを続ける', () async {
          controllers[0].addError('error');
          controllers[0].add(10);
          await Future<void>.delayed(Duration.zero);
          expect(emitted.last.first, 10);
        });
      });
    }
  });
}
