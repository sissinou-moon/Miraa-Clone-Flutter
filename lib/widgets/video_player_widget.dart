import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final String? localThumbnailPath;
  final String? remoteThumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    this.localThumbnailPath,
    this.remoteThumbnailUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _showOverlay = false;

  void _handleTap() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
      _showOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showOverlay = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: widget.controller.value.isInitialized
            ? GestureDetector(
                onTap: _handleTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: widget.controller.value.size.width,
                          height: widget.controller.value.size.height,
                          child: VideoPlayer(widget.controller),
                        ),
                      ),
                    ),
                    // Play / Pause animated icon overlay
                    AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _buildThumbnailPlaceholder(),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    Widget? imageWidget;
    if (widget.localThumbnailPath != null &&
        widget.localThumbnailPath!.isNotEmpty &&
        File(widget.localThumbnailPath!).existsSync()) {
      imageWidget = Image.file(
        File(widget.localThumbnailPath!),
        fit: BoxFit.cover,
      );
    } else if (widget.remoteThumbnailUrl != null &&
        widget.remoteThumbnailUrl!.isNotEmpty) {
      imageWidget = Image.network(
        widget.remoteThumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (imageWidget != null) Positioned.fill(child: imageWidget),
        Container(
          color: Colors.black.withValues(alpha: 0.35),
        ),
        const CircularProgressIndicator(
          color: AppTheme.brightGreen,
          strokeWidth: 3,
        ),
      ],
    );
  }
}
