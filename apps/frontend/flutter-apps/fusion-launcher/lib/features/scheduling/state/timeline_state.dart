import 'package:fusion_lib/fusion_lib.dart';

import '../model/calendar_event.dart';

class TimelineState {
  final List<CalendarEvent> allEvents;
  final DateTime visibleMonth;
  TimelineState({required this.allEvents, required this.visibleMonth}) {
    for (final CalendarEvent event in allEvents) {
      final DateTime eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      if (!eventsByDate.containsKey(eventDate)) {
        eventsByDate[eventDate] = <CalendarEvent>[];
      }
      eventsByDate[eventDate]!.add(event);
      if (event.startTime.year == visibleMonth.year && event.startTime.month == visibleMonth.month) {
        currentMonthEvents.add(event);
      }
    }
  }

  final List<CalendarEvent> currentMonthEvents = <CalendarEvent>[];

  final Map<DateTime, List<CalendarEvent>> eventsByDate = <DateTime, List<CalendarEvent>>{};

  static TimelineState initial() {
    return TimelineState(allEvents: <CalendarEvent>[], visibleMonth: DateTime.now());
  }
}

extension TimelineStateMethods on TimelineState {
  TimelineState refresh(List<ScheduleConfig> schedules) {
    final List<CalendarEvent> events = <CalendarEvent>[];

    CalendarEvent construct(ScheduleConfig schedule, DateTime date) {
      return CalendarEvent(
        title: schedule.name,
        startTime: date.copyWith(
          hour: schedule.time.hour,
          minute: schedule.time.minute,
        ),
        schedule: schedule,
      );
    }

    for (final ScheduleConfig schedule in schedules) {
      if (schedule.recurrence == RecurrenceType.none) {
        events.add(construct(schedule, schedule.startDate));
      } else {
        DateTime eventDate = schedule.startDate;
        final DateTime? endDate = schedule.endDate;
        while (eventDate.isBefore(endDate ?? eventDate.add(const Duration(days: 365 * 2)))) {
          if (schedule.recurrence == RecurrenceType.daily) {
            events.add(
              construct(schedule, eventDate),
            );
          } else if (schedule.recurrence == RecurrenceType.weekly) {
            if (schedule.weeklyDays.contains(eventDate.weekday)) {
              events.add(
                construct(schedule, eventDate),
              );
            }
          }
          eventDate = eventDate.add(const Duration(days: 1));
        }
      }
    }

    return TimelineState(
      allEvents: events,
      visibleMonth: visibleMonth,
    );
  }

  TimelineState changeMonth(DateTime newMonth) {
    return TimelineState(
      allEvents: allEvents,
      visibleMonth: newMonth,
    );
  }
}
