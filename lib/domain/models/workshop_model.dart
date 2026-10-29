class WorkshopModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String name;
  final String description;
  final String room;
  final String speaker;
  final String? imageUrl;
  final DateTime startDateTime;
  final DateTime endDateTime;

  WorkshopModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.name,
    this.description = '',
    required this.room,
    required this.speaker,
    this.imageUrl,
    required this.startDateTime,
    required this.endDateTime,
  });

  /// Solo se califica un taller que ya terminó: el backend rechaza el resto
  /// desde el 2026-10-28, y antes la app ofrecía el botón siempre.
  bool get terminado => endDateTime.isBefore(DateTime.now());

  factory WorkshopModel.fromJson(
    Map<String, dynamic> json, {
    String eventId = '',
    String eventTitle = '',
  }) {
    return WorkshopModel(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? eventId,
      eventTitle: json['eventTitle'] ?? eventTitle,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      room: json['room'] ?? '',
      speaker: json['speaker'] ?? '',
      imageUrl: json['imageUrl'],
      // A diferencia de las fechas del evento (columnas `date`, sin hora), las
      // del taller son instantes con zona: el backend manda «09:00-05:00».
      // DateTime.parse los deja en UTC, y sin toLocal() el cronograma pintaba
      // «14:00» para un taller de las nueve de la mañana.
      startDateTime: DateTime.parse(
        json['startDateTime'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      endDateTime: DateTime.parse(
        json['endDateTime'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'name': name,
      'description': description,
      'room': room,
      'speaker': speaker,
      'imageUrl': imageUrl,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
    };
  }
}
