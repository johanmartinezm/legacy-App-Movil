import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';

/// Una unidad de Asesoría («NUESTRAS UNIDADES»), administrable desde el panel
/// desde el 2026-10-13.
class UnidadAsesoria {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  /// Opción de «¿Qué necesita?» que el formulario marca al entrar por aquí.
  final String necesidad;

  const UnidadAsesoria({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.necesidad,
  });

  /// Claves de icono que guarda el panel → icono de la app. La misma lista
  /// vive en el backend (domain/asesoria_unidad.go) y en el panel
  /// (asesoria-unidad.model.ts). Una clave desconocida pinta el genérico.
  static const Map<String, IconData> iconos = {
    'escudo': Icons.verified_user_outlined,
    'crecimiento': Icons.trending_up,
    'balanza': Icons.balance,
    'formacion': Icons.school_outlined,
    'grupo': Icons.groups_outlined,
    'negocio': Icons.business_center_outlined,
    'familia': Icons.family_restroom,
    'banco': Icons.account_balance_outlined,
    'apreton': Icons.handshake_outlined,
    'mazo': Icons.gavel,
  };

  factory UnidadAsesoria.fromJson(Map<String, dynamic> json) => UnidadAsesoria(
        titulo: (json['titulo'] as String? ?? '').trim(),
        subtitulo: (json['subtitulo'] as String? ?? '').trim(),
        icono: iconos[json['icono']] ?? Icons.business_center_outlined,
        necesidad: (json['necesidad'] as String? ?? 'Otro').trim(),
      );

  /// Las cinco de siempre: se ven mientras carga y si el backend no responde,
  /// para que la pantalla nunca quede vacía.
  static const List<UnidadAsesoria> porDefecto = [
    UnidadAsesoria(
      titulo: 'L&M Consultoría',
      subtitulo: 'Gobierno corporativo, empresa familiar y patrimonio',
      icono: Icons.verified_user_outlined,
      necesidad: 'Gobierno',
    ),
    UnidadAsesoria(
      titulo: 'Aurum Legacy Advisors',
      subtitulo: 'Finanzas estratégicas y crecimiento patrimonial',
      icono: Icons.trending_up,
      necesidad: 'Patrimonio',
    ),
    UnidadAsesoria(
      titulo: 'Legacy Legal',
      subtitulo: 'Estructuración jurídica, tributaria y patrimonial',
      icono: Icons.balance,
      necesidad: 'Legal/Tributario',
    ),
    UnidadAsesoria(
      titulo: 'LSO',
      subtitulo: 'Formación y certificación para propietarios',
      icono: Icons.school_outlined,
      necesidad: 'Certificación',
    ),
    UnidadAsesoria(
      titulo: 'Network en Gobierno Corporativo',
      subtitulo: 'Consejeros y miembros de junta',
      icono: Icons.groups_outlined,
      necesidad: 'Gobierno',
    ),
  ];
}

/// Pide las unidades activas, en el orden del panel. **Nunca falla**: ante
/// cualquier error, o una lista vacía, devuelve `null` y la pantalla se queda
/// con [UnidadAsesoria.porDefecto].
class AsesoriaUnidadesService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  AsesoriaUnidadesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<UnidadAsesoria>?> unidades() async {
    try {
      final url = Uri.parse('$_baseUrl${ApiConstants.asesoriaUnidadesEndpoint}');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! List) return null;

      final unidades = [
        for (final u in data)
          if (u is Map<String, dynamic>) UnidadAsesoria.fromJson(u),
      ].where((u) => u.titulo.isNotEmpty).toList();
      return unidades.isEmpty ? null : unidades;
    } catch (_) {
      return null;
    }
  }
}
