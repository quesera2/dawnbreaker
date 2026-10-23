import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionExpiry', () {
    late ProviderContainer container;
    late SessionExpiry sessionExpiry;
    late List<SessionExpiredEvent?> notified;

    setUp(() {
      container = ProviderContainer();
      sessionExpiry = container.read(sessionExpiryProvider.notifier);
      notified = [];
      container.listen(sessionExpiryProvider, (_, next) => notified.add(next));
    });

    tearDown(() => container.dispose());

    test('はじめは何も知らせていない', () {
      expect(container.read(sessionExpiryProvider), isNull);
    });

    test('セッション切れを知らせられる', () {
      sessionExpiry.notifyExpired();

      expect(notified, [isA<SessionExpiredEvent>()]);
    });

    test('サインインし直すまでは重ねて知らせない', () {
      sessionExpiry
        ..notifyExpired()
        ..notifyExpired();

      expect(notified, hasLength(1));
    });

    test('サインインし直したあとは、次のセッション切れを知らせられる', () {
      sessionExpiry
        ..notifyExpired()
        ..reset()
        ..notifyExpired();

      final events = notified.whereType<SessionExpiredEvent>().toList();
      expect(events, hasLength(2));
      expect(events.first.id, isNot(events.last.id));
    });
  });
}
