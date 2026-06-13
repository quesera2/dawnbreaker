import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';

abstract interface class SettingsRepository {
  Stream<NotificationSetting> watchNotificationSetting();

  Future<void> setNotificationSetting(NotificationSetting setting);

  Stream<HomeDisplayMode> watchHomeDisplayMode();

  Future<void> setHomeDisplayMode(HomeDisplayMode value);

  Stream<List<ColorSetting>> watchColorSettings();

  Future<void> setColorSettings(List<ColorSetting> settings);

  Stream<bool> watchProgressBarAnimationEnabled();

  Future<void> setProgressBarAnimationEnabled(bool value);
}
