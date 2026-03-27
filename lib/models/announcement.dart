class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Whether the announcement is currently visible
  final int priority; // Higher priority announcements appear first (0 = normal, 1 = high, 2 = urgent)

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.priority = 0,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt']
              : (json['createdAt'] is String
                  ? DateTime.parse(json['createdAt'])
                  : (json['createdAt'] as dynamic).toDate()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt']
              : (json['updatedAt'] is String
                  ? DateTime.parse(json['updatedAt'])
                  : (json['updatedAt'] as dynamic).toDate()))
          : null,
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'priority': priority,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? priority,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
    );
  }
}

