import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/splash_screen.dart';
import 'package:shedidthat/services/local_server_manager.dart';
import 'package:shedidthat/services/device_service.dart';
import 'package:shedidthat/screens/home_screen.dart';
import 'package:shedidthat/services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final storageService = StorageService();
    final isLocalMode = await storageService.getIsLocalMode();
    final hasBeenRun = await storageService.getHasBeenRunBefore();

    if (isLocalMode && hasBeenRun) {

        }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();

      Size windowSize;
      if (Platform.isMacOS) {
        final primaryDisplay = await screenRetriever.getPrimaryDisplay();
        final visibleSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
        windowSize = Size(768, visibleSize.height);
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

    Widget app = MyApp(home: hasBeenRun ? const HomeScreen() : const SplashScreen());
    if (!isLocalMode) {
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
      app = SentryWidget(child: app);
    }

    runApp(app);
  }, (exception, stackTrace) async {
    await Sentry.captureException(exception, stackTrace: stackTrace);
  });
}

class MyApp extends StatefulWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalServerManager().stopServer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      LocalServerManager().stopServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Enforce dark mode
      home: widget.home,
      debugShowCheckedModeBanner: false,
    );
  }
}
