import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsViewModel', () {
    late ProviderContainer container;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'dawnbreaker',
        packageName: 'com.example.dawnbreaker',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    group('初期状態', () {
      test('バージョンが読み込み中である', () {
        final state = container.read(settingsViewModelProvider);
        expect(state.isLoading, true);
      });

      test('バージョンが空である', () {
        final state = container.read(settingsViewModelProvider);
        expect(state.version, isEmpty);
      });
    });

    group('ロード後', () {
      setUp(() async {
        container.read(settingsViewModelProvider);
        await Future<void>.microtask(() {});
      });

      test('バージョンが表示される', () {
        expect(container.read(settingsViewModelProvider).version, '1.2.3');
      });

      test('読み込みが完了している', () {
        expect(container.read(settingsViewModelProvider).isLoading, false);
      });
    });
  });
}
