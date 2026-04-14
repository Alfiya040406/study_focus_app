import 'package:flutter/material.dart';

import '../../services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  double fontScale = 1.0;
  String fontFamily = 'Poppins';

  final List<String> fonts = const [
    'Poppins',
    'Roboto',
    'Lato',
    'Nunito',
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = AppSettingsService.settingsNotifier.value;

    setState(() {
      darkMode = settings.darkMode;
      fontScale = settings.fontScale;
      fontFamily = settings.fontFamily;
    });
  }

  Future<void> saveDarkMode(bool value) async {
    await AppSettingsService.setDarkMode(value);
    setState(() {
      darkMode = value;
    });
  }

  Future<void> saveFontScale(double value) async {
    await AppSettingsService.setFontScale(value);
    setState(() {
      fontScale = value;
    });
  }

  Future<void> saveFontFamily(String value) async {
    await AppSettingsService.setFontFamily(value);
    setState(() {
      fontFamily = value;
    });
  }

  Widget buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildSectionCard(
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined,
                      color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    value: darkMode,
                    onChanged: saveDarkMode,
                  ),
                ],
              ),
            ),
            buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Preview text size',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    value: fontScale,
                    label: fontScale.toStringAsFixed(1),
                    onChanged: (value) async {
                      await saveFontScale(value);
                    },
                  ),
                ],
              ),
            ),
            buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Font Style',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: fontFamily,
                    items: fonts.map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await saveFontFamily(value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The quick brown fox jumps over the lazy dog.',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
