import 'package:app_settings/app_settings.dart';
import 'package:app_settings/app_settings_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeAppSettingsPlatform
    with MockPlatformInterfaceMixin
    implements AppSettingsPlatform {
  AppSettingsType? openedType;

  @override
  Future<void> openAppSettings({
    AppSettingsType type = AppSettingsType.settings,
    bool asAnotherTask = false,
  }) async {
    openedType = type;
  }

  @override
  Future<void> openAppSettingsPanel(AppSettingsPanelType type) async {}
}
