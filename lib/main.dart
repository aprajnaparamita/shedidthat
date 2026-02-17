
import 'package:flutter/material.dart';
import 'package:she_absolutely_just_did_that/screens/home_screen.dart';
import 'package:she_absolutely_just_did_that/services/device_service.dart';
import 'package:she_absolutely_just_did_that/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register the device when the app starts
  await DeviceService.registerDevice('https://she-absolutely-just-did-that-api.fly.dev');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'She Absolutely Just Did That',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Or ThemeMode.light, ThemeMode.dark
      home: const HomeScreen(),
    );
  }
}
