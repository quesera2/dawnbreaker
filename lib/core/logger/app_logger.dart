import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  output: kDebugMode ? ConsoleOutput() : _CrashlyticsOutput(),
  printer: kDebugMode
      ? PrettyPrinter(methodCount: 2)
      : SimplePrinter(printTime: true, colors: false),
);

final class _CrashlyticsOutput extends LogOutput {
  final _crashlytics = FirebaseCrashlytics.instance;

  @override
  void output(OutputEvent event) {
    final message = event.lines.join('\n');
    _crashlytics.log(message);
    final error = event.origin.error;
    if (error != null) {
      _crashlytics.recordError(
        error,
        event.origin.stackTrace,
        reason: message,
        fatal: event.level == Level.fatal,
      );
    }
  }
}
