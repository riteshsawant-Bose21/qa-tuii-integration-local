import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/event_card.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/month_cell_overflow_indicator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import '../../viewmodel/scheduler_viewmodel.dart';
import '../sections/scheduler_form.dart';

class MonthDayCell extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final Map<DateTime, List<CalendarEvent>> eventsByDate;

  const MonthDayCell({super.key, required this.date, required this.isCurrentMonth, required this.eventsByDate});

  @override
  State<MonthDayCell> createState() => _MonthDayCellState();
}

class _MonthDayCellState extends State<MonthDayCell> {
  late final ValueNotifier<bool> _hoveredEventNotifier;

  @override
  void initState() {
    super.initState();
    _hoveredEventNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _hoveredEventNotifier.dispose();
    super.dispose();
  }

  List<CalendarEvent> _eventsFor(DateTime date) {
    final DateTime key = DateTime(date.year, date.month, date.day);
    return widget.eventsByDate[key] ?? <CalendarEvent>[];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final bool isToday = widget.date.year == today.year && widget.date.month == today.month && widget.date.day == today.day;

    final List<CalendarEvent> events = _eventsFor(widget.date);
    const int maxVisible = 2;

    return GestureDetector(
      onTap: () => SchedulerForm.show(context, context.read<SchedulerViewmodel>()),
      child: MouseRegion(
        onEnter: (_) => _hoveredEventNotifier.value = true,
        onExit: (_) => _hoveredEventNotifier.value = false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday ? context.colorScheme.primary : context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Stack(
            children: <Widget>[
              /// Main content column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Day number
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child:
                        isToday
                            ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: context.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: FusionAppText(text: '${widget.date.day}', style: context.textTheme.b3SemiBold),
                            )
                            : FusionAppText(
                              text: '${widget.date.day}',
                              style: context.textTheme.b3Medium.withColor(
                                widget.isCurrentMonth ? context.colorScheme.textBody : context.colorScheme.textDisabled,
                              ),
                            ),
                  ),

                  const SizedBox(height: 8),

                  /// Event cards
                  ...events.take(maxVisible).map((CalendarEvent event) => EventCard(event: event)),

                  /// Overflow indicator
                  if (events.length > maxVisible)
                    MonthCellOverflowIndicator(
                      overflowCount: events.length - maxVisible,
                      allEvents: events,
                      date: widget.date,
                    ),
                ],
              ),

              ValueListenableBuilder<bool>(
                valueListenable: _hoveredEventNotifier,
                builder: (BuildContext context, bool isHovered, Widget? child) {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !isHovered,
                      child: AnimatedOpacity(
                        opacity: isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () => SchedulerForm.show(context, context.read<SchedulerViewmodel>()),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation3,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                FusionIcon.icon(
                                  semanticId: 'add_schedule_icon',
                                  Icons.add,
                                  size: 16,
                                  color: context.colorScheme.iconDefault,
                                ),
                                const SizedBox(width: 6),
                                FusionAppText(
                                  text: 'Add Schedule',
                                  style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
