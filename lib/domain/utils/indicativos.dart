/// Indicativos telefónicos de los países desde los que escribe la comunidad.
///
/// Se escribió el 2026-10-13 para el formulario de asesoría, donde el
/// indicativo pasó a ser obligatorio: sin él, un WhatsApp como «300 123 4567»
/// no se puede marcar desde fuera de Colombia. Vive aquí, y no en la pantalla,
/// para que registro y pago puedan usar la misma lista si se les pide.
///
/// Colombia va primero porque es de donde viene la mayoría; el resto, por
/// orden alfabético.
class Indicativo {
  final String pais;
  final String codigo;
  final String bandera;

  const Indicativo(this.pais, this.codigo, this.bandera);

  /// Lo que se ve en el desplegable abierto: «🇨🇴 Colombia (+57)».
  String get etiqueta => '$bandera $pais ($codigo)';

  /// Lo que se ve en el campo cerrado, que es estrecho: «🇨🇴 +57».
  String get corta => '$bandera $codigo';
}

const List<Indicativo> indicativos = [
  Indicativo('Colombia', '+57', '🇨🇴'),
  Indicativo('Alemania', '+49', '🇩🇪'),
  Indicativo('Argentina', '+54', '🇦🇷'),
  Indicativo('Bolivia', '+591', '🇧🇴'),
  Indicativo('Brasil', '+55', '🇧🇷'),
  Indicativo('Canadá', '+1', '🇨🇦'),
  Indicativo('Chile', '+56', '🇨🇱'),
  Indicativo('Costa Rica', '+506', '🇨🇷'),
  Indicativo('Ecuador', '+593', '🇪🇨'),
  Indicativo('El Salvador', '+503', '🇸🇻'),
  Indicativo('España', '+34', '🇪🇸'),
  Indicativo('Estados Unidos', '+1', '🇺🇸'),
  Indicativo('Francia', '+33', '🇫🇷'),
  Indicativo('Guatemala', '+502', '🇬🇹'),
  Indicativo('Honduras', '+504', '🇭🇳'),
  Indicativo('Italia', '+39', '🇮🇹'),
  Indicativo('México', '+52', '🇲🇽'),
  Indicativo('Nicaragua', '+505', '🇳🇮'),
  Indicativo('Panamá', '+507', '🇵🇦'),
  Indicativo('Paraguay', '+595', '🇵🇾'),
  Indicativo('Perú', '+51', '🇵🇪'),
  Indicativo('Portugal', '+351', '🇵🇹'),
  Indicativo('Puerto Rico', '+1', '🇵🇷'),
  Indicativo('Reino Unido', '+44', '🇬🇧'),
  Indicativo('República Dominicana', '+1', '🇩🇴'),
  Indicativo('Suiza', '+41', '🇨🇭'),
  Indicativo('Uruguay', '+598', '🇺🇾'),
  Indicativo('Venezuela', '+58', '🇻🇪'),
];

/// Cuántos dígitos tiene el número sin el indicativo. Los separadores
/// (espacios, guiones, paréntesis) no cuentan.
int digitosDe(String numero) => numero.replaceAll(RegExp(r'\D'), '').length;

/// Un número local plausible: entre 6 y 14 dígitos. No pretende validar el
/// plan de numeración de cada país, solo atrapar lo que seguro está mal.
bool numeroLocalValido(String numero) {
  final n = digitosDe(numero);
  return n >= 6 && n <= 14;
}

/// «+57 300 123 4567»: el indicativo y el número tal como se escribió.
String telefonoCompleto(Indicativo indicativo, String numero) =>
    '${indicativo.codigo} ${numero.trim()}';
