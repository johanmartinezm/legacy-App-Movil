
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
