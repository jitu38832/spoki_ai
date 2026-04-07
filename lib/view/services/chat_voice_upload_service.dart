import 'dart:io';

import 'package:dio/dio.dart';
import 'package:spokiai/viewmodel/repository/api_service.dart';

/// Multipart upload of a local audio file; backend returns a public/signed URL + transcription.
class ChatVoiceUploadResult {
  ChatVoiceUploadResult({
    required this.audioUrl,
    required this.transcription,
  });

  final String audioUrl;
  final String transcription;
}

class ChatVoiceUploadService {
  /// Relative to [BASEURL] (`/api/v1/`).
  static const String uploadPath = 'chat/voice-upload';

  static Future<ChatVoiceUploadResult?> upload({
    required String token,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final basename = filePath.replaceAll(r'\', '/').split('/').last;
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath, filename: basename),
    });

    final response = await ApiService(token: token).sendRequest.post(
      uploadPath,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    final data = response.data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final url = _pickString(map, const [
      'url',
      'audioUrl',
      'fileUrl',
      'secureUrl',
    ]);
    if (url == null || url.isEmpty) return null;

    final transcription = _pickString(map, const [
          'transcription',
          'text',
          'message',
          'transcript',
        ]) ??
        '';

    return ChatVoiceUploadResult(audioUrl: url, transcription: transcription.trim());
  }

  static String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v is String ? v : v.toString();
      final t = s.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }
}
