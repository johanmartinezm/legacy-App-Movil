class GraphqlBook {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String? imageUrl;
  final String? price;
  final String? regularPrice;
  final String stockStatus;

  GraphqlBook({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    this.imageUrl,
    this.price,
    this.regularPrice,
    required this.stockStatus,
  });

  factory GraphqlBook.fromJson(Map<String, dynamic> json) {
    // Extract image URL
    String? imageUrl;
    if (json['image'] != null) {
      imageUrl = json['image']['sourceUrl'];
      if (imageUrl != null) {
        imageUrl = imageUrl.replaceAll('localhost:8080', 'localhost:8082');
      }
    }

    // Clean price (remove &nbsp; and other HTML entities if needed)
    String? cleanPrice = json['price']?.replaceAll('&nbsp;', ' ');
    String? cleanRegularPrice = json['regularPrice']?.replaceAll('&nbsp;', ' ');

    return GraphqlBook(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      shortDescription: json['shortDescription'],
      imageUrl: imageUrl,
      price: cleanPrice,
      regularPrice: cleanRegularPrice,
      stockStatus: json['stockStatus'] ?? 'IN_STOCK',
    );
  }
}
