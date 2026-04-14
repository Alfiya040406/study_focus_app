import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/file_service.dart';

class NotesUploadScreen extends StatefulWidget {
  const NotesUploadScreen({super.key});

  @override
  State<NotesUploadScreen> createState() => _NotesUploadScreenState();
}

class _NotesUploadScreenState extends State<NotesUploadScreen> {
  final TextEditingController subjectController = TextEditingController();

  File? selectedFile;
  List<dynamic> notes = [];
  String email = '';
  String selectedModule = 'Module 1';
  bool isLoading = false;

  final List<String> modules = const [
    'Module 1',
    'Module 2',
    'Module 3',
    'Module 4',
    'Module 5',
    'Module 6',
  ];

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';

    if (email.isNotEmpty) {
      await loadNotes();
    }
  }

  Future<void> loadNotes() async {
    try {
      final data = await ApiService.getNotes(email);
      setState(() {
        notes = data;
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  Future<void> pickFile() async {
    final file = await FileService.pickAnyStudyFile();
    if (file != null) {
      setState(() {
        selectedFile = file;
      });
    }
  }

  Future<void> uploadNote() async {
    if (subjectController.text.trim().isEmpty || selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subject and pick a file')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.uploadNote(
        file: selectedFile!,
        email: email,
        subject: subjectController.text.trim(),
        module: selectedModule,
      );

      subjectController.clear();

      setState(() {
        selectedFile = null;
        selectedModule = 'Module 1';
      });

      await loadNotes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await ApiService.deleteNote(id, email);
      await loadNotes();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Map<String, List<dynamic>> groupNotesBySubject(List<dynamic> notes) {
    final Map<String, List<dynamic>> grouped = {};

    for (final note in notes) {
      final subject = note['subject'] ?? 'Unknown Subject';
      grouped.putIfAbsent(subject, () => []);
      grouped[subject]!.add(note);
    }

    return grouped;
  }

  Widget buildNoteTile(dynamic note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAE9FF),
          child: Icon(Icons.description_outlined, color: Colors.deepPurple),
        ),
        title: Text(note['file_name'] ?? 'Untitled note'),
        subtitle: Text(
          '${note['module'] ?? '-'} • ${note['uploaded_at'] ?? ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => deleteNote(note['id']),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotes = groupNotesBySubject(notes);

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
                    'Upload Notes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'Example: Computer Networks',
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedModule,
                    items: modules.map((module) {
                      return DropdownMenuItem(
                        value: module,
                        child: Text(module),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedModule = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Module',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      selectedFile == null
                          ? 'Pick PDF / Image Note'
                          : FileService.getFileName(selectedFile!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : uploadNote,
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(isLoading ? 'Uploading...' : 'Upload Note'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Notes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 14),

            if (notes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'No notes uploaded yet. Add a subject, choose a module and upload your notes.',
                ),
              )
            else
              ...groupedNotes.entries.map((entry) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...entry.value.map(buildNoteTile),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
