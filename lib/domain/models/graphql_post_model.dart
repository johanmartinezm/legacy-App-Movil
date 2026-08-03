import 'content_model.dart';

class GraphqlPost {
  final String id;
  final String title;
  final String date;
  final String excerpt;
  final String? content; // Added full content
  final String? featuredImageUrl;
  final List<GraphqlCategory> categories;

  GraphqlPost({
    required this.id,
    required this.title,
    required this.date,
    required this.excerpt,
    this.content,
    this.featuredImageUrl,
    required this.categories,
  });

  factory GraphqlPost.fromJson(Map<String, dynamic> json) {
    // Extract image URL from featuredImage.node.sourceUrl
    String? imageUrl;
    if (json['featuredImage'] != null &&
        json['featuredImage']['node'] != null) {
      imageUrl = json['featuredImage']['node']['sourceUrl'];

      // For Flutter Web and Docker, we use localhost.
      // Ensure the port is 8082 as specified.
      if (imageUrl != null) {
        imageUrl = imageUrl.replaceAll('localhost:8080', 'localhost:8082');
      }
    }

    // Extract categories from categories.nodes
    List<GraphqlCategory> categoriesList = [];
    if (json['categories'] != null && json['categories']['nodes'] != null) {
      categoriesList = (json['categories']['nodes'] as List)
          .map((c) => GraphqlCategory.fromJson(c))
          .toList();
    }

    return GraphqlPost(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      excerpt: json['excerpt'] ?? '',
      content: json['content'],
      featuredImageUrl: imageUrl,
      categories: categoriesList,
    );
  }

  /// Converts this post to a [ContentItem] for compatibility with existing detail screens
  ContentItem toContentItem() {
    return ContentItem(
      id: id,
      title: title,
      type: 'article',
      category: categories.isNotEmpty ? categories.first.name : 'Artículo',
      isFree: true,
      imageUrl: featuredImageUrl ?? '',
      description: excerpt.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
      fullContent: content ?? excerpt,
      date: date.split('T')[0],
      readTime: '5 min', // Mock for now
    );
  }
}

class GraphqlCategory {
  final String name;
  final String slug;

  GraphqlCategory({required this.name, required this.slug});

  factory GraphqlCategory.fromJson(Map<String, dynamic> json) {
    return GraphqlCategory(name: json['name'], slug: json['slug']);
  }
}

class GraphqlPostsResponse {
  final List<GraphqlPost> posts;
  final String? endCursor;
  final bool hasNextPage;

  GraphqlPostsResponse({
    required this.posts,
    this.endCursor,
    required this.hasNextPage,
  });
}
