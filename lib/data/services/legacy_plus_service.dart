import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';

/// Un punto con check de la pantalla Legacy+, administrable desde el panel
/// («Puntos de Legacy+») desde el 2026-10-13.
class PuntoLegacyPlus {
  /// «incluye» (bajo «Tiene acceso a:») o «beneficios».
  final String grupo;
  final String titulo;
  final String texto;

  const PuntoLegacyPlus(this.grupo, this.titulo, this.texto);

  factory PuntoLegacyPlus.fromJson(Map<String, dynamic> json) => PuntoLegacyPlus(
        (json['grupo'] as String? ?? '').trim(),
        (json['titulo'] as String? ?? '').trim(),
        (json['texto'] as String? ?? '').trim(),
      );

  /// Los de siempre: se ven mientras carga, si el backend falla, o en el grupo
  /// que no tenga ningún punto activo.
  static const List<PuntoLegacyPlus> porDefecto = [
    PuntoLegacyPlus(
      'incluye',
      'Chats de sinergia',
      'Chats de sinergia entre pares: hay 4 chats para hablar de temas de Empresa, Patrimonio, Familia y otros entre miembros de otras familias empresarias.',
    ),
    PuntoLegacyPlus(
      'incluye',
      'Legacy Board',
      'Red de gobierno corporativo que conecta a familias empresarias y empresas que necesitan crear o fortalecer sus órganos de gobierno (juntas directivas, consejos de familia, directorios, advisory boards y comités) con profesionales que quieren servir en ellos.',
    ),
    PuntoLegacyPlus(
      'incluye',
      'Beneficios',
      'Son descuentos y servicios especiales de aliados o de Legacy Network.',
    ),
    PuntoLegacyPlus(
      'beneficios',
      'Legacy Network',
      'Legacy Test con descuento. Legacy Test: trampas familiares bonificado. Descuento LSO 15% para cualquier programa, 10% de descuento en los libros en nuestra página con el código xxxx. 20% de descuento en el Legacy Summit.',
    ),
    PuntoLegacyPlus(
      'beneficios',
      'Beneficios de aliados',
      'Vitalea, Olfabrand, Boconcept, Espectador, EUDE, JW Marriott.',
    ),
  ];
}

/// Pide los puntos activos, ya ordenados por el backend. **Nunca falla**: ante
/// cualquier error devuelve `null` y la pantalla se queda con los de siempre.
class LegacyPlusService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  LegacyPlusService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<PuntoLegacyPlus>?> puntos() async {
    try {
      final url = Uri.parse('$_baseUrl${ApiConstants.legacyPlusItemsEndpoint}');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! List) return null;

      return [
        for (final p in data)
          if (p is Map<String, dynamic>) PuntoLegacyPlus.fromJson(p),
      ].where((p) => p.titulo.isNotEmpty).toList();
    } catch (_) {
      return null;
    }
  }
}
