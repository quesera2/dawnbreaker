import 'package:dawnbreaker/data/model/home_display_mode.dart';

abstract interface class SettingsRepository {
  Stream<bool> watchNotificationEnabled();

  Future<void> setNotificationEnabled(bool value);

  Stream<HomeDisplayMode> watchHomeSortType();

  Future<void> setHomeSortType(HomeDisplayMode value);
}
