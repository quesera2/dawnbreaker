import 'dart:async';

import 'package:dawnbreaker/app/app.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_permission_observer.dart';
import 'package:dawnbreaker/data/preferences/shared_preferences_provider.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/firebase_options_dev.dart' as dev_options;
import 'package:dawnbreaker/firebase_options_prod.dart' as prod_options;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final firebaseOptions = flavor == 'prod'
      ? prod_options.DefaultFirebaseOptions.currentPlatform
      : dev_options.DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting();

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  // PR2 時点では挙動を変えないため、これまで getUser() が内部でやっていた匿名サインインを
  // ここで明示的に呼ぶ。無条件に呼ぶと「匿名でない既存ユーザーはサインアウトされる」という
  // FirebaseAuth.signInAnonymously() の仕様を踏むため、NoLogin のときだけに絞る。外すのは PR4
  final userRepository = container.read(userRepositoryProvider);
  if (userRepository.getUser() is NoLogin) {
    await userRepository.signInAsGuest();
  }
  await container.read(taskRepositoryProvider.future);
  // どちらも初回フレームの描画に必要なく、Firestore への書き込み Future はオフラインでは
  // 完了しないため待たない。待つとスプラッシュが出たままアプリが起動しなくなる
  final notificationService = await container.read(
    fcmNotificationServiceProvider.future,
  );
  unawaited(
    notificationService.registerToken().onError((e, s) {
      logger.e('registerToken failed', error: e, stackTrace: s);
    }),
  );
  final userSettings = await container.read(
    userSettingsRepositoryProvider.future,
  );
  unawaited(
    userSettings.updateLastActiveAt().onError((e, s) {
      logger.e('updateLastActiveAt failed', error: e, stackTrace: s);
    }),
  );
  container.read(notificationPermissionObserverProvider);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
