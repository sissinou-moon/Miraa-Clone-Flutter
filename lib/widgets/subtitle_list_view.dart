import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subtitle_item.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';

class SubtitleListView extends StatefulWidget {
  final List<SubtitleItem> subtitles;
  final int activeIndex;
  final Function(int index, SubtitleItem item) onSubtitleTap;
  final Function(int index, SubtitleItem item)? onPinTap;

  const SubtitleListView({
    super.key,
    required this.subtitles,
    required this.activeIndex,
    required this.onSubtitleTap,
    this.onPinTap,
  });

  @override
  State<SubtitleListView> createState() => _SubtitleListViewState();
}

class _SubtitleListViewState extends State<SubtitleListView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  bool _userIsScrolling = false;

  @override
  void didUpdateWidget(covariant SubtitleListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex && !_userIsScrolling) {
      _scrollToActiveIndex(widget.activeIndex);
    }
  }

  void _scrollToActiveIndex(int index) {
    if (index < 0 || index >= widget.subtitles.length) return;
    final key = _itemKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.35, // Position item near upper-middle of viewport
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subtitles.isEmpty) {
      return Center(
        child: Text(
          'No subtitles available',
          style: GoogleFonts.inter(color: AppTheme.textMuted),
        ),
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Pause auto-scroll briefly when the user manually scrolls
        _userIsScrolling = true;
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) _userIsScrolling = false;
        });
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: 120,
        ),
        itemCount: widget.subtitles.length,
        itemBuilder: (context, index) {
          final item = widget.subtitles[index];
          final isActive = index == widget.activeIndex;
          final key = _itemKeys.putIfAbsent(index, () => GlobalKey());

          return Container(
            key: key,
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSubtitleTap(index, item),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.cardCream.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.12),
                      width: isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp tag on left
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Text(
                          TimeFormatter.formatSeconds(item.start),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppTheme.primaryGreen
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      // Text & Translation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.text,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppTheme.textDark
                                    : AppTheme.textDark.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.translation,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pin / Bookmark button
                      IconButton(
                        icon: Icon(
                          item.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 18,
                          color: item.isPinned
                              ? AppTheme.primaryGreen
                              : AppTheme.textLight.withValues(alpha: 0.7),
                        ),
                        onPressed: () => widget.onPinTap?.call(index, item),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
