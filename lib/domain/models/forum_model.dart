class Forum {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String status;
  final String? createdByUserId;
  final bool createdByAdmin;
  final int postCount;
  final String authorAlias;
  final DateTime createdAt;
  final DateTime updatedAt;

  Forum({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.status,
    this.createdByUserId,
    required this.createdByAdmin,
    required this.postCount,
    required this.authorAlias,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      status: json['status'] ?? 'active',
      createdByUserId: json['created_by_user_id'],
      createdByAdmin: json['created_by_admin'] ?? false,
      postCount: json['post_count'] ?? 0,
      authorAlias: json['author_alias'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'status': status,
      'created_by_user_id': createdByUserId,
      'created_by_admin': createdByAdmin,
      'author_alias': authorAlias,
    };
  }

  Forum copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    String? status,
    String? createdByUserId,
    bool? createdByAdmin,
    int? postCount,
    String? authorAlias,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Forum(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      postCount: postCount ?? this.postCount,
      authorAlias: authorAlias ?? this.authorAlias,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ForumPost {
  final String id;
  final String forumId;
  final String? parentId;
  final String authorAlias;
  final String content;
  final String imageUrl;
  final String status;
  final int replyCount;
  final DateTime createdAt;

  ForumPost({
    required this.id,
    required this.forumId,
    this.parentId,
    required this.authorAlias,
    required this.content,
    required this.imageUrl,
    required this.status,
    required this.replyCount,
    required this.createdAt,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] ?? '',
      forumId: json['forum_id'] ?? '',
      parentId: json['parent_id'],
      authorAlias: json['author_alias'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ?? '',
      status: json['status'] ?? 'active',
      replyCount: json['reply_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
