import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_user_repository.dart';

void main() {
  test('サインインしていないユーザーではタスクを読み書きできない', () async {
    final repository = FakeUserRepository(const NoLogin());
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });

    // read() は例外を ProviderException に包んで投げ、その型は公開されていない。
    // onError には元の例外がそのまま届くのでこちらで受ける
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
}
