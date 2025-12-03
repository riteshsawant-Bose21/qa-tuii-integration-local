import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_lib/fusion_utils/color_utils.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:intl/intl.dart';

class CalenderView extends StatelessWidget {
  final DateTime viewingMonth;
  final List<CalendarEvent> events;
  final Map<DateTime, List<CalendarEvent>> eventsByDate;
  const CalenderView({
    super.key,
    required this.viewingMonth,
    required this.events,
    required this.eventsByDate,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateUtils.getDaysInMonth(viewingMonth.year, viewingMonth.month);
    const double hourLabelWidth = 100;
    const double dayLabelHeight = 50;
    const double hourWidth = 100;
    const double dayHeight = 200;
    final double totalWidth = hourLabelWidth + (24 * hourWidth);
    final double totalHeight = dayLabelHeight + (daysInMonth * dayHeight);

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: <Widget>[
              // Grid lines
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _GridPainter(
                  daysInMonth: daysInMonth,
                  hourLabelWidth: hourLabelWidth,
                  dayLabelHeight: dayLabelHeight,
                  hourWidth: hourWidth,
                  dayHeight: dayHeight,
                  theme: theme,
                ),
              ),
              // Day and Time Labels
              for (int i = 0; i <= daysInMonth; i++)
                Positioned(
                  top: dayLabelHeight + (i * dayHeight) - (dayHeight / 2) - 10,
                  left: 10,
                  child:
                      i == 0
                          ? const SizedBox()
                          : Text(
                            DateFormat('MMM d').format(
                              DateTime(viewingMonth.year, viewingMonth.month, i),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                ),
              for (int i = 0; i < 24; i++)
                Positioned(
                  top: 10,
                  left: hourLabelWidth + (i * hourWidth) + 10,
                  child: Text(
                    '${i.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              // Events
              ...events.map((CalendarEvent event) {
                final double top = dayLabelHeight + (event.startTime.day - 1) * dayHeight;
                final double left = hourLabelWidth + (event.startTime.hour * hourWidth) + (event.startTime.minute / 60 * hourWidth);

                final List<CalendarEvent> todaysEvents =
                    eventsByDate[DateTime(event.startTime.year, event.startTime.month, event.startTime.day)] ?? <CalendarEvent>[];
                final List<CalendarEvent> overlappingEvents = <CalendarEvent>[];
                for (final CalendarEvent otherEvent in todaysEvents) {
                  final DateTime eventStartTime = event.startTime;
                  final DateTime otherStartTime = otherEvent.startTime;
                  final DateTime eventEndTime = eventStartTime.add(const Duration(hours: 1));
                  final DateTime otherEndTime = otherStartTime.add(const Duration(hours: 1));

                  if (eventStartTime.isBefore(otherEndTime) && otherStartTime.isBefore(eventEndTime)) {
                    overlappingEvents.add(otherEvent);
                  }
                }
                overlappingEvents.sort((CalendarEvent a, CalendarEvent b) => a.startTime.compareTo(b.startTime));
                final int currentEventPosition = overlappingEvents.indexOf(event);

                final double perEventHeight = (dayHeight * 0.9) / (overlappingEvents.isEmpty ? 1 : overlappingEvents.length);
                return Positioned(
                  top: top + (currentEventPosition * perEventHeight),
                  left: left,
                  // width: hourWidth,
                  height: perEventHeight.clamp(dayHeight * 0.1, dayHeight * 0.75),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorUtils.hexToColor(event.schedule.colorHex).withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                          color: ColorUtils.hexToColor(event.schedule.colorHex),
                          width: 5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Flex(
                        direction: overlappingEvents.length < 2 ? Axis.vertical : Axis.horizontal,
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: <Widget>[
                          FusionAppText(
                            text: event.title,
                            style: theme.textTheme.labelLarge,
                          ),
                          FusionAppText(
                            text: "At ${DateFormat('hh:mm a').format(event.startTime)}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.daysInMonth,
    required this.hourLabelWidth,
    required this.dayLabelHeight,
    required this.hourWidth,
    required this.dayHeight,
    required this.theme,
  });
  final int daysInMonth;
  final double hourLabelWidth;
  final double dayLabelHeight;
  final double hourWidth;
  final double dayHeight;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.grey.shade300;

    // Draw vertical lines
    for (int i = 0; i <= 24; i++) {
      final double x = hourLabelWidth + (i * hourWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= daysInMonth; i++) {
      final double y = dayLabelHeight + (i * dayHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
