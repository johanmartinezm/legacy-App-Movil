import 'package:intl/intl.dart';
import '../models/workshop_model.dart';
import '../../config/utils/currency_formatter.dart';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String date;
  /// Fecha de inicio sin formatear, para poder comparar. `date` llega ya
  /// convertida a dd/MM/yyyy y no sirve para ordenar ni para saber si el
  /// evento ya pasó.
  final DateTime? startDate;
  final DateTime? endDate;
  final String? time;
  final String? location;
  final String? speaker;
  final String priceLabel;
  final double price;
  final bool isFree;
  final String buttonText;
  final String actionStatus;
  final String imageUrl;
  final String description;
  final String? includes;
  final int categoryOrder;
  final int? attendeesCount;
  final List<WorkshopModel> workshops;

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.startDate,
    this.endDate,
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
    this.includes,
    this.categoryOrder = 0,
    this.attendeesCount,
    this.workshops = const [],
  });

  EventModel copyWith({
    String? buttonText,
    String? actionStatus,
    int? attendeesCount,
  }) {
    return EventModel(
      id: id,
      title: title,
      category: category,
      date: date,
      startDate: startDate,
      endDate: endDate,
      time: time,
      location: location,
      speaker: speaker,
      priceLabel: priceLabel,
      price: price,
      isFree: isFree,
      buttonText: buttonText ?? this.buttonText,
      actionStatus: actionStatus ?? this.actionStatus,
      imageUrl: imageUrl,
      description: description,
      includes: includes,
      categoryOrder: categoryOrder,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      workshops: workshops,
    );
  }

  /// Un evento es pasado cuando su último día quedó atrás. Los eventos de hoy
  /// siguen contando como próximos durante toda la jornada, y los que llegan
  /// sin fecha utilizable nunca se ocultan del listado principal.
  bool get isPast {
    final DateTime? ref = endDate ?? startDate;
    if (ref == null) return false;
    final DateTime hoy = DateTime.now();
    return DateTime(
      ref.year,
      ref.month,
      ref.day,
    ).isBefore(DateTime(hoy.year, hoy.month, hoy.day));
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final String eventId = json['id'] ?? '';
    final String eventTitle = json['title'] ?? '';

    // Format date if it's in ISO format
    String displayDate = json['date'] ?? '';
    try {
      if (displayDate.contains('T')) {
        final DateTime dt = DateTime.parse(displayDate);
        displayDate = DateFormat('dd/MM/yyyy').format(dt);
      }
    } catch (_) {}

    // El backend guarda start_date/end_date como `date` (medianoche UTC). No se
    // convierten a hora local a propósito: en husos negativos eso mostraría el
    // día anterior, y el texto de arriba tampoco convierte.
    final DateTime? startDate = DateTime.tryParse(json['date'] ?? '');
    final DateTime? endDate = DateTime.tryParse(json['end_date'] ?? '');

    return EventModel(
      id: eventId,
      title: eventTitle,
      category: json['category'] ?? '',
      date: displayDate,
      startDate: startDate,
      endDate: endDate,
      time: json['time'],
      location: json['location'],
      speaker: json['speaker'],
      priceLabel: (json['isFree'] == true || (json['price'] as num? ?? 0) == 0)
          ? 'GRATIS'
          : CurrencyFormatter.format((json['price'] as num?)?.toDouble() ?? 0.0),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isFree: json['isFree'] ?? false,
      buttonText: json['buttonText'] ?? '',
      actionStatus: json['actionStatus'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      includes: json['includes'],
      categoryOrder: json['categoryOrder'] ?? 0,
      attendeesCount: json['attendeesCount'],
      workshops:
          (json['workshops'] as List?)
              ?.map(
                (w) => WorkshopModel.fromJson(
                  w,
                  eventId: eventId,
                  eventTitle: eventTitle,
                ),
              )
              .toList() ??
          [],
    );
  }
}
