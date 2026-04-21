import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/month_grid.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'WeekDayHeader.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'timeline_calender_view'),
      child: Column(
        children: <Widget>[
          /// Month and Year Header
          const WeekDayRowHeader(),
          const SizedBox(height: 4),

          /// Month Grid
          Expanded(child: MonthGrid(viewingMonth: widget.viewingMonth, eventsByDate: widget.eventsByDate)),
        ],
      ),
    );
  }
}
