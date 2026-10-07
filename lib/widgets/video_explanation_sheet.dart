import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/orbs/thinking_orb.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class VideoExplanationSheet extends StatefulWidget {
  final MediaItem mediaItem;
  final String? initialExplanation;
  final bool isGenerating;
  final ValueNotifier<String>? streamingNotifier;
  final VoidCallback? onRetry;

  const VideoExplanationSheet({
    super.key,
    required this.mediaItem,
    this.initialExplanation,
    this.isGenerating = false,
    this.streamingNotifier,
    this.onRetry,
  });

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
    _initExplanationState();
  }

  void _initExplanationState() {
    final explanation =
        widget.initialExplanation ?? widget.mediaItem.videoExplanation;

    if (explanation != null && explanation.isNotEmpty) {
      _history.add({"role": "assistant", "content": explanation});
      _isLoading = false;
    } else if (widget.isGenerating && widget.streamingNotifier != null) {
      _isLoading = true;
      _history.add({
        "role": "assistant",
        "content": widget.streamingNotifier!.value,
      });
      widget.streamingNotifier!.addListener(_onStreamUpdate);
    } else {
      _isLoading = widget.isGenerating;
      if (widget.streamingNotifier != null) {
        widget.streamingNotifier!.addListener(_onStreamUpdate);
      }
    }
  }

  void _onStreamUpdate() {
    if (!mounted || widget.streamingNotifier == null) return;
    final currentText = widget.streamingNotifier!.value;
    setState(() {
      if (_history.isEmpty) {
        _history.add({"role": "assistant", "content": currentText});
      } else {
        _history[0]["content"] = currentText;
      }
      _isLoading = widget.isGenerating;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    widget.streamingNotifier?.removeListener(_onStreamUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
      final historyForApi = _history.sublist(0, _history.length - 2);
      final stream = ApiService().chatWithVideo(
        text,
        historyForApi,
        language: widget.mediaItem.language,
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get answer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
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
          const SizedBox(height: 16),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Video Explanation',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Messages list
          Expanded(
            child: _history.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 40,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No explanation available yet.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: widget.onRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Generate Explanation',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _history.length,
                    itemBuilder: (ctx, i) {
                      final msg = _history[i];
                      final isUser = msg['role'] == 'user';
                      final content = msg['content'] ?? '';

                      if (content.isEmpty &&
                          !isUser &&
                          _isLoading &&
                          i == _history.length - 1) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardCream,
                              borderRadius: BorderRadius.circular(16)
                                  .copyWith(bottomLeft: Radius.zero),
                            ),
                            child: SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  const ThinkingOrb(size: 32, dark: true),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Analyzing...',
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

                      if (content.isEmpty && !isUser) {
                        return const SizedBox.shrink();
                      }

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
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
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: GoogleFonts.inter(
                                      color: AppTheme.textDark,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    strong: GoogleFonts.inter(
                                      color: AppTheme.textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h1: GoogleFonts.outfit(
                                      color: AppTheme.textDark,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: GoogleFonts.outfit(
                                      color: AppTheme.textDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: GoogleFonts.outfit(
                                      color: AppTheme.textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    tableBody: GoogleFonts.inter(
                                      color: AppTheme.textDark,
                                      fontSize: 13,
                                    ),
                                    tableHead: GoogleFonts.inter(
                                      color: AppTheme.textDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: GoogleFonts.inter(
                                      color: AppTheme.textDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),

          // Message input bar
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
