import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';

/// 端末固有の設定。アカウントに紐づく通知設定は [UserSettingsRepository] が持つ
abstract interface class SettingsRepository {
  Stream<HomeDisplayMode> watchHomeDisplayMode();

  Future<void> setHomeDisplayMode(HomeDisplayMode value);

  Stream<List<ColorSetting>> watchColorSettings();

  Future<void> setColorSettings(List<ColorSetting> settings);

  Stream<bool> watchProgressBarAnimationEnabled();

  Future<void> setProgressBarAnimationEnabled(bool value);
}
