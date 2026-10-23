import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:dawnbreaker/core/auth/session_observer.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/session_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeUserRepository fakeUserRepository;

  void setUpContainer({
    AppUser user = const Guest('user-1'),
    SessionStatus serverSessionStatus = SessionStatus.valid,
  }) {
    fakeUserRepository = FakeUserRepository(user)
      ..serverSessionStatus = serverSessionStatus;
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(fakeUserRepository)],
    );
    addTearDown(container.dispose);
  }

  SessionObserver observer() =>
      container.read(sessionObserverProvider.notifier);

  bool isNotifiedExpired() => container.read(sessionExpiryProvider) != null;

  /// セッションを確かめる契機
  final triggers = <(String, void Function())>[
    ('起動したとき', () => observer().verifyOnStartup()),
    (
      '復帰したとき',
      () => observer().didChangeAppLifecycleState(AppLifecycleState.resumed),
    ),
  ];

  group('SessionObserver', () {
    for (final (description, trigger) in triggers) {
      group(description, () {
        for (final (status, expected, statusDescription) in [
          (SessionStatus.valid, false, 'セッションが生きていれば知らせない'),
          (SessionStatus.expired, true, 'セッションが切れていれば知らせる'),
          (SessionStatus.unknown, false, '確かめられなければ知らせない'),
        ]) {
          test(statusDescription, () async {
            setUpContainer(serverSessionStatus: status);

            trigger();
            await pumpEventQueue();

            expect(isNotifiedExpired(), expected);
          });
        }

        test('サインインしていなければ確かめない', () async {
          setUpContainer(user: const NoLogin());

          trigger();
          await pumpEventQueue();

          expect(fakeUserRepository.verifySessionCount, 0);
          expect(isNotifiedExpired(), false);
        });
      });
    }

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
    ]) {
      test('前面に戻ったのでなければ確かめない（$state）', () async {
        setUpContainer();

        observer().didChangeAppLifecycleState(state);
        await pumpEventQueue();

        expect(fakeUserRepository.verifySessionCount, 0);
      });
    }
  });
}
