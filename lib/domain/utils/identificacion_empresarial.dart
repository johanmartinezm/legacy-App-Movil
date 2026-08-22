/// Países y tipos de identificación que ofrece el paso "Empresa" del
/// registro. Vive aparte del formulario, sin depender de Flutter, para poder
/// probarlo sin pintar nada — igual que `event_filters.dart`.
///
/// Hasta el 2026-08-22 el país solo distinguía "Colombia" de "Otro", y ese
/// "Otro" ofrecía tipos de identificación de persona (Pasaporte, Documento
/// extranjero), no de empresa. Quien registraba una empresa fuera de Colombia
/// no encontraba su propio documento tributario (RFC, RUC, RUT...).
library;

/// Países LATAM que el registro reconoce por su propio tipo de documento.
/// "Otro" va al final como salida para cualquier país no listado.
const List<String> paisesLatam = [
  'Colombia',
  'México',
  'Perú',
  'Chile',
  'Argentina',
  'Ecuador',
  'Panamá',
  'República Dominicana',
  'Venezuela',
  'Bolivia',
  'Paraguay',
  'Uruguay',
  'Costa Rica',
  'Guatemala',
  'Honduras',
  'El Salvador',
  'Nicaragua',
  'Otro',
];

/// Tipos de identificación de empresa por país. NIT/RUC/RFC/RUT primero
/// porque es lo que se pide en la mayoría de los casos; el resto queda como
/// alternativa para quien opera como persona natural o aún no tiene el
/// documento tributario.
const Map<String, List<String>> _tiposPorPais = {
  'Colombia': ['NIT', 'Cédula', 'Cédula de extranjería', 'Pasaporte', 'Tarjeta de identidad'],
  'México': ['RFC', 'Pasaporte', 'Otro'],
  'Perú': ['RUC', 'DNI', 'Pasaporte', 'Otro'],
  'Chile': ['RUT', 'Pasaporte', 'Otro'],
  'Argentina': ['CUIT', 'DNI', 'Pasaporte', 'Otro'],
  'Ecuador': ['RUC', 'Cédula', 'Pasaporte', 'Otro'],
  'Panamá': ['RUC', 'Cédula', 'Pasaporte', 'Otro'],
  'República Dominicana': ['RNC', 'Cédula', 'Pasaporte', 'Otro'],
  'Venezuela': ['RIF', 'Cédula', 'Pasaporte', 'Otro'],
  'Bolivia': ['NIT', 'Cédula de identidad', 'Pasaporte', 'Otro'],
  'Paraguay': ['RUC', 'Cédula', 'Pasaporte', 'Otro'],
  'Uruguay': ['RUT', 'Cédula de identidad', 'Pasaporte', 'Otro'],
  'Costa Rica': ['Cédula jurídica', 'Cédula física', 'Pasaporte', 'Otro'],
  'Guatemala': ['NIT', 'DPI', 'Pasaporte', 'Otro'],
  'Honduras': ['RTN', 'Identidad', 'Pasaporte', 'Otro'],
  'El Salvador': ['NIT', 'DUI', 'Pasaporte', 'Otro'],
  'Nicaragua': ['RUC', 'Cédula', 'Pasaporte', 'Otro'],
};

/// Tipos de identificación para un país. Cualquier país fuera de la lista
/// —incluido "Otro"— cae en el mismo genérico de siempre.
List<String> tiposIdentificacionPara(String pais) {
  return _tiposPorPais[pais] ?? const ['Pasaporte', 'Documento extranjero', 'Otro'];
}
