class EventsData {
  final List<EventItem> events;

  EventsData({required this.events});

  factory EventsData.fromJson(Map<String, dynamic> json) {
    final evts = (json['events'] as List? ?? []).map((e) => EventItem.fromJson(e as Map<String, dynamic>)).toList();
    return EventsData(events: evts);
  }
}

class EventItem {
  final String id;
  final String title;
  final String category;
  final String date;
  final String? time;
  final String? location;
  final String? speaker; // legacy single speaker field
  final String priceLabel;
  final double price;
  final bool isFree;
  final String buttonText;
  final String actionStatus;
  final String imageUrl;
  final String description;
  final int? attendeesCount;

  // Additional fields that EventDetail expects
  final String status; // e.g., "Próximamente", "Finalizado"
  final String type; // e.g., "Presencial", "Virtual"
  final List<AgendaItem> agenda;
  final List<Speaker> speakers;

  EventItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.time,
    this.location,
    this.speaker,
    required this.priceLabel,
    required this.price,
    required this.isFree,
    required this.buttonText,
    required this.actionStatus,
    required this.imageUrl,
    required this.description,
    this.attendeesCount,
    required this.status,
    required this.type,
    required this.agenda,
    required this.speakers,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final List<AgendaItem> agenda = (json['agenda'] as List? ?? []).map((a) => AgendaItem.fromJson(a as Map<String, dynamic>)).toList();
    final List<Speaker> speakers = (json['speakers'] as List? ?? []).map((s) => Speaker.fromJson(s as Map<String, dynamic>)).toList();

    String inferredType;
    if (json.containsKey('type') && (json['type'] is String)) {
      inferredType = json['type'];
    } else {
      inferredType = (json['location'] == null) ? 'Virtual' : 'Presencial';
    }

    String inferredStatus = json['status'] ?? json['actionStatus'] ?? 'Próximamente';

    return EventItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      date: json['date'] ?? '',
      time: json['time'],
      location: json['location'],
      speaker: json['speaker'],
      priceLabel: json['priceLabel'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      isFree: json['isFree'] ?? false,
      buttonText: json['buttonText'] ?? '',
      actionStatus: json['actionStatus'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      attendeesCount: json['attendeesCount'],
      status: inferredStatus,
      type: inferredType,
      agenda: agenda,
      speakers: speakers,
    );
  }
}

class AgendaItem {
  final String time;
  final String activity;
  final String description;

  AgendaItem({required this.time, required this.activity, required this.description});

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      time: json['time'] ?? '',
      activity: json['activity'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Speaker {
  final String name;
  final String role;
  final String avatarUrl;

  Speaker({required this.name, required this.role, required this.avatarUrl});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}
