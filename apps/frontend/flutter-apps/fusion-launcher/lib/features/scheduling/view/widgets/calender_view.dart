import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_lib/fusion_utils/color_utils.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:intl/intl.dart';

class CalenderView extends StatefulWidget {
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
  State<CalenderView> createState() => _CalenderViewState();
}

class _CalenderViewState extends State<CalenderView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_onScrollChange);
    _horizontalController.addListener(_onScrollChange);
  }

  void _onScrollChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _verticalController.removeListener(_onScrollChange);
    _horizontalController.removeListener(_onScrollChange);
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateUtils.getDaysInMonth(widget.viewingMonth.year, widget.viewingMonth.month);
    const double hourLabelWidth = 100;
    const double dayLabelHeight = 50;
    const double hourWidth = 100;
    const double dayHeight = 200;
    final double totalWidth = hourLabelWidth + (24 * hourWidth);
    final double totalHeight = dayLabelHeight + (daysInMonth * dayHeight);

    return Stack(
      children: <Widget>[
        // Scrollable content: grid + events
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
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
                    // Events
                    ...widget.events.map((CalendarEvent event) {
                      final double top = dayLabelHeight + (event.startTime.day - 1) * dayHeight;
                      final double left = hourLabelWidth + (event.startTime.hour * hourWidth) + (event.startTime.minute / 60 * hourWidth);

                      final List<CalendarEvent> todaysEvents =
                          widget.eventsByDate[DateTime(event.startTime.year, event.startTime.month, event.startTime.day)] ?? <CalendarEvent>[];
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
          ),
        ),

        // Pinned time labels (top row), scroll horizontally only
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            height: dayLabelHeight,
            child: Stack(
              children: <Widget>[
                for (int i = 0; i < 24; i++)
                  Positioned(
                    top: 10,
                    left: hourLabelWidth + (i * hourWidth) - (_horizontalController.hasClients ? _horizontalController.offset : 0),
                    child: Container(
                      width: hourWidth,
                      height: dayLabelHeight,
                      decoration: BoxDecoration(
                        // color: Colors.red,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          left: BorderSide(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: Text(
                        ' ${i.toString().padLeft(2, '0')}:00',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Pinned day labels (left column), scroll vertically only
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            width: hourLabelWidth,
            child: Stack(
              children: <Widget>[
                for (int i = 1; i <= daysInMonth; i++)
                  Positioned(
                    top: dayLabelHeight + ((i - 1) * dayHeight) - (_verticalController.hasClients ? _verticalController.offset : 0),
                    left: 10,
                    height: dayHeight,
                    width: hourWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('MMM d').format(
                            DateTime(widget.viewingMonth.year, widget.viewingMonth.month, i),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,

          left: 0,
          width: hourWidth,
          height: dayLabelHeight,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
          ),
        ),
      ],
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
