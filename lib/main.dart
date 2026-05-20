import 'package:dawnbreaker/app/app.dart';
import 'package:dawnbreaker/core/notification/notification_permission_observer.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/task_notification_sync_notifier.dart';
import 'package:dawnbreaker/data/preferences/shared_preferences_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting();
  tz.initializeTimeZones();
  final localTimezone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  final notificationService = await container.read(
    notificationServiceProvider.future,
  );
  await notificationService.initialize();
  container.read(taskNotificationSyncProvider);
  container.read(notificationPermissionObserverProvider);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
