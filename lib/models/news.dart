// News models for the news application

class NewsArticle {
  final String id;
  final String title;
  final String? excerpt;
  final String content;
  final String imageUrl;
  final String publishedAt;
  final int? viewCount;
  final bool isBreaking;
  final NewsCategory newsCategory;
  final NewsAuthor newsAuthor;

  NewsArticle({
    required this.id,
    required this.title,
    this.excerpt,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
    this.viewCount,
    required this.isBreaking,
    required this.newsCategory,
    required this.newsAuthor,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ?? '',
      publishedAt: json['published_at'] ?? '',
      viewCount: json['view_count'] as int?,
      isBreaking: json['is_breaking'] ?? false,
      newsCategory: NewsCategory.fromJson(json['news_category'] ?? {}),
      newsAuthor: NewsAuthor.fromJson(json['news_author'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'image_url': imageUrl,
      'published_at': publishedAt,
      'view_count': viewCount,
      'is_breaking': isBreaking,
      'news_category': newsCategory.toJson(),
      'news_author': newsAuthor.toJson(),
    };
  }
}

class NewsCategory {
  final String id;
  final String name;
  final String color;

  NewsCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}

class NewsAuthor {
  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;

  NewsAuthor({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
  });

  factory NewsAuthor.fromJson(Map<String, dynamic> json) {
    return NewsAuthor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }
}
