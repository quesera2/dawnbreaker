import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_notification_token_repository.dart';
import 'package:dawnbreaker/data/repository/user/notification_token_repository_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_user_repository.dart';

void main() {
  group('notificationTokenRepository', () {
    group('サインインしていない場合', () {
      late FakeUserRepository userRepository;
      late ProviderContainer container;

      setUp(() {
        userRepository = FakeUserRepository(const NoLogin());
        container = ProviderContainer(
          overrides: [userRepositoryProvider.overrideWithValue(userRepository)],
        );
      });

      tearDown(() async {
        container.dispose();
        await userRepository.close();
      });

      // 消費側は build で read / watch するため、この2つが本番で通る経路になる。
      // どちらも ProviderException に包まれて届き、元の例外は exception に入る
      test('通知トークンを登録できない', () {
        expect(
          () => container.read(notificationTokenRepositoryProvider),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isA<NotificationTokenNotSignedInException>(),
            ),
          ),
        );
      });

      test('watch している Provider も使えなくなる', () {
        final dependent = Provider(
          (ref) => ref.watch(notificationTokenRepositoryProvider),
        );

        expect(
          () => container.read(dependent),
          throwsA(isA<ProviderException>()),
        );
      });

      test('購読している側にサインインしていないことが伝わる', () {
        Object? thrown;
        final subscription = container.listen(
          notificationTokenRepositoryProvider,
          (_, _) {},
          onError: (error, _) => thrown = error,
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        expect(thrown, isA<NotificationTokenNotSignedInException>());
      });
    });
  });
}
