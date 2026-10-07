import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';
import '../models/subtitle_item.dart';

class StorageService {
  static const String _itemsKey = 'miraa_saved_media_items_v1';
  static const String _serverUrlKey = 'miraa_custom_backend_url';

  /// Saves or updates a media item in the persistent library list
  Future<void> saveMediaItem(MediaItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedMediaItems();

    final existingIndex = items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.insert(0, item);
    }

    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(jsonList));

    if (item.videoExplanation != null &&
        item.videoExplanation!.isNotEmpty &&
        item.localSubtitlePath.isNotEmpty) {
      try {
        final expFile = File(
          item.localSubtitlePath.replaceAll('.json', '_explanation.txt'),
        );
        await expFile.writeAsString(item.videoExplanation!);
      } catch (e) {
        debugPrint('Error saving explanation file: $e');
      }
    }
  }

  /// Retrieves all saved media items from local storage
  Future<List<MediaItem>> getSavedMediaItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_itemsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final List<MediaItem> items = [];
        for (final item in decoded) {
          try {
            var mediaItem = MediaItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            // If subtitles were saved separately in file, load them if empty in memory
            if (mediaItem.subtitles.isEmpty &&
                mediaItem.localSubtitlePath.isNotEmpty) {
              final subFile = File(mediaItem.localSubtitlePath);
              if (await subFile.exists()) {
                final subRaw = await subFile.readAsString();
                final subList = jsonDecode(subRaw) as List;
                final subs = subList
                    .map(
                      (s) => SubtitleItem.fromJson(
                        Map<String, dynamic>.from(s as Map),
                      ),
                    )
                    .toList();
                mediaItem = mediaItem.copyWith(subtitles: subs);
              }
            }
            // If explanation was saved in file, load it if empty in item
            if ((mediaItem.videoExplanation == null ||
                    mediaItem.videoExplanation!.isEmpty) &&
                mediaItem.localSubtitlePath.isNotEmpty) {
              final expFile = File(
                mediaItem.localSubtitlePath.replaceAll('.json', '_explanation.txt'),
              );
              if (await expFile.exists()) {
                final expText = await expFile.readAsString();
                mediaItem = mediaItem.copyWith(videoExplanation: expText);
              }
            }
            items.add(mediaItem);
          } catch (e) {
            debugPrint('Error parsing saved item: $e');
          }
        }
        return items;
      }
    } catch (e) {
      debugPrint('Error retrieving saved items: $e');
    }
    return [];
  }

  /// Deletes a media item and removes its offline files
  Future<void> deleteMediaItem(String id) async {
    final items = await getSavedMediaItems();
    final toRemove = items.where((i) => i.id == id).toList();

    for (final item in toRemove) {
      // Remove video file
      if (item.localVideoPath.isNotEmpty) {
        final vFile = File(item.localVideoPath);
        if (await vFile.exists()) {
          try {
            await vFile.delete();
          } catch (_) {}
        }
      }
      // Remove subtitle file
      if (item.localSubtitlePath.isNotEmpty) {
        final sFile = File(item.localSubtitlePath);
        if (await sFile.exists()) {
          try {
            await sFile.delete();
          } catch (_) {}
        }
      }
      // Remove explanation file
      if (item.localSubtitlePath.isNotEmpty) {
        final expFile = File(
          item.localSubtitlePath.replaceAll('.json', '_explanation.txt'),
        );
        if (await expFile.exists()) {
          try {
            await expFile.delete();
          } catch (_) {}
        }
      }
      // Remove thumbnail file
      if (item.localThumbnailPath != null &&
          item.localThumbnailPath!.isNotEmpty) {
        final tFile = File(item.localThumbnailPath!);
        if (await tFile.exists()) {
          try {
            await tFile.delete();
          } catch (_) {}
        }
      }
    }

    final remaining = items.where((i) => i.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(remaining.map((i) => i.toJson()).toList()),
    );
  }

  /// Alias for deleteMediaItem
  Future<void> deleteItem(String id) => deleteMediaItem(id);

  /// Save backend base URL configuration
  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  /// Retrieve backend base URL configuration
  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }
}
