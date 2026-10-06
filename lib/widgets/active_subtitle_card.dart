import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subtitle_item.dart';
import '../utils/app_theme.dart';

class ActiveSubtitleCard extends StatelessWidget {
  final SubtitleItem? subtitle;
  final VoidCallback? onPinToggle;
  final Function(String word)? onWordTap;

  const ActiveSubtitleCard({
    super.key,
    required this.subtitle,
    this.onPinToggle,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (subtitle == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardCreamBorder, width: 1.2),
        ),
        child: Center(
          child: Text(
            'Select a subtitle or play video to begin shadowing',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final words = subtitle!.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardCreamBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of segmented words with Miraa style pill highlights
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: List.generate(words.length, (index) {
              final word = words[index];
              final Color chipColor = AppTheme.pastelWordColors[index % AppTheme.pastelWordColors.length];

              return InkWell(
                onTap: () => onWordTap?.call(word),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    word,
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // English / target translation beneath
          Text(
            subtitle!.translation,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
