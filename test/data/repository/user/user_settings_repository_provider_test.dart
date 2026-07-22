import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_user_repository.dart';

void main() {
  test('サインインしていないユーザーは通知設定を持たない', () async {
    final repository = FakeUserRepository(const NoLogin());
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });

    // Riverpod は失敗した Provider を自動で作り直すため `.future` は完了しない。
    // 状態に載ったエラーを見る
    final subscription = container.listen(
      userSettingsRepositoryProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(userSettingsRepositoryProvider).error,
      isA<UserSettingsNotSignedInException>(),
    );
  });
}
