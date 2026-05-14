import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_onboarding_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsViewModel viewModel;
  late SettingsUiState viewState;
  late FakeOnboardingRepository fakeOnboardingRepository;

  void setUpContainer({bool notificationEnabled = true}) {
    PackageInfo.setMockInitialValues(
      appName: 'dawnbreaker',
      packageName: 'com.example.dawnbreaker',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
    fakeOnboardingRepository = FakeOnboardingRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(
            initialNotificationEnabled: notificationEnabled,
          ),
        ),
        onboardingRepositoryProvider.overrideWith(
          (_) => fakeOnboardingRepository,
        ),
      ],
    );
  }

  Future<void> setUpLoaded({bool notificationEnabled = true}) async {
    setUpContainer(notificationEnabled: notificationEnabled);
    await waitUntil(container, settingsViewModelProvider, (s) => !s.isLoading);
    viewModel = container.read(settingsViewModelProvider.notifier);
    container.listen(
      settingsViewModelProvider,
      (_, next) => viewState = next,
      fireImmediately: true,
    );
  }

  tearDown(() => container.dispose());

  group('SettingsViewModel', () {
    group('初期状態', () {
      setUp(() => setUpContainer());

      test('読み込み中である', () {
        expect(container.read(settingsViewModelProvider).isLoading, true);
      });

      test('バージョンが空である', () {
        expect(container.read(settingsViewModelProvider).version, isEmpty);
      });
    });

    group('ロード後', () {
      group('通知が有効な場合', () {
        setUp(() async => setUpLoaded());

        test('読み込みが完了している', () {
          expect(viewState.isLoading, false);
        });

        test('バージョンが表示される', () {
          expect(viewState.version, '1.2.3');
        });

        test('通知が有効である', () {
          expect(viewState.notificationEnabled, true);
        });
      });

      group('通知が無効な場合', () {
        setUp(() async => setUpLoaded(notificationEnabled: false));

        test('通知が無効である', () {
          expect(viewState.notificationEnabled, false);
        });
      });

      group('setNotificationEnabled', () {
        setUp(() async => setUpLoaded());

        test('処理中はisNotificationUpdatingがtrueになる', () async {
          final future = viewModel.setNotificationEnabled(false);
          expect(viewState.isNotificationUpdating, true);
          await future;
          expect(viewState.isNotificationUpdating, false);
        });

        test('通知が無効になる', () async {
          await viewModel.setNotificationEnabled(false);
          expect(viewState.notificationEnabled, false);
        });

        test('通知が有効になる', () async {
          await viewModel.setNotificationEnabled(false);
          await viewModel.setNotificationEnabled(true);
          expect(viewState.notificationEnabled, true);
        });
      });

      group('deleteTutorialFlag', () {
        setUp(() async => setUpLoaded());

        test('チュートリアルフラグが削除される', () async {
          await viewModel.deleteTutorialFlag();
          expect(fakeOnboardingRepository.removeCompletionCalled, true);
        });

        test('完了メッセージが表示される', () async {
          await viewModel.deleteTutorialFlag();
          expect(viewState.snackBarMessage, isA<TutorialFlagResetMessage>());
        });
      });
    });
  });
}
