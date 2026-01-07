import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_launcher/features/scheduling/view/sections/scheduler_form.dart';
import 'package:fusion_launcher/features/scheduling/viewmodel/scheduler_viewmodel.dart';
import 'package:fusion_lib/fusion_utils/color_utils.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_text_button.dart';
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

  HoveredEventInfo? _hoveredEventInfo;
  void onHover(CalendarEvent event, Offset position, Size size) {
    setState(() {
      _hoveredEventInfo = HoveredEventInfo(event: event, position: position, size: size);
    });
  }

  void onHoverExit() {
    setState(() {
      _hoveredEventInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateUtils.getDaysInMonth(widget.viewingMonth.year, widget.viewingMonth.month);
    const double hourLabelWidth = 100;
    const double dayLabelHeight = 50;
    const double dayWidth = 100;
    const double hourHeight = 200;
    final double totalWidth = hourLabelWidth + (daysInMonth * dayWidth);
    final double totalHeight = dayLabelHeight + (24 * hourHeight);

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
                        dayWidth: dayWidth,
                        hourHeight: hourHeight,
                        theme: theme,
                      ),
                    ),
                    // Events
                    ...widget.events.map((CalendarEvent event) {
                      final double top = dayLabelHeight + (event.startTime.hour * hourHeight) + (event.startTime.minute / 60 * hourHeight);
                      final double left = hourLabelWidth + (event.startTime.day - 1) * dayWidth;

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

                      final double perEventWidth = (dayWidth * 0.95) / (overlappingEvents.isEmpty ? 1 : overlappingEvents.length);
                      final double left2 = left + (currentEventPosition * perEventWidth);
                      final double clamp = perEventWidth.clamp(dayWidth * 0.1, dayWidth);
                      return Positioned(
                        top: top,
                        left: left2,
                        width: clamp,
                        // height: hourHeight,
                        child: MouseRegion(
                          cursor: MouseCursor.uncontrolled,
                          onEnter: (PointerEnterEvent _) {},
                          onExit: (PointerExitEvent _) {
                            // onHoverExit();
                          },
                          child: InkWell(
                            onTap: () {
                              onHover(event, Offset(left2, top), Size(clamp, hourHeight));
                              // SchedulerForm.show(context, context.read<SchedulerViewmodel>(), initial: event.schedule);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                // color: ColorUtils.hexToColor(event.schedule.colorHex).withAlpha(50),
                                // borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  top: BorderSide(
                                    color: ColorUtils.hexToColor(event.schedule.colorHex),
                                    width: 5,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 5,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: event.title,
                                      style: theme.textTheme.labelLarge,
                                      maxLine: 2,
                                      textAlign: TextAlign.start,
                                    ),
                                    FusionAppText(
                                      text: "At ${DateFormat('hh:mm a').format(event.startTime)}",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.black38,
                                      ),
                                      textAlign: TextAlign.start,
                                      maxLine: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_hoveredEventInfo != null) ...<Widget>[
                      Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () {
                            onHoverExit();
                          },
                          child: Container(
                            width: totalWidth,
                            height: totalHeight,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      Positioned(
                        top: _hoveredEventInfo!.position.dy,
                        left: _hoveredEventInfo!.position.dx + _hoveredEventInfo!.size.width + 10,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: ColorUtils.hexToColor(_hoveredEventInfo!.event.schedule.colorHex),
                                width: 5,
                              ),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: <Widget>[
                              FusionAppText(
                                text: _hoveredEventInfo?.event.title ?? "----",
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              FusionAppText(
                                text: "Scheduled at ${DateFormat('dd MMM yyyy, hh:mm a').format(_hoveredEventInfo?.event.startTime ?? DateTime.now())}",
                                style: theme.textTheme.bodySmall,
                              ),

                              FusionTextButton(
                                label: "",
                                prefixIcon: Icons.edit,
                                showPrefixIcon: true,
                                width: 50,
                                height: 25,
                                onTap: () {
                                  SchedulerForm.show(context, context.read<SchedulerViewmodel>(), initial: _hoveredEventInfo?.event.schedule);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pinned date labels (top row), scroll horizontally only
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            height: dayLabelHeight,
            child: Stack(
              children: <Widget>[
                for (int i = 1; i <= daysInMonth; i++)
                  Positioned(
                    top: 10,
                    left: hourLabelWidth + ((i - 1) * dayWidth) - (_horizontalController.hasClients ? _horizontalController.offset : 0),
                    child: Container(
                      width: dayWidth,
                      height: dayLabelHeight,
                      decoration: BoxDecoration(
                        // color: Colors.red,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          left: BorderSide(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: Text(
                        ' ${DateFormat('MMM d').format(DateTime(widget.viewingMonth.year, widget.viewingMonth.month, i))}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Pinned time labels (left column), scroll vertically only
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            width: hourLabelWidth,
            child: Stack(
              children: <Widget>[
                for (int i = 0; i < 24; i++)
                  Positioned(
                    top: dayLabelHeight + (i * hourHeight) - (_verticalController.hasClients ? _verticalController.offset : 0),
                    left: 10,
                    height: hourHeight,
                    width: hourLabelWidth - 20,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i.toString().padLeft(2, '0')}:00',
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
          width: hourLabelWidth,
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
    required this.dayWidth,
    required this.hourHeight,
    required this.theme,
  });
  final int daysInMonth;
  final double hourLabelWidth;
  final double dayLabelHeight;
  final double dayWidth;
  final double hourHeight;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.grey.shade300;

    // Draw vertical lines
    for (int i = 0; i <= daysInMonth; i++) {
      final double x = hourLabelWidth + (i * dayWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= 24; i++) {
      final double y = dayLabelHeight + (i * hourHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class HoveredEventInfo {
  final CalendarEvent event;
  final Offset position;
  final Size size;
  HoveredEventInfo({
    required this.event,
    required this.position,
    required this.size,
  });
}
