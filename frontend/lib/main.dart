import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/splash_screen.dart';
import 'services/device_service.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://12b7eb577913149a1ca8b5054a46db9d@o4509949000482816.ingest.us.sentry.io/4510902247686144';
        options.sendDefaultPii = true;
        options.enableLogs = true;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
    );

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();

      Size windowSize;
      if (Platform.isMacOS) {
        final primaryDisplay = await screenRetriever.getPrimaryDisplay();
        windowSize = Size(768, primaryDisplay.size.height);
      } else {
        windowSize = const Size(400, 800);
      }

      WindowOptions windowOptions = WindowOptions(
        size: windowSize,
        minimumSize: windowSize,
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    await DeviceService.registerDevice();
    runApp(SentryWidget(child: const MyApp()));
  }, (exception, stackTrace) async {
    await Sentry.captureException(exception, stackTrace: stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'She Absolutely Just Did That',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme, // Optional: Explicitly set dark theme
      themeMode: ThemeMode.dark, // Enforce dark mode
      home: const SplashScreen(),
    );
  }
}
