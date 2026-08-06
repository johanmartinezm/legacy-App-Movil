/// Una inscripción del usuario a un evento, con los datos del evento ya
/// incorporados: es lo que pinta la pantalla "Mi credencial".
class RegistrationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String? eventLocation;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final String? eventImageUrl;
  final String paymentStatus;
  final String registrationStatus;
  final DateTime? registrationDate;

  /// Código que se dibuja como QR. Llega **vacío** en las inscripciones
  /// pendientes de pago: el backend no lo manda, porque no dan derecho a entrar.
  final String qrData;

  final double totalPaid;
  final bool attendanceConfirmed;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventLocation,
    this.eventStartDate,
    this.eventEndDate,
    this.eventImageUrl,
    required this.paymentStatus,
    required this.registrationStatus,
    this.registrationDate,
    required this.qrData,
    required this.totalPaid,
    required this.attendanceConfirmed,
  });

  /// Estados que usa el backend (`events.registrations.registration_status`).
  static const String estadoConfirmada = 'confirmed';
  static const String estadoPendientePago = 'pending_payment';

  bool get estaPendienteDePago => registrationStatus == estadoPendientePago;

  /// Solo hay credencial que enseñar si está confirmada y trae código.
  bool get tieneQr => qrData.isNotEmpty && !estaPendienteDePago;

  /// Un evento ya terminado no sirve para entrar a ningún sitio. Se compara
  /// contra el último día, y sin convertir a hora local: el backend serializa
  /// las fechas a medianoche UTC, y convertirlas en un huso negativo mostraría
  /// el día anterior.
  bool get eventoTerminado {
    final fin = eventEndDate ?? eventStartDate;
    if (fin == null) return false;
    final hoy = DateTime.now();
    final hoyUtc = DateTime.utc(hoy.year, hoy.month, hoy.day);
    return fin.isBefore(hoyUtc);
  }

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      eventTitle: json['eventTitle']?.toString() ?? 'Evento',
      eventLocation: json['eventLocation'] as String?,
      eventStartDate: DateTime.tryParse(json['eventStartDate']?.toString() ?? ''),
      eventEndDate: DateTime.tryParse(json['eventEndDate']?.toString() ?? ''),
      eventImageUrl: json['eventImageUrl'] as String?,
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      registrationStatus: json['registrationStatus']?.toString() ?? '',
      registrationDate:
          DateTime.tryParse(json['registrationDate']?.toString() ?? ''),
      qrData: json['qrData']?.toString() ?? '',
      totalPaid: _asDouble(json['totalPaid']),
      attendanceConfirmed: json['attendanceConfirmed'] == true,
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
