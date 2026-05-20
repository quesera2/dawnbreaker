import 'dart:async';

import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    bool initialNotificationEnabled = true,
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
  }) : notificationEnabled = initialNotificationEnabled,
       displayMode = initialDisplayMode;

  bool notificationEnabled;
  HomeDisplayMode displayMode;
  final _notificationController = StreamController<bool>.broadcast();
  final _displayModeController = StreamController<HomeDisplayMode>.broadcast();

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
}
