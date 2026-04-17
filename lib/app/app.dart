import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final _colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  static final _theme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.surface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dawnbreaker',
      theme: _theme,
      home: const HomeScreen(),
    );
  }
}
