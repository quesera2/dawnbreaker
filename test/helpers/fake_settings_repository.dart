import 'dart:async';

import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    bool initialNotificationEnabled = true,
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
    List<ColorSetting>? initialColorSettings,
  }) : notificationEnabled = initialNotificationEnabled,
       displayMode = initialDisplayMode,
       colorSettings = initialColorSettings ?? ColorSetting.defaults();

  bool notificationEnabled;
  HomeDisplayMode displayMode;
  List<ColorSetting> colorSettings;
  final _notificationController = StreamController<bool>.broadcast();
  final _displayModeController = StreamController<HomeDisplayMode>.broadcast();
  final _colorSettingsController =
      StreamController<List<ColorSetting>>.broadcast();

  @override
  Stream<bool> watchNotificationEnabled() async* {
    yield notificationEnabled;
    yield* _notificationController.stream;
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    notificationEnabled = value;
    _notificationController.add(value);
  }

  @override
  Stream<HomeDisplayMode> watchHomeDisplayMode() async* {
    yield displayMode;
    yield* _displayModeController.stream;
  }

  @override
  Future<void> setHomeDisplayMode(HomeDisplayMode value) async {
    displayMode = value;
    _displayModeController.add(value);
  }

  @override
  Stream<List<ColorSetting>> watchColorSettings() async* {
    yield colorSettings;
    yield* _colorSettingsController.stream;
  }

  @override
  Future<void> setColorSettings(List<ColorSetting> settings) async {
    colorSettings = settings;
    _colorSettingsController.add(settings);
  }
}
