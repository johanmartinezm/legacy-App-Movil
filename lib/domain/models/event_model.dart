import 'package:intl/intl.dart';
import '../models/workshop_model.dart';
import '../../config/utils/currency_formatter.dart';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String date;
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

    return EventModel(
      id: eventId,
      title: eventTitle,
      category: json['category'] ?? '',
      date: displayDate,
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
