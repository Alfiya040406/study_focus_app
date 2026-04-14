import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/focus/focus_timer_screen.dart';
import 'screens/home/main_navigation.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/study/ai_explanation_screen.dart';
import 'screens/study/notes_upload_screen.dart';
import 'screens/study/study_method_screen.dart';
import 'services/app_settings_service.dart';

class StudyTrackerApp extends StatefulWidget {
  const StudyTrackerApp({super.key});

  @override
  State<StudyTrackerApp> createState() => _StudyTrackerAppState();
}

class _StudyTrackerAppState extends State<StudyTrackerApp> {
  bool _isLoading = true;

  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    final prefs = await SharedPreferences.getInstance();

    final bool hasSeenIntro = prefs.getBool('intro_seen') ?? false;
    final String savedEmail = prefs.getString('email') ?? '';

    await AppSettingsService.loadSettings();

    Widget nextScreen;

    if (!hasSeenIntro) {
      nextScreen = const IntroScreen();
    } else if (savedEmail.isNotEmpty) {
      nextScreen = const MainNavigation();
    } else {
      nextScreen = const LoginScreen();
    }

    if (!mounted) return;

    setState(() {
      _initialScreen = nextScreen;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<AppSettingsModel>(
      valueListenable: AppSettingsService.settingsNotifier,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Study Tracker',
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme(
            fontFamily: settings.fontFamily,
            fontScale: settings.fontScale,
          ),
          darkTheme: AppTheme.darkTheme(
            fontFamily: settings.fontFamily,
            fontScale: settings.fontScale,
          ),
          home: _initialScreen,
          routes: {
            '/intro': (context) => const IntroScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const MainNavigation(),
            '/methods': (context) => const StudyMethodScreen(),
            '/upload': (context) => const NotesUploadScreen(),
            '/ai': (context) => const AIExplanationScreen(),
            '/focus': (context) => const FocusTimerScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
