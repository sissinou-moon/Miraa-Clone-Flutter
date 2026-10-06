import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';
import '../models/subtitle_item.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/active_subtitle_card.dart';
import '../widgets/bottom_player_controls.dart';
import '../widgets/explanation_sheet.dart';
import '../widgets/shadowing_practice_sheet.dart';
import '../widgets/subtitle_list_view.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_explanation_sheet.dart';

class PlayerScreen extends StatefulWidget {
  final MediaItem mediaItem;
  final StorageService storageService;

  const PlayerScreen({
    super.key,
    required this.mediaItem,
    required this.storageService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late MediaItem _item;
  late VideoPlayerController _controller;
  bool _isControllerInitialized = false;

  int _activeIndex = 0;
  bool _isRepeatOn = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _item = widget.mediaItem;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final localFile = File(_item.localVideoPath);
    if (_item.localVideoPath.isNotEmpty && await localFile.exists()) {
      _controller = VideoPlayerController.file(localFile);
    } else if (_item.originalUrl.isNotEmpty) {
      // Fallback: if local file is missing, try network stream
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(_item.originalUrl),
      );
    } else {
      // Offline sample fallback: create empty controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      );
    }

    try {
      await _controller.initialize();
      _controller.addListener(_videoListener);
      setState(() {
        _isControllerInitialized = true;
        _totalDuration = _controller.value.duration;
      });
      _controller.play();
    } catch (e) {
      debugPrint('Video player initialization error: $e');
      setState(() {
        _isControllerInitialized = true;
        _totalDuration = Duration(
          seconds: _item.durationSeconds > 0 ? _item.durationSeconds : 140,
        );
      });
    }
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isInitialized) return;

    final pos = _controller.value.position;
    final posSeconds = pos.inMilliseconds / 1000.0;

    // Check currently active subtitle
    int foundIndex = -1;

    for (int i = 0; i < _item.subtitles.length; i++) {
      final subtitle = _item.subtitles[i];

      if (posSeconds >= subtitle.start) {
        foundIndex = i;
      } else {
        break;
      }
    }

    if (foundIndex != -1 && foundIndex != _activeIndex) {
      setState(() {
        _activeIndex = foundIndex;
      });
    }

    // Handle repeat loop mode for the current sentence
    if (_isRepeatOn &&
        _activeIndex >= 0 &&
        _activeIndex < _item.subtitles.length) {
      final currentSub = _item.subtitles[_activeIndex];
      if (posSeconds >= currentSub.end) {
        _controller.seekTo(currentSub.startDuration);
        _controller.play();
        return;
      }
    }

    setState(() {
      _currentPosition = pos;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _seekToSubtitle(int index, SubtitleItem item) {
    setState(() {
      _activeIndex = index;
    });
    _controller.seekTo(item.startDuration);
    if (!_controller.value.isPlaying) {
      _controller.play();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeatOn = !_isRepeatOn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isRepeatOn
              ? 'Sentence Repeat ON (Shadowing Mode)'
              : 'Sentence Repeat OFF',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _togglePinSubtitle() {
    if (_activeIndex < 0 || _activeIndex >= _item.subtitles.length) return;
    final cur = _item.subtitles[_activeIndex];
    final updatedList = List<SubtitleItem>.from(_item.subtitles);
    updatedList[_activeIndex] = cur.copyWith(isPinned: !cur.isPinned);

    setState(() {
      _item = _item.copyWith(subtitles: updatedList);
    });

    widget.storageService.saveMediaItem(_item);
  }

  void _togglePinByIndex(int index, SubtitleItem item) {
    final updatedList = List<SubtitleItem>.from(_item.subtitles);
    updatedList[index] = item.copyWith(isPinned: !item.isPinned);

    setState(() {
      _item = _item.copyWith(subtitles: updatedList);
    });

    widget.storageService.saveMediaItem(_item);
  }

  void _showSpeedMenu() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Playback Speed',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              ...speeds.map(
                (s) => ListTile(
                  title: Text(
                    '${s}x',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: _playbackSpeed == s
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _playbackSpeed == s
                          ? AppTheme.primaryGreen
                          : AppTheme.textDark,
                    ),
                  ),
                  onTap: () {
                    _controller.setPlaybackSpeed(s);
                    setState(() => _playbackSpeed = s);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openExplanation({String? focusedWord}) {
    if (_activeIndex < 0 || _activeIndex >= _item.subtitles.length) return;
    final currentSub = _item.subtitles[_activeIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ExplanationSheet(subtitle: currentSub, focusedWord: focusedWord),
    );
  }

  void _openShadowingPractice() {
    if (_activeIndex < 0 || _activeIndex >= _item.subtitles.length) return;
    final currentSub = _item.subtitles[_activeIndex];

    // Pause main playback while shadowing
    _controller.pause();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShadowingPracticeSheet(
        subtitle: currentSub,
        onReplayNative: () {
          _controller.seekTo(currentSub.startDuration);
          _controller.play();
        },
      ),
    );
  }

  void _openVideoExplanation() {
    _controller.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoExplanationSheet(subtitles: _item.subtitles),
    );
  }

  SubtitleItem? get _currentSubtitle {
    if (_activeIndex >= 0 && _activeIndex < _item.subtitles.length) {
      return _item.subtitles[_activeIndex];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCream,
      body: SafeArea(
        child: !_isControllerInitialized
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      // Top Navigation Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                              color: AppTheme.textDark,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: Text(
                                _item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_rounded,
                                color: AppTheme.primaryGreen,
                              ),
                              tooltip: 'Explain Video',
                              onPressed: _openVideoExplanation,
                            ),
                          ],
                        ),
                      ),

                      // Video Player Area
                      VideoPlayerWidget(
                        controller: _controller,
                        localThumbnailPath: _item.localThumbnailPath,
                        remoteThumbnailUrl: _item.thumbnailUrl,
                      ),

                      // Active Subtitle Card (Highlighted current phrase with word pills)
                      ActiveSubtitleCard(
                        subtitle: _currentSubtitle,
                        onPinToggle: _togglePinSubtitle,
                        onWordTap: (word) =>
                            _openExplanation(focusedWord: word),
                      ),

                      // Subtitle List (All sentences with tap-to-seek and auto-scroll)
                      Expanded(
                        child: SubtitleListView(
                          subtitles: _item.subtitles,
                          activeIndex: _activeIndex,
                          onSubtitleTap: _seekToSubtitle,
                          onPinTap: _togglePinByIndex,
                        ),
                      ),
                    ],
                  ),

                  // Floating Bottom Player Controls Bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BottomPlayerControls(
                      currentPosition: _currentPosition,
                      totalDuration: _totalDuration,
                      isPlaying: _controller.value.isPlaying,
                      isRepeatOn: _isRepeatOn,
                      isPinned: _currentSubtitle?.isPinned ?? false,
                      playbackSpeed: _playbackSpeed,
                      onSeek: (newPos) => _controller.seekTo(newPos),
                      onPlayPause: _togglePlayPause,
                      onToggleRepeat: _toggleRepeat,
                      onTogglePin: _togglePinSubtitle,
                      onExplain: () => _openExplanation(),
                      onChangeSpeed: _showSpeedMenu,
                      onPracticeVoice: _openShadowingPractice,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
