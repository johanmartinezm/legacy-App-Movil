class GraphqlBook {
  final String id;
  final String name;

  /// La pagina del libro en la tienda de LSO.
  ///
  /// La compra se hace alli y no en la app: los libros son de LSO y se cobran
  /// en dolares. Decision del 2026-08-19, la misma que para los programas.
  final String? url;
  final String? description;
  final String? shortDescription;
  final String? imageUrl;
  final String? price;
  final String? regularPrice;
  final String stockStatus;

  GraphqlBook({
    required this.id,
    required this.name,
    this.url,
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
      url: (json['link'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['link'] as String,
      description: json['description'],
      shortDescription: json['shortDescription'],
      imageUrl: imageUrl,
      price: cleanPrice,
      regularPrice: cleanRegularPrice,
      stockStatus: json['stockStatus'] ?? 'IN_STOCK',
    );
  }
}
