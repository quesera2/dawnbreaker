import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_user_repository.dart';

void main() {
  group('taskRepository', () {
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

      // ViewModel は build で read / watch するため、この2つが本番で通る経路になる。
      // どちらも ProviderException に包まれて届き、元の例外は exception に入る
      test('読み出すとタスクを読み書きできない', () {
        expect(
          () => container.read(taskRepositoryProvider),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isA<TaskNotSignedInException>(),
            ),
          ),
        );
      });

      test('watch している Provider も使えなくなる', () {
        final dependent = Provider((ref) => ref.watch(taskRepositoryProvider));

        expect(
          () => container.read(dependent),
          throwsA(isA<ProviderException>()),
        );
      });

      test('購読している側にサインインしていないことが伝わる', () {
        Object? thrown;
        final subscription = container.listen(
          taskRepositoryProvider,
          (_, _) {},
          onError: (error, _) => thrown = error,
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        expect(thrown, isA<TaskNotSignedInException>());
      });
    });
  });
}
