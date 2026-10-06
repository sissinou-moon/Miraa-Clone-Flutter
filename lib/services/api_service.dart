import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subtitle_item.dart';

import 'package:crypto/crypto.dart';

class ApiService {
  // Default base URL. On Android Emulator, localhost is 10.0.2.2.
  static String defaultBaseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';

  /// In-memory cached custom base URL, set from Backend Server Settings
  static String? customBaseUrl;

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Resolves the active base URL:
  /// Uses [customBaseUrl] parameter if provided, otherwise checks saved URL from
  /// settings, falling back to [defaultBaseUrl].
  static Future<String> resolveBaseUrl({String? customBaseUrl}) async {
    if (customBaseUrl?.trim().isNotEmpty == true) {
      return customBaseUrl!.trim();
    }
    if (ApiService.customBaseUrl?.trim().isNotEmpty == true) {
      return ApiService.customBaseUrl!.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('miraa_custom_backend_url');
      if (saved?.trim().isNotEmpty == true) {
        ApiService.customBaseUrl = saved!.trim();
        return saved.trim();
      }
    } catch (_) {}
    return defaultBaseUrl;
  }

  String generateToken(String secretKey) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final hmac = Hmac(sha256, utf8.encode(secretKey));

    return hmac.convert(utf8.encode(timestamp)).toString();
  }

  /// Fetches bilingual subtitles for a YouTube URL from the FastAPI translation backend.
  Future<List<SubtitleItem>> fetchSubtitles(
    String youtubeUrl, {
    String? customBaseUrl,
  }) async {
    final String baseUrl = await resolveBaseUrl(customBaseUrl: customBaseUrl);
    final token = generateToken("YassineSissinou");

    final Uri uri = Uri.parse('$baseUrl/translate');

    debugPrint('Requesting subtitles from: $uri for $youtubeUrl');

    print("TOKEN : $token");

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'sign': token},
            body: jsonEncode({'url': youtubeUrl}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('subtitles')) {
          final List list = decoded['subtitles'] as List;
          return list
              .map(
                (item) => SubtitleItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        } else {
          throw Exception('Invalid response format: missing "subtitles" key');
        }
      } else {
        throw HttpException(
          'Backend returned error ${response.statusCode}: ${response.body}',
          uri: uri,
        );
      }
    } catch (e) {
      // If localhost failed on Android, attempt 10.0.2.2 fallback automatically
      if (defaultTargetPlatform == TargetPlatform.android &&
          baseUrl.contains('localhost')) {
        final fallbackUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
        debugPrint('Retrying with Android emulator fallback: $fallbackUrl');
        return fetchSubtitles(youtubeUrl, customBaseUrl: fallbackUrl);
      }
      rethrow;
    }
  }

  /// Checks if backend is reachable
  Future<bool> checkHealth({String? customBaseUrl}) async {
    final String baseUrl = await resolveBaseUrl(customBaseUrl: customBaseUrl);
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Calls the model endpoint for A1 level sentence explanation
  Stream<String> explainSentence(
    String sentence, {
    String? customBaseUrl,
  }) async* {
    final String baseUrl = await resolveBaseUrl(customBaseUrl: customBaseUrl);

    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/model'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({"text": sentence, "history": []});

      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Failed to load explanation: ${response.statusCode}');
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final payload = line.substring(6).trim();
          if (payload == '[DONE]') return;
          try {
            final data = jsonDecode(payload);
            if (data.containsKey('token')) {
              yield data['token'] as String;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          baseUrl.contains('localhost')) {
        final fallbackUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
        yield* explainSentence(sentence, customBaseUrl: fallbackUrl);
      } else {
        rethrow;
      }
    }
  }

  /// Chat with video model
  Stream<String> chatWithVideo(
    String prompt,
    List<Map<String, dynamic>> history, {
    String? customBaseUrl,
  }) async* {
    final String baseUrl = await resolveBaseUrl(customBaseUrl: customBaseUrl);

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/model/video-explanation'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({"text": prompt, "history": history});

      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Failed to chat: ${response.statusCode}');
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final payload = line.substring(6).trim();
          if (payload == '[DONE]') return;
          try {
            final data = jsonDecode(payload);
            if (data.containsKey('token')) {
              yield data['token'] as String;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          baseUrl.contains('localhost')) {
        final fallbackUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
        yield* chatWithVideo(prompt, history, customBaseUrl: fallbackUrl);
      } else {
        rethrow;
      }
    }
  }

  /// Get TTS audio path
  Future<String> getTtsAudioPath(String text, {String? customBaseUrl}) async {
    final String baseUrl = await resolveBaseUrl(customBaseUrl: customBaseUrl);

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/russian-tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"text": text, "speed": 1.0, "speaker": "xenia"}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav',
        );
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Failed to load TTS: ${response.statusCode}');
      }
    } catch (e) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          baseUrl.contains('localhost')) {
        final fallbackUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
        return getTtsAudioPath(text, customBaseUrl: fallbackUrl);
      }
      rethrow;
    }
  }
}
