import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../focus/focus_timer_screen.dart';
import '../settings/settings_screen.dart';
import '../study/ai_explanation_screen.dart';
import '../study/notes_upload_screen.dart';
import '../study/study_method_screen.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  int homeRefreshToken = 0;

  final List<String> titles = const [
    'Home',
    'Study Methods',
    'Upload Notes',
    'Ask AI',
    'Focus Timer',
    'Settings',
  ];

  List<Widget> get screens => [
        HomeScreen(
          key: ValueKey(homeRefreshToken),
          onNavigate: changeScreen,
        ),
        const StudyMethodScreen(),
        const NotesUploadScreen(),
        const AIExplanationScreen(),
        const FocusTimerScreen(),
        const SettingsScreen(),
      ];

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('email');

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void changeScreen(int index) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    setState(() {
      currentIndex = index;
      if (index == 0) {
        homeRefreshToken++;
      }
    });
  }

  Drawer buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8E97FD)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.school, size: 28),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Study Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Learn smarter 🚀',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => changeScreen(0),
            ),
            ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('Study Methods'),
              onTap: () => changeScreen(1),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload Notes'),
              onTap: () => changeScreen(2),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Ask AI'),
              onTap: () => changeScreen(3),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Focus Timer'),
              onTap: () => changeScreen(4),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => changeScreen(5),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: signOut,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(
        title: Text(titles[currentIndex]),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
    );
  }
}
