import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FileService {
  static Future<File?> pickAnyStudyFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }

      return null;
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  static String getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }
}
