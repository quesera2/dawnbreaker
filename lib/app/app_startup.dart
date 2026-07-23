import 'dart:async';

import 'package:dawnbreaker/app/flavor.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_permission_observer.dart';
import 'package:dawnbreaker/data/preferences/shared_preferences_provider.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリの起動処理
class AppStartup {
  AppStartup._();

  /// 完了を待つ必要がある処理を記述し、生成した DI コンテナを返却する
  static Future<ProviderContainer> start({required Flavor flavor}) async {
    await Firebase.initializeApp(options: flavor.firebaseOptions);
    _startCrashReporting();

    await initializeDateFormatting();

    final container = await _createContainer();
    // 遅延させても良い処理は以下に書く
    startDeferredWork(container);
    return container;
  }

  /// Flutter とプラットフォームの未捕捉例外を Crashlytics へ送るようにする
  static void _startCrashReporting() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      return true;
    };
    unawaited(
      FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(true)
          .onError((e, s) {
            logger.e('enable crashlytics failed', error: e, stackTrace: s);
          }),
    );
  }

  static Future<ProviderContainer> _createContainer() async {
    final preferences = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
  }

  /// 完了を待つ必要がない非同期処理を記述する
  @visibleForTesting
  static void startDeferredWork(ProviderContainer container) {
    container.read(notificationPermissionObserverProvider);

    switch (container.read(currentUserProvider)) {
      case SignedInUser():
        // サインイン済みの場合は FCM トークンと最終アクティブ日時を連携
        unawaited(
          _registerNotificationToken(container).onError((e, s) {
            logger.e('registerToken failed', error: e, stackTrace: s);
          }),
        );
        unawaited(
          _updateLastActiveAt(container).onError((e, s) {
            logger.e('updateLastActiveAt failed', error: e, stackTrace: s);
          }),
        );
      case NoLogin():
        // 未サインイン時は何もしない
        break;
    }
  }

  static Future<void> _registerNotificationToken(
    ProviderContainer container,
  ) async {
    final service = await container.read(fcmNotificationServiceProvider.future);
    await service.registerToken();
  }

  static Future<void> _updateLastActiveAt(ProviderContainer container) async {
    final userSettings = await container.read(
      userSettingsRepositoryProvider.future,
    );
    await userSettings.updateLastActiveAt();
  }
}
