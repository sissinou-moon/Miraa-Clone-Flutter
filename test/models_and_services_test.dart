import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:miraa_shadowing/models/media_item.dart';
import 'package:miraa_shadowing/models/subtitle_item.dart';
import 'package:miraa_shadowing/services/api_service.dart';
import 'package:miraa_shadowing/utils/time_formatter.dart';

void main() {
  group('SubtitleItem & MediaItem Tests', () {
    test('Parses backend sample payload correctly', () {
      const rawJson = '''
      {
        "subtitles": [
          {
            "start": 0.32,
            "end": 7.68,
            "text": "Привет, я Аня, и я студентка. Каждый",
            "translation": "Hello, I'm Anya and I'm a student. Every"
          },
          {
            "start": 4.24,
            "end": 11.08,
            "text": "день после лекций я прихожу в это кафе.",
            "translation": "the day after lectures I come to this cafe."
          }
        ]
      }
      ''';

      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final list = (decoded['subtitles'] as List)
          .map((item) => SubtitleItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      expect(list.length, 2);
      expect(list[0].start, 0.32);
      expect(list[0].end, 7.68);
      expect(list[0].text, 'Привет, я Аня, и я студентка. Каждый');
      expect(list[0].translation, "Hello, I'm Anya and I'm a student. Every");
      expect(list[0].startDuration, const Duration(milliseconds: 320));
      expect(list[0].endDuration, const Duration(milliseconds: 7680));
    });

    test('MediaItem JSON serialization and deserialization', () {
      final sub = SubtitleItem(
        start: 1.0,
        end: 5.0,
        text: 'Тест',
        translation: 'Test',
      );

      final item = MediaItem(
        id: 'test_vid',
        title: 'Sample Video',
        originalUrl: 'https://youtube.com/watch?v=123',
        localVideoPath: '/path/to/vid.mp4',
        localSubtitlePath: '/path/to/sub.json',
        durationSeconds: 120,
        createdAt: DateTime(2026, 10, 3),
        subtitles: [sub],
      );

      final json = item.toJson();
      final recovered = MediaItem.fromJson(json);

      expect(recovered.id, 'test_vid');
      expect(recovered.title, 'Sample Video');
      expect(recovered.subtitles.length, 1);
      expect(recovered.subtitles.first.text, 'Тест');
    });

    test('TimeFormatter formats seconds and durations properly', () {
      expect(TimeFormatter.formatSeconds(0.32), '0:00');
      expect(TimeFormatter.formatSeconds(83.0), '1:23');
      expect(TimeFormatter.formatSeconds(495.0), '8:15');
      expect(TimeFormatter.formatSeconds(1157.0), '19:17');
    });

    test('ApiService baseUrl resolution logic', () async {
      ApiService.customBaseUrl = null;
      // When no customBaseUrl is provided or saved, defaults to defaultBaseUrl
      final defaultResolved = await ApiService.resolveBaseUrl();
      expect(defaultResolved, ApiService.defaultBaseUrl);

      // When customBaseUrl is provided as parameter
      final paramResolved = await ApiService.resolveBaseUrl(customBaseUrl: 'http://my-server.com:8000 ');
      expect(paramResolved, 'http://my-server.com:8000');

      // When global customBaseUrl is configured
      ApiService.customBaseUrl = 'http://global-server.com:9000';
      final globalResolved = await ApiService.resolveBaseUrl();
      expect(globalResolved, 'http://global-server.com:9000');

      // Reset
      ApiService.customBaseUrl = null;
    });
  });
}
