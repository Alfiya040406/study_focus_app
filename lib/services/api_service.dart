import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://127.0.0.1:5000';
  }

  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['error'] ?? 'Signup failed');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['error'] ?? 'Login failed');
  }

  static Future<List<dynamic>> getNotes(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/notes?email=$email'));

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return List<dynamic>.from(data['notes'] ?? []);
    }

    throw Exception(data['error'] ?? 'Failed to load notes');
  }

  static Future<Map<String, dynamic>> uploadNote({
    required File file,
    required String email,
    required String subject,
    required String module,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-note'),
    );

    request.fields['email'] = email;
    request.fields['subject'] = subject;
    request.fields['module'] = module;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['error'] ?? 'Failed to upload note');
  }

  static Future<void> deleteNote(int noteId, String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-note/$noteId?email=$email'),
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to delete note');
    }
  }

  static Future<String> askAI({
    required String email,
    required String question,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ask-ai'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'question': question,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['answer'] ?? '';
    }

    throw Exception(data['error'] ?? 'AI request failed');
  }

  static Future<String> explainNoteById({
    required int noteId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain-note-by-id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'note_id': noteId, 'email': email}),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['answer'] ?? '';
    }

    throw Exception(data['error'] ?? 'Failed to explain note');
  }

  static Future<String> askNoteById({
    required int noteId,
    required String email,
    required String question,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ask-note-by-id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'note_id': noteId,
        'email': email,
        'question': question,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['answer'] ?? '';
    }

    throw Exception(data['error'] ?? 'Failed to ask question on note');
  }

  static Future<void> saveStudySession({
    required String email,
    required String methodTitle,
    required String phase,
    required int minutes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/study-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'method_title': methodTitle,
        'phase': phase,
        'minutes': minutes,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to save study session');
    }
  }

  static Future<Map<String, dynamic>> getStudySummary({
    required String email,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/study-summary?email=$email'),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['error'] ?? 'Failed to load study summary');
  }

  static Future<List<dynamic>> getAiHistory(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai-history?email=$email'),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return List<dynamic>.from(data['history'] ?? []);
    }

    throw Exception(data['error'] ?? 'Failed to load AI history');
  }

  static Future<void> clearAiHistory(String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/ai-history?email=$email'),
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to clear AI history');
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'data': decoded};
  }
}
