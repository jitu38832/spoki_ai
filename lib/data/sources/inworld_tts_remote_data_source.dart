import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:spokiai/core/config/inworld_tts_config.dart';
import 'package:spokiai/data/models/inworld_tts_models.dart';

abstract class InworldTtsRemoteDataSource {
  Future<Uint8List> synthesize(InworldTtsRequest request);
}

class InworldTtsRemoteDataSourceImpl implements InworldTtsRemoteDataSource {
  InworldTtsRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: InworldTtsConfig.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: <String, dynamic>{
                  'Authorization': InworldTtsConfig.authorizationHeaderValue,
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;

  @override
  Future<Uint8List> synthesize(InworldTtsRequest request) async {
    if (!InworldTtsConfig.hasCredentials) {
      throw StateError('INWORLD_API_KEY is not configured');
    }

    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        InworldTtsConfig.ttsPath,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      throw Exception('Inworld TTS failed: $msg');
    }

    final data = response.data;
    if (data == null) {
      throw Exception('Empty TTS response');
    }
    final parsed = InworldTtsResponse.fromJson(data);
    return Uint8List.fromList(base64Decode(parsed.audioContentBase64));
  }
}
