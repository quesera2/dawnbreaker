import 'dart:async';

import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';

import 'watch_stream.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
    List<ColorSetting>? initialColorSettings,
    bool initialProgressBarAnimationEnabled = true,
  }) : displayMode = initialDisplayMode,
       colorSettings = initialColorSettings ?? ColorSetting.defaults(),
       progressBarAnimationEnabled = initialProgressBarAnimationEnabled;

  HomeDisplayMode displayMode;
  List<ColorSetting> colorSettings;
  bool progressBarAnimationEnabled;
  final _displayModeController = StreamController<HomeDisplayMode>.broadcast();
  final _colorSettingsController =
      StreamController<List<ColorSetting>>.broadcast();
  final _progressBarAnimationController = StreamController<bool>.broadcast();

  @override
  Stream<HomeDisplayMode> watchHomeDisplayMode() =>
      watchWithCurrent(displayMode, _displayModeController.stream);

  @override
  Future<void> setHomeDisplayMode(HomeDisplayMode value) async {
    displayMode = value;
    _displayModeController.add(value);
  }

  @override
  Stream<List<ColorSetting>> watchColorSettings() =>
      watchWithCurrent(colorSettings, _colorSettingsController.stream);

  @override
  Future<void> setColorSettings(List<ColorSetting> settings) async {
    colorSettings = settings;
    _colorSettingsController.add(settings);
  }

  @override
  Stream<bool> watchProgressBarAnimationEnabled() => watchWithCurrent(
    progressBarAnimationEnabled,
    _progressBarAnimationController.stream,
  );

  @override
  Future<void> setProgressBarAnimationEnabled(bool value) async {
    progressBarAnimationEnabled = value;
    _progressBarAnimationController.add(value);
  }
}
