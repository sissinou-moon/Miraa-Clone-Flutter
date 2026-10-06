import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/subtitle_item.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../components/orbs/thinking_orb.dart';

class ExplanationSheet extends StatefulWidget {
  final SubtitleItem subtitle;
  final String? focusedWord;

  const ExplanationSheet({
    super.key,
    required this.subtitle,
    this.focusedWord,
  });

  @override
  State<ExplanationSheet> createState() => _ExplanationSheetState();
}

class _ExplanationSheetState extends State<ExplanationSheet> {
  bool _isLoading = true;
  String _explanation = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingText = false;
  String? _playingWord;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
    if (widget.focusedWord != null) {
      _playTts(widget.focusedWord!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _isLoading = true;
      _explanation = '';
    });
    try {
      final stream = ApiService().explainSentence(widget.subtitle.text);
      await for (final chunk in stream) {
        setState(() {
          if (_isLoading) _isLoading = false;
          _explanation += chunk;
        });
      }
    } catch (e) {
      setState(() {
        _explanation = 'Failed to load explanation: $e';
        _isLoading = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playTts(String text, {bool isSentence = false}) async {
    try {
      if (isSentence) {
        setState(() => _isPlayingText = true);
      } else {
        setState(() => _playingWord = text);
      }
      final path = await ApiService().getTtsAudioPath(text);
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        if (isSentence) {
          setState(() => _isPlayingText = false);
        } else {
          setState(() => _playingWord = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.subtitle.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'AI Language Explanation',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isPlayingText ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                  color: AppTheme.primaryGreen,
                ),
                onPressed: () {
                  if (_isPlayingText) {
                    _audioPlayer.stop();
                    setState(() => _isPlayingText = false);
                  } else {
                    _playTts(widget.subtitle.text, isSentence: true);
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          // Current Sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardCreamBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subtitle.text,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle.translation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Vocabulary Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          // Word tokens list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words.map((w) {
              final isFocused = widget.focusedWord != null &&
                  w.toLowerCase().contains(widget.focusedWord!.toLowerCase());
              final isPlaying = _playingWord == w;
              return GestureDetector(
                onTap: () => _playTts(w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFocused || isPlaying
                        ? AppTheme.brightGreen.withValues(alpha: 0.4)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFocused || isPlaying ? AppTheme.primaryGreen : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying) ...[
                        const Icon(Icons.volume_up, size: 14, color: AppTheme.primaryGreenDark),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        w,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isFocused || isPlaying ? FontWeight.w700 : FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const Center(child: ThinkingOrb(size: 40, dark: true))
          else
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: _explanation,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                    strong: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    em: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    h1: GoogleFonts.outfit(
                      fontSize: 20,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: GoogleFonts.outfit(
                      fontSize: 18,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
