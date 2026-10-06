class SubtitleItem {
  final double start;
  final double end;
  final String text;
  final String translation;
  final bool isPinned;

  const SubtitleItem({
    required this.start,
    required this.end,
    required this.text,
    required this.translation,
    this.isPinned = false,
  });

  Duration get startDuration => Duration(milliseconds: (start * 1000).round());
  Duration get endDuration => Duration(milliseconds: (end * 1000).round());
  Duration get duration => Duration(milliseconds: ((end - start) * 1000).round());

  SubtitleItem copyWith({
    double? start,
    double? end,
    String? text,
    String? translation,
    bool? isPinned,
  }) {
    return SubtitleItem(
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory SubtitleItem.fromJson(Map<String, dynamic> json) {
    return SubtitleItem(
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      text: (json['text'] as String?)?.trim() ?? '',
      translation: (json['translation'] as String?)?.trim() ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'text': text,
      'translation': translation,
      'isPinned': isPinned,
    };
  }
}
