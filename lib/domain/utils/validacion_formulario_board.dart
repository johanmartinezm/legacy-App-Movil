/// Validación de un campo de los formularios de Legacy Board, sin depender de
/// Flutter para poder probarla sola, como `event_filters.dart`.
///
/// Repite las reglas de `board_formulario_service.go` para no gastar un viaje
/// al servidor en un error previsible. La que cuenta es la del servidor: si
/// las dos se separan, el backend rechaza y la pantalla lleva al campo.
library;

import '../../data/services/board_formularios_service.dart';

final _reTelefono = RegExp(r'^\+?[0-9 ().-]+$');
final _reCorreo = RegExp(r'^[^@\s<>()]+@[^@\s<>()]+\.[^@\s<>()]+$');

/// Normaliza el valor como lo hará el backend: los textos cortos sin espacios
/// de sobra, los largos recortados en los extremos, y lo vacío como `null`.
dynamic normalizarValorBoard(CampoBoard campo, dynamic valor) {
  if (valor == null) return null;
  if (valor is String) {
    final limpio = campo.tipo == TipoCampoBoard.textoLargo
        ? valor.trim()
        : valor.trim().split(RegExp(r'\s+')).join(' ');
    return limpio.isEmpty ? null : limpio;
  }
  if (valor is List) return valor.isEmpty ? null : valor;
  return valor;
}

/// Devuelve el mensaje de error del campo, o `null` si está bien. [hoy] es
/// para las pruebas.
String? validarCampoBoard(CampoBoard campo, dynamic valorCrudo, {DateTime? hoy}) {
  final valor = normalizarValorBoard(campo, valorCrudo);
  if (valor == null) {
    return campo.obligatorio ? 'Este campo es obligatorio' : null;
  }

  switch (campo.tipo) {
    case TipoCampoBoard.numero:
      final n = valor is int ? valor : int.tryParse('$valor');
      if (n == null) return 'Escribe un número entero';
      if ((campo.min != null && n < campo.min!) || (campo.max != null && n > campo.max!)) {
        return 'Debe estar entre ${campo.min} y ${campo.max}';
      }
      return null;

    case TipoCampoBoard.siNo:
      return valor is bool ? null : 'Elige sí o no';

    case TipoCampoBoard.multiseleccion:
      final ids = (valor as List).cast<String>();
      if (campo.exclusiva.isNotEmpty && ids.length > 1) {
        for (final o in campo.opciones) {
          if (o.codigo == campo.exclusiva && ids.contains(o.id)) {
            return '«${o.etiqueta}» no se puede marcar junto con otras opciones';
          }
        }
      }
      return null;

    case TipoCampoBoard.seleccion:
      return campo.opciones.any((o) => o.id == valor) ? null : 'Elige una opción';

    case TipoCampoBoard.foto:
      return '$valor'.startsWith('/api/images/') ? null : 'Sube la foto';
  }

  final texto = valor as String;
  if (texto.runes.length > campo.maximoTexto) {
    return 'Admite hasta ${campo.maximoTexto} caracteres';
  }
  switch (campo.tipo) {
    case TipoCampoBoard.texto:
    case TipoCampoBoard.textoLargo:
      if (campo.patron.isNotEmpty && !RegExp(campo.patron).hasMatch(texto)) {
        return 'Tiene caracteres no permitidos';
      }
    case TipoCampoBoard.email:
      if (!_reCorreo.hasMatch(texto) || texto.length > 254) return 'Escribe un correo válido';
    case TipoCampoBoard.telefono:
      final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (!_reTelefono.hasMatch(texto) || digitos < 7 || digitos > 15) {
        return 'Escribe un teléfono válido, con el código de país';
      }
    case TipoCampoBoard.fecha:
      final fecha = DateTime.tryParse(texto);
      final limite = hoy ?? DateTime.now();
      if (fecha == null || fecha.year < 1900 || fecha.isAfter(limite)) return 'Elige una fecha válida';
    case TipoCampoBoard.url:
      final uri = Uri.tryParse(texto);
      if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
        return 'Debe empezar por https://';
      }
      final host = uri.host.toLowerCase();
      if (campo.dominio.isNotEmpty && host != campo.dominio && !host.endsWith('.${campo.dominio}')) {
        return 'Debe ser un enlace de ${campo.dominio}';
      }
  }
  return null;
}

/// Las respuestas listas para el backend: solo las que tienen valor, ya
/// normalizadas. Un opcional vacío no viaja.
Map<String, dynamic> respuestasParaEnviarBoard(FormularioBoard formulario, Map<String, dynamic> valores) {
  final salida = <String, dynamic>{};
  for (final seccion in formulario.secciones) {
    for (final campo in seccion.campos) {
      var valor = normalizarValorBoard(campo, valores[campo.clave]);
      if (valor == null) continue;
      if (campo.tipo == TipoCampoBoard.numero && valor is String) {
        valor = int.tryParse(valor) ?? valor;
      }
      salida[campo.clave] = valor;
    }
  }
  return salida;
}

/// En qué sección está un campo; -1 si no está.
int seccionDelCampoBoard(FormularioBoard formulario, String clave) {
  for (var i = 0; i < formulario.secciones.length; i++) {
    if (formulario.secciones[i].campos.any((c) => c.clave == clave)) return i;
  }
  return -1;
}
