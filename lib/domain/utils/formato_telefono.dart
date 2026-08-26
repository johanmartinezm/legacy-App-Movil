import 'package:flutter/services.dart';

/// Filtros de entrada para los campos de teléfono.
///
/// `TextInputType.phone` **no impide escribir letras**: elige qué teclado se
/// ofrece, no qué se acepta. Con un teclado predictivo, uno físico, un pegado
/// desde el portapapeles o la app compilada para web, un teléfono acaba con
/// letras dentro y nadie lo nota hasta que hay que llamar a esa persona.
///
/// No es `digitsOnly` a propósito: el propio ejemplo de los campos lleva `+` y
/// espacios (`+57 300 123 4567`), y hay quien escribe el indicativo entre
/// paréntesis. Lo que se bloquea son las letras.
///
/// Vive aquí y no dentro de una pantalla porque los tres formularios que piden
/// un teléfono —registro, asesoría y el pago de un evento— tienen que filtrar
/// igual; cuando estaba escrito a mano solo lo tenía el registro.
final List<TextInputFormatter> formateadoresDeTelefono = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
];
