import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/subtitle_item.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../components/orbs/thinking_orb.dart';

class VideoExplanationSheet extends StatefulWidget {
  final List<SubtitleItem> subtitles;

  const VideoExplanationSheet({super.key, required this.subtitles});

  @override
  State<VideoExplanationSheet> createState() => _VideoExplanationSheetState();
}

class _VideoExplanationSheetState extends State<VideoExplanationSheet> {
  final List<Map<String, dynamic>> _history = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startInitialAnalysis();
  }

  Future<void> _startInitialAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final subtitlesText = widget.subtitles.map((s) => s.text).join(' ');
      final prompt = '''Analyze these Russian subtitles for an A1 learner.

1. Topic: briefly explain what the video is about in simple English.
2. Key points: give 2–3 simple points from the video.
3. Questions: create 2 simple questions about the video that the learner must answer to test their understanding.

Keep everything short, clear, and A1-level. Do not give the answers to the questions.
Subtitles: $subtitlesText''';

      setState(() {
        _history.add({"role": "user", "content": prompt});
        _history.add({"role": "assistant", "content": ""});
      });
      final assistantIdx = _history.length - 1;

      final stream = ApiService().chatWithVideo(prompt, []);
      await for (final chunk in stream) {
        setState(() {
          _history[assistantIdx]["content"] =
              _history[assistantIdx]["content"]! + chunk;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _history.add({"role": "user", "content": text});
      _history.add({"role": "assistant", "content": ""});
      _isLoading = true;
    });
    _scrollToBottom();

    final assistantIdx = _history.length - 1;

    try {
      // Exclude the currently empty assistant message from history payload
      final historyForApi = _history.sublist(0, _history.length - 2);
      final stream = ApiService().chatWithVideo(text, historyForApi);
      await for (final chunk in stream) {
        setState(() {
          _history[assistantIdx]["content"] =
              _history[assistantIdx]["content"]! + chunk;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          Text(
            'Video Explanation',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _history.length,
              itemBuilder: (ctx, i) {
                final msg = _history[i];
                final isUser = msg['role'] == 'user';
                final content = msg['content'] ?? '';

                // Skip the initial very long prompt from UI
                if (i == 0 && isUser) return const SizedBox.shrink();

                if (content.isEmpty &&
                    !isUser &&
                    _isLoading &&
                    i == _history.length - 1) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 5,
                        top: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardCream,
                        borderRadius: BorderRadius.circular(16)
                            .copyWith(bottomLeft: Radius.zero),
                      ),
                      child: SizedBox(
                        width: 110,
                        child: Row(
                          spacing: 5,
                          children: [
                            const ThinkingOrb(size: 35, dark: true),
                            Text(
                              'Thinking...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (content.isEmpty && !isUser) return const SizedBox.shrink();

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppTheme.primaryGreen
                          : AppTheme.cardCream,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser
                            ? Radius.zero
                            : const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                    ),
                    child: isUser
                        ? Text(
                            content,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          )
                        : MarkdownBody(
                            data: content,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.inter(
                                color: AppTheme.textDark,
                                fontSize: 15,
                              ),
                              strong: GoogleFonts.inter(
                                color: AppTheme.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              h1: GoogleFonts.outfit(
                                color: AppTheme.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: GoogleFonts.outfit(
                                color: AppTheme.textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              h3: GoogleFonts.outfit(
                                color: AppTheme.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              listBullet: GoogleFonts.inter(
                                color: AppTheme.textDark,
                                fontSize: 15,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ask about the video...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
