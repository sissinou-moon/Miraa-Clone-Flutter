import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../models/subtitle_item.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class AddVideoDialog extends StatefulWidget {
  final ApiService apiService;
  final DownloadService downloadService;
  final StorageService storageService;

  const AddVideoDialog({
    super.key,
    required this.apiService,
    required this.downloadService,
    required this.storageService,
  });

  @override
  State<AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<AddVideoDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  bool _showSettings = false;

  // The sample Russian conversation data provided in the user prompt
  static const List<Map<String, dynamic>> _sampleSubtitlesJson = [
    {"start": 0.32, "end": 7.68, "text": "Привет, я Аня, и я студентка. Каждый", "translation": "Hello, I'm Anya and I'm a student. Every"},
    {"start": 4.24, "end": 11.08, "text": "день после лекций я прихожу в это кафе.", "translation": "the day after lectures I come to this cafe."},
    {"start": 7.68, "end": 16.04, "text": "Здесь тихо, и у меня есть мой любимый", "translation": "It's quiet here and I have my favorite"},
    {"start": 11.08, "end": 19.2, "text": "стол у окна. Я пью кофе, читаю книги и", "translation": "table by the window. I drink coffee, read books and"},
    {"start": 16.04, "end": 23.24, "text": "делаю домашнее задание. Я люблю это", "translation": "I'm doing my homework. I love it"},
    {"start": 19.2, "end": 27.24, "text": "место. Я думаю, это мой стол.", "translation": "place. I think this is my desk."},
    {"start": 23.24, "end": 32.24, "text": "Глупо, я знаю, но мне здесь спокойно.", "translation": "It's stupid, I know, but I'm at peace here."},
    {"start": 27.24, "end": 35.68, "text": "Но сегодня что-то новое. На моём столе", "translation": "But today there is something new. On my desk"},
    {"start": 32.24, "end": 41.08, "text": "лежит маленькая записка.", "translation": "there is a small note."},
    {"start": 35.68, "end": 44.0, "text": "Это очень странно. Кто оставил её здесь?", "translation": "This is very strange. Who left it here?"},
    {"start": 41.08, "end": 47.6, "text": "Может быть, это ошибка.", "translation": "Maybe this is a mistake."},
    {"start": 44.0, "end": 49.68, "text": "Я смотрю вокруг, но не вижу ничего", "translation": "I look around but I don't see anything"},
    {"start": 47.6, "end": 52.76, "text": "необычного.", "translation": "unusual."},
    {"start": 49.68, "end": 57.6, "text": "Я открываю записку.", "translation": "I open the note."},
    {"start": 52.76, "end": 61.24, "text": "Хм. Моё сердце бьётся немного быстрее.", "translation": "Hm. My heart beats a little faster."},
    {"start": 57.6, "end": 66.36, "text": "На записке только один вопрос: какая", "translation": "There is only one question on the note: which"},
    {"start": 61.24, "end": 69.68, "text": "ваша любимая книга? И всё. Нимени, ни", "translation": "your favorite book? That's all. No, no"},
    {"start": 66.36, "end": 73.96, "text": "телефона, только вопрос.", "translation": "phone, just a question."},
    {"start": 69.68, "end": 78.16, "text": "Хм. Моя любимая книга. Это трудный", "translation": "Hm. My favorite book. It's difficult"},
    {"start": 73.96, "end": 79.84, "text": "вопрос. У меня много любимых книг. Я", "translation": "question. I have many favorite books. I"},
    {"start": 78.16, "end": 82.08, "text": "думаю,", "translation": "Think,"},
    {"start": 79.84, "end": 87.36, "text": "кто этот человек?", "translation": "who is this person?"},
    {"start": 82.08, "end": 89.4, "text": "Он или она видел меня здесь с книгами?", "translation": "Did he or she see me here with books?"},
    {"start": 87.36, "end": 92.68, "text": "Это интересно,", "translation": "This is interesting,"},
    {"start": 89.4, "end": 96.12, "text": "но и немного страшно.", "translation": "but also a little scary."},
    {"start": 92.68, "end": 99.52, "text": "Я не знаю, что делать: ответить или", "translation": "I don't know what to do: answer or"},
    {"start": 96.12, "end": 105.04, "text": "просто выбросить записку. Это просто", "translation": "just throw the note away. It's simple"},
    {"start": 99.52, "end": 107.6, "text": "шутка. Я решаю ответить. Х почему нет?", "translation": "joke. I decide to answer. X why not?"},
    {"start": 105.04, "end": 111.96, "text": "Это романтично.", "translation": "It's romantic."},
    {"start": 107.6, "end": 115.76, "text": "Я беру ручку и бумагу. Я думаю минуту, а", "translation": "I take a pen and paper. I think for a minute, eh"},
    {"start": 111.96, "end": 119.04, "text": "потом пишу свой ответ. Я оставлю свой", "translation": "then I write my answer. I'll leave mine"},
    {"start": 115.76, "end": 124.36, "text": "ответ на этом же столе. Может быть,", "translation": "the answer is on the same table. May be,"},
    {"start": 119.04, "end": 128.36, "text": "завтра здесь будет новая записка.", "translation": "There will be a new note here tomorrow."},
    {"start": 124.36, "end": 132.24, "text": "А может быть, нет. Посмотрим.", "translation": "Or maybe not. Let's see."},
    {"start": 128.36, "end": 134.9, "text": "[музыка]", "translation": "[music]"},
    {"start": 132.24, "end": 138.59, "text": "Угу.", "translation": "Yes."},
    {"start": 134.9, "end": 138.59, "text": "[музыка]", "translation": "[music]"}
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedServerUrl();
  }

  Future<void> _loadSavedServerUrl() async {
    final saved = await widget.storageService.getServerUrl();
    _serverController.text = saved ?? ApiService.defaultBaseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _handleProcess() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter or paste a YouTube video URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.05;
      _statusMessage = 'Requesting subtitles from translation endpoint...';
    });

    try {
      final customBase = _serverController.text.trim();
      await widget.storageService.saveServerUrl(customBase);

      // 1. Call endpoint: POST /translate with {"url": url}
      List<SubtitleItem> subtitles;
      try {
        subtitles = await widget.apiService.fetchSubtitles(
          url,
          customBaseUrl: customBase,
        );
      } catch (apiErr) {
        debugPrint('Endpoint request failed: $apiErr');
        // If user is pasting a demo URL or backend is currently off, check if fallback to sample subtitles
        if (url.contains('watch') || url.contains('youtu.be')) {
          rethrow;
        } else {
          subtitles = _sampleSubtitlesJson.map((e) => SubtitleItem.fromJson(e)).toList();
        }
      }

      setState(() {
        _statusMessage = 'Fetched ${subtitles.length} bilingual subtitles. Downloading media files...';
        _downloadProgress = 0.25;
      });

      // 2. Download video and subtitles locally for 100% offline access
      final MediaItem mediaItem = await widget.downloadService.processAndSaveVideo(
        youtubeUrl: url,
        subtitles: subtitles,
        onProgress: (prog, msg) {
          if (mounted) {
            setState(() {
              _downloadProgress = prog;
              _statusMessage = msg;
            });
          }
        },
      );

      // 3. Save to library database
      await widget.storageService.saveMediaItem(mediaItem);

      if (mounted) {
        Navigator.of(context).pop(mediaItem);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error processing video: $e';
        });
      }
    }
  }

  Future<void> _loadSampleData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Creating offline sample lesson...';
      _downloadProgress = 0.5;
    });

    try {
      final sampleSubs = _sampleSubtitlesJson.map((e) => SubtitleItem.fromJson(e)).toList();
      final MediaItem sampleItem = await widget.downloadService.createSampleOfflineItem(sampleSubs);
      await widget.storageService.saveMediaItem(sampleItem);

      if (mounted) {
        Navigator.of(context).pop(sampleItem);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load sample: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.softGreen.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.video_library_rounded,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add YouTube Video',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Paste a YouTube URL to extract bilingual subtitles and save the video for offline shadowing practice.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardCream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardCreamBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        enabled: !_isLoading,
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: 'https://www.youtube.com/watch?v=...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryGreen),
                      tooltip: 'Paste from clipboard',
                      onPressed: _isLoading ? null : _pasteFromClipboard,
                    ),
                  ],
                ),
              ),

              // Server config expandable
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _showSettings = !_showSettings),
                child: Row(
                  children: [
                    Icon(
                      _showSettings ? Icons.keyboard_arrow_up : Icons.tune_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showSettings ? 'Hide backend endpoint settings' : 'Backend endpoint settings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (_showSettings) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _serverController,
                  enabled: !_isLoading,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Endpoint Base URL',
                    hintText: 'http://localhost:8000',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              // Error banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Progress bar
              if (_isLoading) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: AppTheme.primaryGreen,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Test sample button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loadSampleData,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppTheme.cardCreamBorder),
                      ),
                      child: Text(
                        'Demo Sample',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Next / Process button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoading ? 'Processing...' : 'Next',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isLoading) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
