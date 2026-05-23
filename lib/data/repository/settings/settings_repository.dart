import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';

abstract interface class SettingsRepository {
  Stream<bool> watchNotificationEnabled();

  Future<void> setNotificationEnabled(bool value);

  Stream<HomeDisplayMode> watchHomeDisplayMode();

  Future<void> setHomeDisplayMode(HomeDisplayMode value);

  Stream<List<ColorSetting>> watchColorSettings();

  Future<void> setColorSettings(List<ColorSetting> settings);
}
