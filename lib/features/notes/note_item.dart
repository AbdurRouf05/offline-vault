class NoteItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'general',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toPlainMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'is_pinned': isPinned ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory NoteItem.fromPlainMap(Map<String, dynamic> map) => NoteItem(
    id: map['id'] as String,
    title: map['title'] as String,
    content: map['content'] as String? ?? '',
    category: map['category'] as String? ?? 'general',
    isPinned: (map['is_pinned'] as int? ?? 0) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}
