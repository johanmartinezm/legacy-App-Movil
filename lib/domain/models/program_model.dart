
class GraphqlProgram {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String? imageUrl;
  final String? price;
  final String modality;
  final String duration;
  final String type; // Programa, Módulo, Curso
  
  /// Lo que se muestra como precio, con su moneda.
  ///
  /// LSO publica en dólares y su tienda devuelve solo la cifra, sin decir de
  /// qué moneda: junto a los eventos de Legacy, que van en pesos colombianos,
  /// un «$300» suelto pasa por trescientos pesos. La moneda va delante para
  /// que siga leyéndose aunque la tarjeta recorte el final.
  ///
  /// Devuelve null cuando el producto no trae precio; ese caso se muestra como
  /// «Cotización», y hoy hay tres programas así en la tienda.
  String? get precioConMoneda {
    final crudo = price?.trim();
    if (crudo == null || crudo.isEmpty) return null;
    return 'USD $crudo';
  }

  double get priceValue {
    if (price == null || price!.isEmpty) return 0.0;
    // Remove currency symbol, spaces, and thousand separators (.)
    // and replace decimal separator (if any)
    String cleanStr = price!.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanStr) ?? 0.0;
  }

  GraphqlProgram({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    this.imageUrl,
    this.price,
    this.modality = 'Virtual',
    this.duration = 'Consultar',
    this.type = 'Curso',
  });

  factory GraphqlProgram.fromJson(Map<String, dynamic> json) {
    // Extract image URL
    String? imageUrl;
    if (json['image'] != null) {
      imageUrl = json['image']['sourceUrl'];
    }

    // Clean price
    String? cleanPrice = json['price']?.replaceAll('&nbsp;', ' ');
    
    // Determine modality and type from categories
    String modality = 'Virtual';
    String type = 'Curso';
    final nameLower = (json['name'] as String? ?? '').toLowerCase();

    if (json['productCategories'] != null && json['productCategories']['nodes'] != null) {
      final categories = json['productCategories']['nodes'] as List;
      
      // Modality
      if (categories.any((cat) => cat['slug'] == 'programas-presenciales')) {
        modality = 'Presencial';
      } else if (categories.any((cat) => cat['slug'] == 'virtuales-en-vivo')) {
        modality = 'Virtual en vivo';
      }

      // Type classification
      if (categories.any((cat) => cat['slug'] == 'modulos') || nameLower.contains('módulo') || nameLower.contains('modulo')) {
        type = 'Módulo';
      } else if (nameLower.contains('programa')) {
        type = 'Programa';
      } else if (categories.any((cat) => cat['slug'] == 'programas')) {
        type = 'Curso';
      }
    }

    return GraphqlProgram(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      shortDescription: _stripHtml(json['shortDescription'] ?? ''),
      imageUrl: imageUrl,
      price: cleanPrice,
      modality: modality,
      duration: '40 horas',
      type: type,
    );
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
