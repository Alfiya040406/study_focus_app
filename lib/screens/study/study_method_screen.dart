import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/study_method.dart';
import '../../services/app_settings_service.dart';
import '../../services/study_method_service.dart';

class StudyMethodScreen extends StatefulWidget {
  const StudyMethodScreen({super.key});

  @override
  State<StudyMethodScreen> createState() => _StudyMethodScreenState();
}

class _StudyMethodScreenState extends State<StudyMethodScreen> {
  late final List<StudyMethod> _methods;
  StudyMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _methods = StudyMethodService.getStudyMethods();
  }

  Future<void> _watchExplanation(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open video')));
    }
  }

  Future<void> _selectMethod(StudyMethod method) async {
    setState(() {
      _selectedMethod = method;
    });

    await AppSettingsService.setDefaultMethod(method.title);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${method.title} selected')));
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(StudyMethod method) {
    final bool isSelected = _selectedMethod?.title == method.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.12)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  method.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            method.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTimeChip(
                icon: Icons.timer_outlined,
                label: 'Focus',
                value: '${method.focusMinutes} min',
                color: Colors.deepPurple,
              ),
              _buildTimeChip(
                icon: Icons.free_breakfast_outlined,
                label: 'Break',
                value: '${method.breakMinutes} min',
                color: Colors.green,
              ),
              _buildTimeChip(
                icon: Icons.menu_book_outlined,
                label: 'Revision',
                value: '${method.revisionMinutes} min',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _watchExplanation(method.videoUrl),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch Explanation'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectMethod(method),
                  icon: const Icon(Icons.check),
                  label: Text(isSelected ? 'Selected' : 'Select'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToFocus() {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a study method first.')),
      );
      return;
    }

    Navigator.pushNamed(context, '/focus', arguments: _selectedMethod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ..._methods.map(_buildMethodCard),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _goToFocus,
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Continue to Focus Timer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
