class CredentialItem {
  final String id;
  final String title;
  final String username;
  final String password;
  final String url;
  final String category;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CredentialItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url = '',
    this.category = 'general',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  CredentialItem copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? url,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CredentialItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toPlainMap() => {
    'id': id,
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'category': category,
    'notes': notes,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory CredentialItem.fromPlainMap(
    Map<String, dynamic> map,
  ) => CredentialItem(
    id: map['id'] as String,
    title: map['title'] as String,
    username: map['username'] as String? ?? '',
    password: map['password'] as String? ?? '',
    url: map['url'] as String? ?? '',
    category: map['category'] as String? ?? 'general',
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}
