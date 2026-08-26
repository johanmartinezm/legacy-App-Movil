/// Reparte en nombre y apellido el nombre completo que da Google o Apple.
///
/// El backend devuelve `name` como **una sola cadena** (la rama del 404 de
/// `SocialLogin`), y el formulario de registro pide nombre y apellido por
/// separado. Alguien tiene que partirla, y no hay forma de acertar siempre: la
/// cadena no dice dónde acaba el nombre.
///
/// ## Qué hacía antes
///
/// La primera palabra era el nombre y **todo lo demás** el apellido. Con dos
/// palabras funciona; con cuatro, que es lo normal aquí —dos nombres y dos
/// apellidos—, «Johan Yezid Martinez Melo» quedaba como nombre «Johan» y
/// apellido «Yezid Martinez Melo».
///
/// ## La regla
///
/// El apellido se queda con la **mitad de atrás, redondeando hacia arriba**:
///
/// | Palabras | Nombre | Apellido | Ejemplo |
/// |---|---|---|---|
/// | 1 | todo | vacío | `Ana` |
/// | 2 | 1 | 1 | `Ana` · `Restrepo` |
/// | 3 | 1 | 2 | `Ana` · `Restrepo Gómez` |
/// | 4 | 2 | 2 | `Johan Yezid` · `Martinez Melo` |
/// | 5 | 2 | 3 | |
///
/// Con tres palabras sigue siendo una apuesta —`Juan Carlos Pérez` y
/// `Juan Pérez Gómez` se escriben igual— y se elige la de dos apellidos, que es
/// la común entre quienes usan esta app. **Con una sola palabra el apellido
/// queda vacío a propósito**: inventarlo sería peor, y el formulario lo pide
/// como obligatorio, así que quien se registra lo completa.
///
/// Esto solo **prellena** el formulario: quien se registra puede corregirlo
/// antes de enviar. Por eso vale una regla razonable y no hace falta acertar
/// siempre.
({String nombre, String apellido}) repartirNombre(String? completo) {
  final partes = (completo ?? '')
      .split(' ')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  if (partes.isEmpty) {
    return (nombre: '', apellido: '');
  }
  if (partes.length == 1) {
    return (nombre: partes.first, apellido: '');
  }

  // Mitad de atrás redondeando hacia arriba: con 3 son 2 apellidos, con 4 son
  // 2 y 2.
  final cuantosApellidos = (partes.length + 1) ~/ 2;
  final corte = partes.length - cuantosApellidos;

  return (
    nombre: partes.sublist(0, corte).join(' '),
    apellido: partes.sublist(corte).join(' '),
  );
}
