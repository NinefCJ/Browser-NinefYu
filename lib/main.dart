import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/settings_service.dart';
import 'features/customization/theme_engine.dart';
import 'pages/browser_home_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeEngineProvider);
    final themeNotifier = ref.read(themeEngineProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Browser NinefYu',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.getThemeData(isDark: false),
      darkTheme: themeNotifier.getThemeData(isDark: true),
      themeMode: _getThemeMode(themeState.mode),
      home: const BrowserHomePage(),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      case AppThemeMode.monet:
        return ThemeMode.system;
    }
  }
}