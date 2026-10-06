import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';

class BottomPlayerControls extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final bool isRepeatOn;
  final bool isPinned;
  final double playbackSpeed;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleRepeat;
  final VoidCallback onTogglePin;
  final VoidCallback onExplain;
  final VoidCallback onChangeSpeed;
  final VoidCallback onPracticeVoice;

  const BottomPlayerControls({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.isRepeatOn,
    required this.isPinned,
    required this.playbackSpeed,
    required this.onSeek,
    required this.onPlayPause,
    required this.onToggleRepeat,
    required this.onTogglePin,
    required this.onExplain,
    required this.onChangeSpeed,
    required this.onPracticeVoice,
  });

  @override
  Widget build(BuildContext context) {
    final double maxSec = totalDuration.inMilliseconds > 0
        ? totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final double curSec = currentPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, maxSec);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardCream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.cardCreamBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Current Time - Slider - Total Duration
          Row(
            children: [
              Text(
                TimeFormatter.formatDuration(currentPosition),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: curSec,
                    min: 0.0,
                    max: maxSec,
                    activeColor: AppTheme.primaryGreen,
                    inactiveColor: const Color(0xFFD6D9D1),
                    onChanged: (val) {
                      onSeek(Duration(milliseconds: val.round()));
                    },
                  ),
                ),
              ),
              Text(
                TimeFormatter.formatDuration(totalDuration),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Action Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pin
              _buildControlButton(
                icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: 'Pin',
                isActive: isPinned,
                onTap: onTogglePin,
              ),
              // Explain
              _buildControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Explain',
                isActive: false,
                onTap: onExplain,
              ),
              // Repeat
              _buildControlButton(
                icon: Icons.repeat_one_rounded,
                label: 'Repeat',
                isActive: isRepeatOn,
                onTap: onToggleRepeat,
              ),
              // Speed
              _buildControlButton(
                icon: Icons.speed_rounded,
                label: playbackSpeed == 1.0 ? 'Speed' : '${playbackSpeed}x',
                isActive: playbackSpeed != 1.0,
                onTap: onChangeSpeed,
              ),
              // Play / Pause
              _buildControlButton(
                icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: isPlaying ? 'Pause' : 'Play',
                isActive: isPlaying,
                onTap: onPlayPause,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textDark,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
