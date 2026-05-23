import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_ui_state.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  late ProviderContainer container;
  late ColorLabelViewModel viewModel;
  late ColorLabelUiState viewState;
  late FakeSettingsRepository fakeRepository;

  void setUpContainer({List<ColorSetting>? initialColorSettings}) {
    fakeRepository = FakeSettingsRepository(
      initialColorSettings: initialColorSettings,
    );
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    addTearDown(container.dispose);
  }

  Future<void> setUpLoaded({List<ColorSetting>? initialColorSettings}) async {
    setUpContainer(initialColorSettings: initialColorSettings);
    // container.listen を先に張り provider を生かし続ける
    // （waitUntil が sub.close() するとリスナーゼロになり auto-dispose される）
    container.listen(
      colorLabelViewModelProvider,
      (_, next) => viewState = next,
      fireImmediately: true,
    );
    await waitUntil(
      container,
      colorLabelViewModelProvider,
      (s) => !s.isLoading,
    );
    await pumpEventQueue();
    viewModel = container.read(colorLabelViewModelProvider.notifier);
  }

  group('ColorLabelViewModel', () {
    group('初期状態', () {
      test('ロード中', () {
        setUpContainer();
        final state = container.read(colorLabelViewModelProvider);
        expect(state.isLoading, isTrue);
      });
    });

    group('ロード後', () {
      group('toggleMode', () {
        test('editモードからsortモードに切り替わる', () async {
          await setUpLoaded();
          expect(viewState.mode, ColorLabelMode.edit);
          viewModel.toggleMode();
          expect(viewState.mode, ColorLabelMode.sort);
        });

        test('sortモードからeditモードに戻る', () async {
          await setUpLoaded();
          viewModel.toggleMode();
          viewModel.toggleMode();
          expect(viewState.mode, ColorLabelMode.edit);
        });
      });

      group('updateAlias', () {
        test('指定したカラーのエイリアスが更新される', () async {
          await setUpLoaded();
          await viewModel.updateAlias(TaskColor.red, 'キッチン');
          await pumpEventQueue();
          final red = viewState.settings.firstWhere(
            (s) => s.color == TaskColor.red,
          );
          expect(red.alias, 'キッチン');
        });

        test('他のカラーのエイリアスは変わらない', () async {
          await setUpLoaded();
          await viewModel.updateAlias(TaskColor.red, 'キッチン');
          await pumpEventQueue();
          final blue = viewState.settings.firstWhere(
            (s) => s.color == TaskColor.blue,
          );
          expect(blue.alias, '');
        });

        test('変更がリポジトリに保存される', () async {
          await setUpLoaded();
          await viewModel.updateAlias(TaskColor.green, '植物');
          final saved = fakeRepository.colorSettings.firstWhere(
            (s) => s.color == TaskColor.green,
          );
          expect(saved.alias, '植物');
        });
      });

      group('reorder', () {
        test('先頭要素を末尾に移動できる', () async {
          final initial = ColorSetting.defaults();
          await setUpLoaded(initialColorSettings: initial);
          final firstColor = initial.first.color;

          await viewModel.reorder(0, initial.length - 1);
          await pumpEventQueue();
          expect(viewState.settings.last.color, firstColor);
        });

        test('末尾要素を先頭に移動できる', () async {
          final initial = ColorSetting.defaults();
          await setUpLoaded(initialColorSettings: initial);
          final lastColor = initial.last.color;

          await viewModel.reorder(initial.length - 1, 0);
          await pumpEventQueue();
          expect(viewState.settings.first.color, lastColor);
        });

        test('並び替えがリポジトリに保存される', () async {
          final initial = ColorSetting.defaults();
          await setUpLoaded(initialColorSettings: initial);
          final lastColor = initial.last.color;

          await viewModel.reorder(initial.length - 1, 0);
          expect(fakeRepository.colorSettings.first.color, lastColor);
        });
      });
    });
  });
}
