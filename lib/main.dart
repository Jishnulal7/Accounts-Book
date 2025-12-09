import 'dart:io';
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:account_book/app.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:account_book/app/data/db/hive.dart';
import 'package:account_book/app/data/db/storage.dart';
import 'package:account_book/app/data/constants/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:account_book/app/providers/theme_provider.dart';
import 'package:account_book/app/screens/home/home_screen.dart';
import 'package:account_book/app/screens/onboarding/onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferences.getInstance();
  await HiveService.initializeHive();
  await StorageService.initializeStorage();
  final initialScreen = await _determineInitialScreen();

  runApp(
    kDebugMode
        ? (Platform.isAndroid
            ? MyAppWrapper(
                initialScreen: initialScreen,
              )
            : MyAppWrapper(
                initialScreen: initialScreen,
              ))
        : MyAppWrapper(
            initialScreen: initialScreen,
          ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          themeMode: themeNotifier.themeMode,
          theme: themes(ThemeMode.light, themeNotifier.themeColor),
          darkTheme: themes(ThemeMode.dark, themeNotifier.themeColor),
          title: 'Account Book',
          debugShowCheckedModeBanner: false,
          locale: const Locale('en_US'),
          home: initialScreen,
        );
      },
    );
  }
}

Future<Widget> _determineInitialScreen() async {
  final prefs = await SharedPreferences.getInstance();

  // Check if business data exists
  final businessDataString = prefs.getString('businessData');

  if (businessDataString != null) {
    // Business data exists, go to HomeScreen
    return const HomeScreen();
  } else {
    // No business data, show OnboardingScreen
    return const OnboardingScreen();
  }
}
