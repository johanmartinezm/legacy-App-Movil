import 'content_model.dart';

enum CustomContentType { text, video }

class CustomContent {
  final String id;
  final String? categoryId;
  final CustomContentType type;
  final String title;
  final String excerpt;
  final String bodyText;
  final String videoUrl;
  final String thumbnailUrl;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? categoryName;

  CustomContent({
    required this.id,
    this.categoryId,
    required this.type,
    required this.title,
    required this.excerpt,
    required this.bodyText,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isPublished,
    this.publishedAt,
    this.categoryName,
  });

  factory CustomContent.fromJson(Map<String, dynamic> json) {
    return CustomContent(
      id: json['id'],
      categoryId: json['category_id'],
      type: json['type'] == 'video'
          ? CustomContentType.video
          : CustomContentType.text,
      title: json['title'],
      excerpt: json['excerpt'] ?? '',
      bodyText: json['body_text'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      isPublished: json['is_published'] ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      categoryName: json['category_name'],
    );
  }

  ContentItem toContentItem() {
    return ContentItem(
      id: id,
      title: title,
      type: type == CustomContentType.video ? 'video' : 'article',
      category: categoryName ?? 'General',
      isFree: true,
      imageUrl: thumbnailUrl,
      description: excerpt,
      fullContent: bodyText,
      videoUrl: type == CustomContentType.video ? videoUrl : null,
      date: publishedAt?.toIso8601String().split('T')[0],
    );
  }
}
