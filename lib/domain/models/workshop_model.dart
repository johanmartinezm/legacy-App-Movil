class WorkshopModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String name;
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
    required this.room,
    required this.speaker,
    this.imageUrl,
    required this.startDateTime,
    required this.endDateTime,
  });

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
      room: json['room'] ?? '',
      speaker: json['speaker'] ?? '',
      imageUrl: json['imageUrl'],
      startDateTime: DateTime.parse(
        json['startDateTime'] ?? DateTime.now().toIso8601String(),
      ),
      endDateTime: DateTime.parse(
        json['endDateTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'name': name,
      'room': room,
      'speaker': speaker,
      'imageUrl': imageUrl,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
    };
  }
}
