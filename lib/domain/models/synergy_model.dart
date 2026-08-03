class Synergy {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String status;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SynergyAuthor? author;
  final List<SynergyComment>? comments;

  Synergy({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.status,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.comments,
  });

  factory Synergy.fromJson(Map<String, dynamic> json) {
    return Synergy(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      status: json['status'] ?? 'active',
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      author: json['author'] != null ? SynergyAuthor.fromJson(json['author']) : null,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((i) => SynergyComment.fromJson(i)).toList()
          : null,
    );
  }
}

class SynergyAuthor {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;

  String get fullName => '$firstName $lastName';

  SynergyAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
  });

  factory SynergyAuthor.fromJson(Map<String, dynamic> json) {
    return SynergyAuthor(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImageUrl: json['profile_image_url'],
    );
  }
}

class SynergyComment {
  final String id;
  final String synergyId;
  final String userId;
  final String content;
  final String? parentCommentId;
  final bool isExpertFeedback;
  final DateTime createdAt;
  final SynergyAuthor? user;

  SynergyComment({
    required this.id,
    required this.synergyId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.isExpertFeedback,
    required this.createdAt,
    this.user,
  });

  factory SynergyComment.fromJson(Map<String, dynamic> json) {
    return SynergyComment(
      id: json['id'] ?? '',
      synergyId: json['synergy_id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'] ?? '',
      parentCommentId: json['parent_comment_id'],
      isExpertFeedback: json['is_expert_feedback'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? SynergyAuthor.fromJson(json['user']) : null,
    );
  }
}
