import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class AIExplanationScreen extends StatefulWidget {
  const AIExplanationScreen({super.key});

  @override
  State<AIExplanationScreen> createState() => _AIExplanationScreenState();
}

class _AIExplanationScreenState extends State<AIExplanationScreen> {
  final TextEditingController questionController = TextEditingController();

  String email = '';
  bool isLoading = false;
  bool isLoadingNotes = true;
  bool isLoadingHistory = true;
  String resultText = '';

  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> aiHistory = [];
  int? selectedNoteId;

  @override
  void initState() {
    super.initState();
    loadUserAndData();
  }

  Future<void> loadUserAndData() async {
    setState(() {
      isLoadingNotes = true;
      isLoadingHistory = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      email = prefs.getString('email') ?? '';

      if (email.isEmpty) {
        setState(() {
          notes = [];
          aiHistory = [];
          isLoadingNotes = false;
          isLoadingHistory = false;
        });
        return;
      }

      final fetchedNotes = await ApiService.getNotes(email);
      final fetchedHistory = await ApiService.getAiHistory(email);

      setState(() {
        notes = fetchedNotes
            .map<Map<String, dynamic>>(
              (note) => Map<String, dynamic>.from(note as Map),
            )
            .toList();

        aiHistory = fetchedHistory
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        if (selectedNoteId != null &&
            !notes.any((note) => note['id'] == selectedNoteId)) {
          selectedNoteId = null;
        }

        isLoadingNotes = false;
        isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        notes = [];
        aiHistory = [];
        isLoadingNotes = false;
        isLoadingHistory = false;
        resultText = 'Error loading data: $e';
      });
    }
  }

  Future<void> clearHistory() async {
    if (email.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear AI History'),
          content: const Text(
            'Are you sure you want to delete all AI chat history?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.clearAiHistory(email);
      await loadUserAndData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI history cleared')),
      );
    } catch (e) {
      setState(() {
        resultText = 'Error clearing history: $e';
      });
    }
  }

  Future<void> explainSelectedNote() async {
    if (selectedNoteId == null) {
      setState(() {
        resultText = 'Please select a saved note first.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultText = '';
    });

    try {
      final answer = await ApiService.explainNoteById(
        noteId: selectedNoteId!,
        email: email,
      );

      setState(() {
        resultText = answer;
      });

      await loadUserAndData();
    } catch (e) {
      setState(() {
        resultText = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> askAboutSelectedNote() async {
    final question = questionController.text.trim();

    if (selectedNoteId == null) {
      setState(() {
        resultText = 'Please select a saved note first.';
      });
      return;
    }

    if (question.isEmpty) {
      setState(() {
        resultText = 'Please type your question first.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultText = '';
    });

    try {
      final answer = await ApiService.askNoteById(
        noteId: selectedNoteId!,
        email: email,
        question: question,
      );

      setState(() {
        resultText = answer;
      });

      await loadUserAndData();
    } catch (e) {
      setState(() {
        resultText = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> askGeneralAI() async {
    final question = questionController.text.trim();

    if (question.isEmpty) {
      setState(() {
        resultText = 'Please type your question first.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultText = '';
    });

    try {
      final answer = await ApiService.askAI(
        email: email,
        question: question,
      );

      setState(() {
        resultText = answer;
      });

      await loadUserAndData();
    } catch (e) {
      setState(() {
        resultText = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildHistoryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['question'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['answer'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            item['created_at'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ask AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingNotes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                  DropdownButtonFormField<int>(
                    value: selectedNoteId,
                    isExpanded: true,
                    items: notes.map((note) {
                      final int id = note['id'] as int;
                      final String subject = note['subject']?.toString() ?? '';
                      final String module = note['module']?.toString() ?? '';
                      final String fileName =
                          note['file_name']?.toString() ?? 'Untitled';

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '$subject - $module - $fileName',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: notes.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedNoteId = value;
                            });
                          },
                    decoration: const InputDecoration(
                      labelText: 'Select Saved Note (Optional for free AI)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notes.isEmpty
                              ? 'No saved notes found. Upload notes first.'
                              : '${notes.length} saved note(s) loaded.',
                          style: TextStyle(
                            color: notes.isEmpty ? Colors.red : Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: loadUserAndData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: questionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ask a question',
                      hintText:
                          'Type your question here or leave empty and use Explain Selected Note',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : explainSelectedNote,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text('Explain'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : askAboutSelectedNote,
                        icon: const Icon(Icons.quiz_outlined, size: 18),
                        label: const Text('Ask Note'),
                      ),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : askGeneralAI,
                        icon: const Icon(Icons.smart_toy_outlined, size: 18),
                        label: const Text('Ask AI'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SelectableText(
                      resultText.isEmpty
                          ? 'AI response will appear here.'
                          : resultText,
                      style: const TextStyle(height: 1.5),
                    ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chat History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (aiHistory.isNotEmpty)
                        TextButton.icon(
                          onPressed: clearHistory,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingHistory)
                    const Center(child: CircularProgressIndicator())
                  else if (aiHistory.isEmpty)
                    const Text('No AI chat history yet.')
                  else
                    ...aiHistory.map(buildHistoryCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
