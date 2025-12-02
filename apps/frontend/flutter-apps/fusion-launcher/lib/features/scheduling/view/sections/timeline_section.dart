part of '../scheduling_page.dart';

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return CalenderView(
      viewingMonth: DateTime.now(),
    );
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
  });
  final String title;
  final DateTime startTime;
  final DateTime endTime;
}

class CalenderView extends StatelessWidget {
  CalenderView({super.key, required this.viewingMonth});
  final DateTime viewingMonth;

  final List<CalendarEvent> _events = <CalendarEvent>[
    CalendarEvent(
      title: 'Team Meeting',
      startTime: DateTime.now().copyWith(day: 2, hour: 10, minute: 0),
      endTime: DateTime.now().copyWith(day: 2, hour: 11, minute: 30),
    ),
    CalendarEvent(
      title: 'Lunch',
      startTime: DateTime.now().copyWith(day: 3, hour: 12, minute: 0),
      endTime: DateTime.now().copyWith(day: 3, hour: 13, minute: 0),
    ),
    CalendarEvent(
      title: 'Design Review',
      startTime: DateTime.now().copyWith(day: 5, hour: 14, minute: 0),
      endTime: DateTime.now().copyWith(day: 5, hour: 16, minute: 0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateUtils.getDaysInMonth(viewingMonth.year, viewingMonth.month);
    const double hourLabelWidth = 100;
    const double dayLabelHeight = 50;
    const double hourWidth = 200;
    const double dayHeight = 100;
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
                            style: theme.textTheme.bodyMedium,
                          ),
                ),
              for (int i = 0; i < 24; i++)
                Positioned(
                  top: 10,
                  left: hourLabelWidth + (i * hourWidth) + 10,
                  child: Text(
                    '${i.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              // Events
              ..._events.map((CalendarEvent event) {
                final double top = dayLabelHeight + (event.startTime.day - 1) * dayHeight;
                final double left = hourLabelWidth + (event.startTime.hour * hourWidth) + (event.startTime.minute / 60 * hourWidth);
                final double width = event.endTime.difference(event.startTime).inMinutes / 60 * hourWidth;
                return Positioned(
                  top: top,
                  left: left,
                  width: width,
                  height: dayHeight,
                  child: Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        event.title,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
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
