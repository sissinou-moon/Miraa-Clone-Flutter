import 'dart:convert';
import 'subtitle_item.dart';

class MediaItem {
  final String id;
  final String title;
  final String originalUrl;
  final String localVideoPath;
  final String localSubtitlePath;
  final String? thumbnailUrl;
  final String? localThumbnailPath;
  final int durationSeconds;
  final DateTime createdAt;
  final List<SubtitleItem> subtitles;

  const MediaItem({
    required this.id,
    required this.title,
    required this.originalUrl,
    required this.localVideoPath,
    required this.localSubtitlePath,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.durationSeconds = 0,
    required this.createdAt,
    this.subtitles = const [],
  });

  Duration get duration => Duration(seconds: durationSeconds);

  MediaItem copyWith({
    String? id,
    String? title,
    String? originalUrl,
    String? localVideoPath,
    String? localSubtitlePath,
    String? thumbnailUrl,
    String? localThumbnailPath,
    int? durationSeconds,
    DateTime? createdAt,
    List<SubtitleItem>? subtitles,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      originalUrl: originalUrl ?? this.originalUrl,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      localSubtitlePath: localSubtitlePath ?? this.localSubtitlePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      subtitles: subtitles ?? this.subtitles,
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    List<SubtitleItem> subs = [];
    if (json['subtitles'] is List) {
      subs = (json['subtitles'] as List)
          .map((e) => SubtitleItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return MediaItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled Video',
      originalUrl: json['originalUrl'] as String? ?? '',
      localVideoPath: json['localVideoPath'] as String? ?? '',
      localSubtitlePath: json['localSubtitlePath'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      localThumbnailPath: json['localThumbnailPath'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      subtitles: subs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalUrl': originalUrl,
      'localVideoPath': localVideoPath,
      'localSubtitlePath': localSubtitlePath,
      'thumbnailUrl': thumbnailUrl,
      'localThumbnailPath': localThumbnailPath,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
