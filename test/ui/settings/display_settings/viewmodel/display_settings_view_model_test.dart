import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/ui/settings/display_settings/viewmodel/display_settings_ui_state.dart';
import 'package:dawnbreaker/ui/settings/display_settings/viewmodel/display_settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/riverpod_test_helper.dart';

void main() {
  late ProviderContainer container;
  late DisplaySettingsViewModel viewModel;
  late DisplaySettingsUiState viewState;
  late FakeSettingsRepository fakeSettingsRepository;

  void setUpContainer({
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
  }) {
    fakeSettingsRepository = FakeSettingsRepository(
      initialDisplayMode: initialDisplayMode,
    );
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepository),
      ],
    );
  }

  Future<void> setUpLoaded({
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
  }) async {
    setUpContainer(initialDisplayMode: initialDisplayMode);
    container.listen(
      displaySettingsViewModelProvider,
      (_, next) => viewState = next,
      fireImmediately: true,
    );
    viewModel = container.read(displaySettingsViewModelProvider.notifier);
    await waitUntil(
      container,
      displaySettingsViewModelProvider,
      (s) => !s.isLoading,
    );
    // async* の yield* 購読が確立されるまで待つ
    await pumpEventQueue();
  }

  tearDown(() => container.dispose());

  group('DisplaySettingsViewModel', () {
    group('初期値', () {
      for (final (mode, label) in [
        (HomeDisplayMode.timeline, 'タイムライン'),
        (HomeDisplayMode.byColor, 'カラーグループ'),
      ]) {
        test('$labelが正しく読み込まれる', () async {
          await setUpLoaded(initialDisplayMode: mode);
          expect(viewState.displayMode, mode);
        });
      }
    });

    group('setDisplayMode', () {
      setUp(() async => setUpLoaded());

      test('表示モードが変更される', () async {
        await viewModel.setDisplayMode(HomeDisplayMode.byColor);
        await pumpEventQueue();
        expect(viewState.displayMode, HomeDisplayMode.byColor);
      });

      test('リポジトリに保存される', () async {
        await viewModel.setDisplayMode(HomeDisplayMode.byColor);
        expect(fakeSettingsRepository.displayMode, HomeDisplayMode.byColor);
      });
    });

    group('外部変更', () {
      setUp(() async => setUpLoaded());

      test('リポジトリの変更がstateに反映される', () async {
        await fakeSettingsRepository.setHomeDisplayMode(
          HomeDisplayMode.byColor,
        );
        await pumpEventQueue();
        expect(viewState.displayMode, HomeDisplayMode.byColor);
      });
    });
  });
}
