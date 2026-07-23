import 'package:dawnbreaker/app/app.dart';
import 'package:dawnbreaker/app/app_startup.dart';
import 'package:dawnbreaker/app/flavor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final container = await AppStartup.start(
    flavor: Flavor.values.byName(flavorName),
  );

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
