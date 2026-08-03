class BannerModel {
  final String? id;
  final String title;
  final String? subtitle;
  final String category;
  final String imageUrl;
  final String actionType;
  final String? actionTarget;
  final bool isActive;
  final int sortOrder;

  BannerModel({
    this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.imageUrl,
    required this.actionType,
    this.actionTarget,
    required this.isActive,
    required this.sortOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      category: json['category'] ?? 'home',
      imageUrl: json['image_url'] ?? '',
      actionType: json['action_type'] ?? 'none',
      actionTarget: json['action_target'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'image_url': imageUrl,
      'action_type': actionType,
      'action_target': actionTarget,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
