import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/config_service.dart';
import 'solo_plus.dart';

/// Los formularios de Legacy Board: el A (postulación del consejero) y, en la
/// fase 4, el B (solicitud del empresario). La app no los define: los pide al
/// backend (`GET /api/board/formularios/{clave}`), que es quien los valida. Así
/// lo que se pinta y lo que se acepta no pueden separarse, y cambiar un texto o
/// una opción no exige publicar otra versión en las tiendas.

/// Tipos de campo del motor, los mismos de `domain/board_formulario.go`.
abstract final class TipoCampoBoard {
  static const texto = 'texto';
  static const textoLargo = 'texto_largo';
  static const email = 'email';
  static const telefono = 'telefono';
  static const numero = 'numero';
  static const fecha = 'fecha';
  static const url = 'url';
  static const seleccion = 'seleccion';
  static const multiseleccion = 'multiseleccion';
  static const siNo = 'sino';
  static const foto = 'foto';
}

class OpcionFormularioBoard {
  final String id;
  final String codigo;
  final String etiqueta;

  const OpcionFormularioBoard({required this.id, required this.codigo, required this.etiqueta});

  factory OpcionFormularioBoard.fromJson(Map<String, dynamic> json) => OpcionFormularioBoard(
        id: json['id'] as String? ?? '',
        codigo: json['codigo'] as String? ?? '',
        etiqueta: json['etiqueta'] as String? ?? '',
      );
}

class CampoBoard {
  final String clave;
  final String etiqueta;
  final String tipo;
  final bool obligatorio;
  final String ayuda;
  final String exclusiva;
  final int? min;
  final int? max;
  final int maxLargo;
  final String patron;
  final String dominio;
  final String prellenar;
  final List<OpcionFormularioBoard> opciones;

  const CampoBoard({
    required this.clave,
    required this.etiqueta,
    required this.tipo,
    this.obligatorio = false,
    this.ayuda = '',
    this.exclusiva = '',
    this.min,
    this.max,
    this.maxLargo = 0,
    this.patron = '',
    this.dominio = '',
    this.prellenar = '',
    this.opciones = const [],
  });

  factory CampoBoard.fromJson(Map<String, dynamic> json) => CampoBoard(
        clave: json['clave'] as String? ?? '',
        etiqueta: json['etiqueta'] as String? ?? '',
        tipo: json['tipo'] as String? ?? TipoCampoBoard.texto,
        obligatorio: json['obligatorio'] == true,
        ayuda: json['ayuda'] as String? ?? '',
        exclusiva: json['exclusiva'] as String? ?? '',
        min: (json['min'] as num?)?.toInt(),
        max: (json['max'] as num?)?.toInt(),
        maxLargo: (json['max_largo'] as num?)?.toInt() ?? 0,
        patron: json['patron'] as String? ?? '',
        dominio: json['dominio'] as String? ?? '',
        prellenar: json['prellenar'] as String? ?? '',
        opciones: [
          for (final o in (json['opciones'] as List? ?? const []))
            if (o is Map<String, dynamic>) OpcionFormularioBoard.fromJson(o),
        ],
      );

  /// Máximo de caracteres de un texto: el del backend, o 200 si no fija uno
  /// (`maxTextoBoardPorDefecto` en board_formulario_service.go).
  int get maximoTexto => maxLargo > 0 ? maxLargo : 200;
}

class SeccionBoard {
  final String titulo;
  final List<CampoBoard> campos;

  const SeccionBoard({required this.titulo, required this.campos});

  factory SeccionBoard.fromJson(Map<String, dynamic> json) => SeccionBoard(
        titulo: json['titulo'] as String? ?? '',
        campos: [
          for (final c in (json['campos'] as List? ?? const []))
            if (c is Map<String, dynamic>) CampoBoard.fromJson(c),
        ],
      );
}

/// Un formulario ya enviado. La app solo muestra su estado.
class EnvioBoard {
  final String id;
  final String formulario;

  /// «pendiente», «aprobada» o «rechazada».
  final String estado;
  final DateTime? creadoEn;

  const EnvioBoard({required this.id, required this.formulario, required this.estado, this.creadoEn});

  factory EnvioBoard.fromJson(Map<String, dynamic> json) => EnvioBoard(
        id: json['id'] as String? ?? '',
        formulario: json['formulario'] as String? ?? '',
        estado: json['estado'] as String? ?? 'pendiente',
        creadoEn: DateTime.tryParse(json['creado_en'] as String? ?? '')?.toLocal(),
      );
}

class FormularioBoard {
  final String clave;
  final String titulo;
  final String descripcion;
  final List<SeccionBoard> secciones;
  final String textoTerminos;
  final String textoConfirmacion;

  /// El envío que ya existe (el A enviado o el B pendiente). Si viene, la
  /// pantalla muestra su estado en vez del formulario.
  final EnvioBoard? envioActual;

  const FormularioBoard({
    required this.clave,
    required this.titulo,
    this.descripcion = '',
    this.secciones = const [],
    this.textoTerminos = '',
    this.textoConfirmacion = '',
    this.envioActual,
  });

  factory FormularioBoard.fromJson(Map<String, dynamic> json) => FormularioBoard(
        clave: json['clave'] as String? ?? '',
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        secciones: [
          for (final s in (json['secciones'] as List? ?? const []))
            if (s is Map<String, dynamic>) SeccionBoard.fromJson(s),
        ],
        textoTerminos: json['texto_terminos'] as String? ?? '',
        textoConfirmacion: json['texto_confirmacion'] as String? ?? '',
        envioActual: json['envio_actual'] is Map<String, dynamic>
            ? EnvioBoard.fromJson(json['envio_actual'] as Map<String, dynamic>)
            : null,
      );
}

/// El backend rechazó el envío. [campo] dice cuál, si fue uno concreto, para
/// que la pantalla lleve a la persona a esa sección.
class ErrorFormularioBoard implements Exception {
  final String mensaje;
  final String? campo;

  /// 409: ya lo había enviado (en otro dispositivo, o con dos toques).
  final bool yaEnviado;

  const ErrorFormularioBoard(this.mensaje, {this.campo, this.yaEnviado = false});

  @override
  String toString() => mensaje;
}

class BoardFormulariosService {
  final String _baseUrl = ConfigService.apiBaseUrl;
  final http.Client _client;

  BoardFormulariosService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _cabeceras(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Lanza [SoloPlusException] si la persona no tiene el plus.
  Future<FormularioBoard> formulario(String? token, String clave) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.boardFormularioEndpoint(clave)}');
    final response = await _client.get(url, headers: _cabeceras(token)).timeout(const Duration(seconds: 15));
    comprobarSoloPlus(response);
    if (response.statusCode != 200) {
      throw Exception('formulario $clave: ${response.statusCode}');
    }
    return FormularioBoard.fromJson(json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Envía las respuestas por clave de campo. Lanza [ErrorFormularioBoard]
  /// ante un rechazo del backend y una excepción normal ante un fallo de red.
  Future<EnvioBoard> enviar(
    String? token,
    String clave, {
    required Map<String, dynamic> respuestas,
    required bool aceptaTerminos,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.boardFormularioEndpoint(clave)}');
    final response = await _client
        .post(
          url,
          headers: _cabeceras(token),
          body: json.encode({'respuestas': respuestas, 'acepta_terminos': aceptaTerminos}),
        )
        .timeout(const Duration(seconds: 20));
    comprobarSoloPlus(response);
    if (response.statusCode == 201) {
      return EnvioBoard.fromJson(json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    String mensaje = 'No se pudo enviar el formulario (${response.statusCode}). Inténtalo de nuevo.';
    String? campo;
    try {
      final datos = json.decode(utf8.decode(response.bodyBytes));
      if (datos is Map) {
        if (datos['message'] is String && (datos['message'] as String).trim().isNotEmpty) {
          mensaje = (datos['message'] as String).trim();
        }
        if (datos['campo'] is String) campo = datos['campo'] as String;
      }
    } catch (_) {}
    throw ErrorFormularioBoard(mensaje, campo: campo, yaEnviado: response.statusCode == 409);
  }

  /// Sube la foto y devuelve la ruta que espera el formulario
  /// (`/api/images/<nombre>`, el mismo formato que la foto de perfil).
  Future<String> subirFoto(String? token, String rutaArchivo) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl${ApiConstants.imageUploadEndpoint}'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', rutaArchivo));
    final response = await http.Response.fromStream(await _client.send(request)).timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final nombre = (json.decode(response.body) as Map)['name'];
      if (nombre is String && nombre.isNotEmpty) return '/api/images/$nombre';
    }
    throw Exception('No se pudo subir la foto. Prueba con otra imagen de menos de 5 MB.');
  }
}
