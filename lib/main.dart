import 'dart:async';
import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/app_config.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/widget/splash_screen.dart';

main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details, {bool forceReport = false}) {
        if (isInDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        } else {
          ErrorReporter.reportError(details.exception, details.stack);
        }
      };

      final config = await rootBundle.loadString('assets/cfg/config.json');
      AppConfig.fromJson(json.decode(config));

      runApp(ProviderScope(child: NhkNewsEasy()));
    },
    (error, stackTrace) {
      _reportError(error, stackTrace);
    },
  );
}

Future<void> _reportError(dynamic error, dynamic stackTrace) async {
  if (isInDebugMode) {
    print(stackTrace);
  } else {
    ErrorReporter.reportError(error, stackTrace);
  }
}

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}

class NhkNewsEasy extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightColorScheme = lightDynamic ?? _defaultLightColorScheme;
        final darkColorScheme = darkDynamic ?? _defaultDarkColorScheme;

        return MaterialApp(
          title: '新報',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: lightColorScheme.surface,
              foregroundColor: lightColorScheme.onSurface,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            listTileTheme: ListTileThemeData(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: darkColorScheme.surface,
              foregroundColor: darkColorScheme.onSurface,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            listTileTheme: ListTileThemeData(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}

const _defaultLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1976D2),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF03DAC6),
  onSecondary: Color(0xFF000000),
  error: Color(0xFFB00020),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFBFE),
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerHighest: Color(0xFFE6E0E9),
  outline: Color(0xFF79747E),
);

const _defaultDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF90CAF9),
  onPrimary: Color(0xFF000000),
  secondary: Color(0xFF03DAC6),
  onSecondary: Color(0xFF000000),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  surface: Color(0xFF1C1B1F),
  onSurface: Color(0xFFE6E1E5),
  surfaceContainerHighest: Color(0xFF49454F),
  outline: Color(0xFF938F99),
);
