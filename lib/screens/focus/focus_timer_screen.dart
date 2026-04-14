import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/study_method.dart';
import '../../services/api_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/study_method_service.dart';

enum TimerPhase { focus, breakTime, revision }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  final List<StudyMethod> methods = StudyMethodService.getStudyMethods();

  Timer? timer;
  late StudyMethod selectedMethod;

  TimerPhase currentPhase = TimerPhase.focus;
  int seconds = 0;
  int extraSeconds = 0;
  bool isRunning = false;
  bool routeMethodLoaded = false;

  @override
  void initState() {
    super.initState();
    selectedMethod = methods.first;
    seconds = selectedMethod.focusMinutes * 60;
    loadDefaultMethod();
  }

  Future<void> loadDefaultMethod() async {
    final savedTitle = await AppSettingsService.getDefaultMethod();
    if (savedTitle == null) return;

    final match = methods.where((m) => m.title == savedTitle);
    if (match.isNotEmpty) {
      setState(() {
        selectedMethod = match.first;
        seconds = selectedMethod.focusMinutes * 60;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (routeMethodLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is StudyMethod) {
      selectedMethod = args;
      currentPhase = TimerPhase.focus;
      seconds = selectedMethod.focusMinutes * 60;
    }

    routeMethodLoaded = true;
  }

  int get initialSeconds {
    switch (currentPhase) {
      case TimerPhase.focus:
        return selectedMethod.focusMinutes * 60;
      case TimerPhase.breakTime:
        return selectedMethod.breakMinutes * 60;
      case TimerPhase.revision:
        return selectedMethod.revisionMinutes * 60;
    }
  }

  String get phaseTitle {
    switch (currentPhase) {
      case TimerPhase.focus:
        return 'Focus Session';
      case TimerPhase.breakTime:
        return 'Break Time';
      case TimerPhase.revision:
        return 'Revision Time';
    }
  }

  String get timeText {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get extraTimeText {
    final int mins = extraSeconds ~/ 60;
    final int secs = extraSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> openMethodVideo() async {
    final Uri uri = Uri.parse(selectedMethod.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> saveCompletedStudyTime(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';

      if (email.isEmpty) return;

      await ApiService.saveStudySession(
        email: email,
        methodTitle: selectedMethod.title,
        phase: currentPhase.name,
        minutes: minutes,
      );
    } catch (e) {
      debugPrint('Error saving study time: $e');
    }
  }

  void updateSelectedMethod(StudyMethod method) {
    timer?.cancel();

    setState(() {
      selectedMethod = method;
      currentPhase = TimerPhase.focus;
      seconds = method.focusMinutes * 60;
      extraSeconds = 0;
      isRunning = false;
    });
  }

  void setPhase(TimerPhase phase) {
    timer?.cancel();

    setState(() {
      currentPhase = phase;
      seconds = phase == TimerPhase.focus
          ? selectedMethod.focusMinutes * 60
          : phase == TimerPhase.breakTime
          ? selectedMethod.breakMinutes * 60
          : selectedMethod.revisionMinutes * 60;
      extraSeconds = 0;
      isRunning = false;
    });
  }

  void startTimer() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          extraSeconds++;
        }
      });

      if (seconds == 0 && extraSeconds == 1) {
        showCompletionDialog();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      seconds = initialSeconds;
      extraSeconds = 0;
      isRunning = false;
    });
  }

  void showCompletionDialog() {
    String title;
    String message;
    List<Widget> actions;

    if (currentPhase == TimerPhase.focus) {
      saveCompletedStudyTime(selectedMethod.focusMinutes);

      title = 'Focus Session Complete 🎉';
      message =
          'You completed your focus time.\n\nNow you can take a break or continue revision.\n\nIf you keep studying, the app will continue counting extra study time.';
      actions = [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setPhase(TimerPhase.breakTime);
            startTimer();
          },
          child: const Text('Start Break'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            setPhase(TimerPhase.revision);
            startTimer();
          },
          child: const Text('Start Revision'),
        ),
      ];
    } else if (currentPhase == TimerPhase.revision) {
      saveCompletedStudyTime(selectedMethod.revisionMinutes);

      title = 'Revision Complete ✅';
      message =
          'Revision completed.\n\nYou can now take a break. If you continue, extra revision time will be tracked on screen.';
      actions = [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            setPhase(TimerPhase.breakTime);
            startTimer();
          },
          child: const Text('Start Break'),
        ),
      ];
    } else {
      title = 'Break Complete ☕';
      message = 'Break finished. You can start your next focus session now.';
      actions = [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            setPhase(TimerPhase.focus);
            startTimer();
          },
          child: const Text('Start Focus'),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = initialSeconds;
    final double progress = totalSeconds == 0
        ? 0
        : (seconds / totalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9FA8FF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Study Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StudyMethod>(
                    value: selectedMethod,
                    dropdownColor: Colors.white,
                    items: methods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.title),
                      );
                    }).toList(),
                    onChanged: (method) {
                      if (method != null) {
                        updateSelectedMethod(method);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: openMethodVideo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Method Explanation'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    phaseTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                        ),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (extraSeconds > 0)
                    Text(
                      'Extra time studied: $extraTimeText',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isRunning ? null : startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isRunning ? pauseTimer : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                      OutlinedButton.icon(
                        onPressed: resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setPhase(TimerPhase.focus),
                    child: const Text('Focus'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setPhase(TimerPhase.breakTime),
                    child: const Text('Break'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setPhase(TimerPhase.revision),
                    child: const Text('Revision'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
