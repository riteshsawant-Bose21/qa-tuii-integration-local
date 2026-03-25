import 'dart:ui';

class EventItemEntity {
  final DateTime time;
  final String title;
  final String eventName;
  final String eventId;
  final Color accentColor;
  bool isEnabled;

  EventItemEntity({
    required this.time,
    required this.title,
    required this.eventName,
    required this.eventId,
    required this.accentColor,
    this.isEnabled = true,
  });


}
