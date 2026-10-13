import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';
import 'solo_plus.dart';

/// Una tarjeta de la sección Beneficios: un beneficio o una alianza, cada tipo
/// en su slider. Se administran en el panel («Beneficios» y «Alianzas»).
class Beneficio {
  /// «beneficio» o «alianza».
  final String tipo;
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final String enlaceUrl;

  const Beneficio({
    required this.tipo,
    required this.titulo,
    this.descripcion = '',
    this.imagenUrl = '',
    this.enlaceUrl = '',
  });

  factory Beneficio.fromJson(Map<String, dynamic> json) => Beneficio(
        tipo: (json['tipo'] as String? ?? 'beneficio').trim(),
        titulo: (json['titulo'] as String? ?? '').trim(),
        descripcion: (json['descripcion'] as String? ?? '').trim(),
        imagenUrl: (json['imagen_url'] as String? ?? '').trim(),
        enlaceUrl: (json['enlace_url'] as String? ?? '').trim(),
      );
}

/// Pide las tarjetas activas, ya ordenadas por el backend. Solo para usuarios
/// Legacy+: lanza [SoloPlusException] ante el 403, y cualquier otro fallo como
/// excepción normal (la pantalla distingue los dos).
class BeneficiosService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  BeneficiosService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Beneficio>> beneficios(String? token) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.beneficiosEndpoint}');
    final response = await _client.get(url, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10));
    comprobarSoloPlus(response);
    if (response.statusCode != 200) {
      throw Exception('beneficios: ${response.statusCode}');
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data is! List) return [];
    return [
      for (final b in data)
        if (b is Map<String, dynamic>) Beneficio.fromJson(b),
    ].where((b) => b.titulo.isNotEmpty).toList();
  }
}
