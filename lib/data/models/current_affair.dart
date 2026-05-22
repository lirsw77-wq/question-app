class CurrentAffair {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String source;
  final int publishDate;
  final String? aiSummary;
  final bool isRead;
  final bool isFavorite;
  final int createdAt;

  CurrentAffair({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.source,
    required this.publishDate,
    this.aiSummary,
    this.isRead = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'category': category,
      'source': source,
      'publish_date': publishDate,
      'ai_summary': aiSummary,
      'is_read': isRead ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory CurrentAffair.fromMap(Map<String, dynamic> map) {
    return CurrentAffair(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      source: map['source'] as String,
      publishDate: map['publish_date'] as int,
      aiSummary: map['ai_summary'] as String?,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  CurrentAffair copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? source,
    int? publishDate,
    String? aiSummary,
    bool? isRead,
    bool? isFavorite,
    int? createdAt,
  }) {
    return CurrentAffair(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      source: source ?? this.source,
      publishDate: publishDate ?? this.publishDate,
      aiSummary: aiSummary ?? this.aiSummary,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
