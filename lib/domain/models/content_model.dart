class ContentItem {
  final String id;
  final String title;
  final String type;
  final String category;
  final bool isFree;
  final String imageUrl;
  final String? description;
  final double? price;

  final String? currency;
  final String? videoUrl;

  // Detail fields
  final String? fullContent;
  final String? authorName;
  final String? authorRole;
  final String? authorAvatar;
  final String? date;
  final String? readTime;
  final String? views;
  final int? totalViews;
  final int? likes;
  final int? dislikes;
  final int? comments;
  final List<ContentItem>? relatedContent;
  final String? duration;
  final String? externalUrl;
  final bool isLikedByMe;

  ContentItem({
    required this.id,
    required this.title,
    this.type = '',
    required this.category,
    required this.isFree,
    required this.imageUrl,
    this.description,
    this.price,
    this.currency,
    this.videoUrl,
    this.fullContent,
    this.authorName,
    this.authorRole,
    this.authorAvatar,
    this.date,
    this.readTime,
    this.views,
    this.totalViews,
    this.likes,
    this.dislikes,
    this.comments,
    this.relatedContent,
    this.duration,
    this.externalUrl,
    this.isLikedByMe = false,
  });

  ContentItem copyWith({int? likes, bool? isLikedByMe, int? totalViews}) {
    return ContentItem(
      id: id,
      title: title,
      type: type,
      category: category,
      isFree: isFree,
      imageUrl: imageUrl,
      description: description,
      price: price,
      currency: currency,
      videoUrl: videoUrl,
      fullContent: fullContent,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorAvatar,
      date: date,
      readTime: readTime,
      views: views,
      totalViews: totalViews ?? this.totalViews,
      likes: likes ?? this.likes,
      dislikes: dislikes,
      comments: comments,
      relatedContent: relatedContent,
      duration: duration,
      externalUrl: externalUrl,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    // Handle author which can be a String or Map
    String? authorName;
    String? authorRole;
    String? authorAvatar;

    if (json['author'] is String) {
      authorName = json['author'];
    } else if (json['author'] is Map) {
      authorName = json['author']['name'];
      authorRole = json['author']['role'];
      authorAvatar = json['author']['avatarUrl'];
    }

    return ContentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isFree: json['isFree'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      videoUrl: json['videoUrl'] as String?,
      fullContent: json['fullContent'] as String?,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorAvatar,
      date: json['date'] as String?,
      readTime:
          json['readTime'] as String? ??
          json['time'] as String?, // Handle 'time' alias from related content
      views: json['views'] as String?,
      likes: json['likes'] as int?,
      dislikes: json['dislikes'] as int?,
      comments: json['comments'] as int?,
      duration: json['duration'] as String?,
      externalUrl: json['externalUrl'] as String?,
      relatedContent: (json['relatedContent'] as List?)
          ?.map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String icon;

  Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }
}

class InformandoteData {
  final List<ContentItem> freeContent;
  final List<ContentItem> paidContent;
  final List<Category> categories;

  InformandoteData({
    required this.freeContent,
    required this.paidContent,
    required this.categories,
  });

  factory InformandoteData.fromJson(Map<String, dynamic> json) {
    return InformandoteData(
      freeContent: (json['freeContent'] as List)
          .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paidContent: (json['paidContent'] as List)
          .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
