import 'package:fusion_lib/fusion_lib.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startTime,
    required this.schedule,
  });
  final String title;
  final DateTime startTime;
  final ScheduleConfig schedule;
}
