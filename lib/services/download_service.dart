import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_item.dart';
import '../models/subtitle_item.dart';

typedef DownloadProgressCallback = void Function(double progress, String status);

class DownloadService {
  /// Downloads video stream and thumbnail, saves subtitles to local files,
  /// and returns a MediaItem configured for 100% offline playback.
  Future<MediaItem> processAndSaveVideo({
    required String youtubeUrl,
    required List<SubtitleItem> subtitles,
    DownloadProgressCallback? onProgress,
  }) async {
    final yt = YoutubeExplode();
    try {
      onProgress?.call(0.05, 'Connecting to YouTube metadata...');
      debugPrint('Fetching YouTube metadata for $youtubeUrl');

      final video = await yt.videos.get(youtubeUrl);
      final String videoId = video.id.value;
      final String cleanTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      onProgress?.call(0.15, 'Preparing local storage directories...');
      final appDir = await getApplicationDocumentsDirectory();

      final videosDir = Directory('${appDir.path}/miraa_offline/videos');
      final subtitlesDir = Directory('${appDir.path}/miraa_offline/subtitles');
      final thumbnailsDir = Directory('${appDir.path}/miraa_offline/thumbnails');

      if (!await videosDir.exists()) await videosDir.create(recursive: true);
      if (!await subtitlesDir.exists()) await subtitlesDir.create(recursive: true);
      if (!await thumbnailsDir.exists()) await thumbnailsDir.create(recursive: true);

      // 1. Save Subtitles JSON locally
      onProgress?.call(0.25, 'Saving bilingual subtitles locally...');
      final String subtitlePath = '${subtitlesDir.path}/$videoId.json';
      final subtitleFile = File(subtitlePath);
      final jsonContent = jsonEncode(subtitles.map((s) => s.toJson()).toList());
      await subtitleFile.writeAsString(jsonContent, flush: true);

      // 2. Download Thumbnail locally for offline preview
      onProgress?.call(0.35, 'Caching thumbnail image...');
      final String thumbnailPath = '${thumbnailsDir.path}/$videoId.jpg';
      String? localThumbPath;
      try {
        final thumbUrl = video.thumbnails.highResUrl;
        final thumbResp = await http.get(Uri.parse(thumbUrl)).timeout(const Duration(seconds: 10));
        if (thumbResp.statusCode == 200) {
          final thumbFile = File(thumbnailPath);
          await thumbFile.writeAsBytes(thumbResp.bodyBytes);
          localThumbPath = thumbFile.path;
        }
      } catch (e) {
        debugPrint('Warning: Could not cache thumbnail locally: $e');
      }

      // 3. Download Video stream (muxed mp4 contains both video & audio)
      onProgress?.call(0.40, 'Locating video streams...');
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      // Prefer muxed streams so video and audio are combined in one file for video_player
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      final StreamInfo? chosenStream = muxedStreams.isNotEmpty ? muxedStreams.first : null;

      final String videoPath = '${videosDir.path}/$videoId.mp4';
      final videoFile = File(videoPath);

      if (chosenStream != null) {
        onProgress?.call(0.45, 'Downloading video for offline playback...');
        final stream = yt.videos.streamsClient.get(chosenStream);
        final fileStream = videoFile.openWrite();
        final int totalBytes = chosenStream.size.totalBytes;
        int receivedBytes = 0;

        await for (final chunk in stream) {
          receivedBytes += chunk.length;
          fileStream.add(chunk);

          if (totalBytes > 0) {
            // Scale progress from 0.45 to 0.95
            final double videoProgress = receivedBytes / totalBytes;
            final double overall = 0.45 + (videoProgress * 0.50);
            final int mbReceived = (receivedBytes / (1024 * 1024)).round();
            final int mbTotal = (totalBytes / (1024 * 1024)).round();
            onProgress?.call(
              overall,
              'Downloading video: $mbReceived MB / $mbTotal MB (${(videoProgress * 100).toInt()}%)',
            );
          }
        }

        await fileStream.flush();
        await fileStream.close();
      } else {
        // Fallback: if no muxed stream exists, get video-only stream
        final videoOnly = manifest.videoOnly.first;
        final stream = yt.videos.streamsClient.get(videoOnly);
        final fileStream = videoFile.openWrite();
        await stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();
      }

      onProgress?.call(1.0, 'Completed! Ready for offline shadowing.');

      return MediaItem(
        id: videoId,
        title: video.title.isNotEmpty ? video.title : cleanTitle,
        originalUrl: youtubeUrl,
        localVideoPath: videoFile.path,
        localSubtitlePath: subtitleFile.path,
        thumbnailUrl: video.thumbnails.highResUrl,
        localThumbnailPath: localThumbPath,
        durationSeconds: video.duration?.inSeconds ?? 0,
        createdAt: DateTime.now(),
        subtitles: subtitles,
      );
    } finally {
      yt.close();
    }
  }

  /// Helper to create a saved sample offline item (useful for previewing or testing without network)
  Future<MediaItem> createSampleOfflineItem(List<SubtitleItem> sampleSubtitles) async {
    final appDir = await getApplicationDocumentsDirectory();
    final subtitlesDir = Directory('${appDir.path}/miraa_offline/subtitles');
    if (!await subtitlesDir.exists()) await subtitlesDir.create(recursive: true);

    const sampleId = 'sample_russian_lesson';
    final subtitlePath = '${subtitlesDir.path}/$sampleId.json';
    final subtitleFile = File(subtitlePath);
    await subtitleFile.writeAsString(
      jsonEncode(sampleSubtitles.map((s) => s.toJson()).toList()),
      flush: true,
    );

    return MediaItem(
      id: sampleId,
      title: 'Привет, я Аня • Russian Story & Conversation',
      originalUrl: 'https://www.youtube.com/watch?v=sample_russian_lesson',
      localVideoPath: '', // Will stream or use bundled sample
      localSubtitlePath: subtitleFile.path,
      thumbnailUrl: null,
      localThumbnailPath: null,
      durationSeconds: 139,
      createdAt: DateTime.now(),
      subtitles: sampleSubtitles,
    );
  }
}
