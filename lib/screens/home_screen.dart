import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/media_item.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'add_video_dialog.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ApiService apiService;
  final DownloadService downloadService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.downloadService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MediaItem> _savedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
    widget.storageService.getServerUrl().then((url) {
      if (url != null && url.trim().isNotEmpty) {
        ApiService.customBaseUrl = url.trim();
      }
    });
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    final items = await widget.storageService.getSavedMediaItems();
    if (mounted) {
      setState(() {
        _savedItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddVideoDialog() async {
    final result = await showDialog<MediaItem>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddVideoDialog(
        apiService: widget.apiService,
        downloadService: widget.downloadService,
        storageService: widget.storageService,
      ),
    );

    if (result != null && mounted) {
      await _loadSavedItems();
      _navigateToPlayer(result);
    }
  }

  void _navigateToPlayer(MediaItem item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) => PlayerScreen(
              mediaItem: item,
              storageService: widget.storageService,
            ),
          ),
        )
        .then((_) => _loadSavedItems());
  }

  Future<void> _deleteItem(MediaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Lesson?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove "${item.title}" and its offline video and subtitles.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.storageService.deleteItem(item.id);
      await _loadSavedItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCream,
      appBar: AppBar(
        title: Text(
          'Miraa Shadowing',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textDark),
            tooltip: 'Server Settings',
            onPressed: () => _openServerSettingsDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _savedItems.isEmpty
          ? _buildBlankInitialState()
          : _buildLibraryList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVideoDialog,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Video',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Blank screen with Add button as requested when user opens app
  Widget _buildBlankInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.softGreen.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: AppTheme.primaryGreen,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Transcribe & Shadowing',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Transcribe your YouTube videos into bilingual materials for shadowing practice. Videos and subtitles are saved locally for offline access.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAddVideoDialog,
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: Text(
                'Add Video URL',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _savedItems.length,
      itemBuilder: (context, index) {
        final item = _savedItems[index];

        Widget? thumbWidget;
        if (item.localThumbnailPath != null &&
            item.localThumbnailPath!.isNotEmpty &&
            File(item.localThumbnailPath!).existsSync()) {
          thumbWidget = Image.file(
            File(item.localThumbnailPath!),
            fit: BoxFit.cover,
            width: 100,
            height: 70,
          );
        } else if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty) {
          thumbWidget = Image.network(
            item.thumbnailUrl!,
            fit: BoxFit.cover,
            width: 100,
            height: 70,
            errorBuilder: (_, _, _) => const Icon(Icons.movie_rounded),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardCreamBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToPlayer(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 100,
                      height: 70,
                      color: AppTheme.cardCream,
                      child:
                          thumbWidget ??
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 32,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Offline Ready',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.subtitles.length} lines',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete option
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openServerSettingsDialog() async {
    final currentUrl =
        await widget.storageService.getServerUrl() ?? ApiService.defaultBaseUrl;
    final controller = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Backend Server Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the URL of the translation endpoint server (POST /translate).',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://localhost:8000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final input = controller.text.trim();
              await widget.storageService.saveServerUrl(input);
              ApiService.customBaseUrl = input.isNotEmpty ? input : null;
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
