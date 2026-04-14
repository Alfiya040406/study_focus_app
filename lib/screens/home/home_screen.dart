import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'User';
  String userEmail = '';
  bool isLoading = true;

  int todayMinutes = 0;
  int totalMinutes = 0;
  List<Map<String, dynamic>> studyHistory = [];

  final List<String> quotes = const [
    'Stay consistent. Small progress adds up.',
    'Focus on progress, not perfection.',
    'One focused session can change your whole day.',
    'Keep learning, keep growing.',
    'Discipline today creates success tomorrow.',
  ];

  String get quote {
    final index = DateTime.now().day % quotes.length;
    return quotes[index];
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString('username') ?? 'User';
    final savedEmail = prefs.getString('email') ?? '';

    setState(() {
      userName = savedName;
      userEmail = savedEmail;
    });

    if (savedEmail.isNotEmpty) {
      await loadStudySummary();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadStudySummary() async {
    try {
      final data = await ApiService.getStudySummary(email: userEmail);

      setState(() {
        todayMinutes = data['today_minutes'] ?? 0;
        totalMinutes = data['total_minutes'] ?? 0;
        studyHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatMinutes(int minutes) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }

  Widget buildQuickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item['date'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            formatMinutes(item['minutes'] ?? 0),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String todayStudyText = formatMinutes(todayMinutes);
    final String totalStudyText = formatMinutes(totalMinutes);

    return RefreshIndicator(
      onRefresh: loadStudySummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 84,
                width: 84,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hello, $userName 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Let’s make today productive.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9FA8FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '"$quote"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 120,
              ),
              itemBuilder: (context, index) {
                final items = [
                  {
                    'title': 'Study Methods',
                    'icon': Icons.psychology_alt_outlined,
                    'color': Colors.deepPurple,
                    'index': 1,
                  },
                  {
                    'title': 'Upload Notes',
                    'icon': Icons.upload_file_outlined,
                    'color': Colors.teal,
                    'index': 2,
                  },
                  {
                    'title': 'Ask AI',
                    'icon': Icons.smart_toy_outlined,
                    'color': Colors.orange,
                    'index': 3,
                  },
                  {
                    'title': 'Focus Timer',
                    'icon': Icons.timer_outlined,
                    'color': Colors.blue,
                    'index': 4,
                  },
                ];

                final item = items[index];

                return buildQuickAction(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  onTap: () => widget.onNavigate(item['index'] as int),
                );
              },
            ),
            const SizedBox(height: 24),
            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              buildStatCard(
                title: 'Time Studied Today',
                value: todayStudyText,
                icon: Icons.today,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 14),
              buildStatCard(
                title: 'Total Study Time',
                value: totalStudyText,
                icon: Icons.bar_chart,
                color: Colors.blue,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(Icons.history, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Study History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (studyHistory.isEmpty && !isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'No study history yet. Start a focus session to track your learning time.',
                ),
              )
            else
              ...studyHistory.map(buildHistoryItem),
          ],
        ),
      ),
    );
  }
}
