import 'package:dawnbreaker/app/app.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/task_notification_sync.dart';
import 'package:dawnbreaker/data/preferences/shared_preferences_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  tz.initializeTimeZones();

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  final notificationService = await container.read(notificationServiceProvider.future);
  await notificationService.initialize();
  container.read(taskNotificationSyncProvider);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
