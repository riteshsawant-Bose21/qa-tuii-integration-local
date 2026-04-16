import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';

import 'month_day_cell.dart';

class MonthGrid extends StatelessWidget {
  final DateTime viewingMonth;
  final Map<DateTime, List<CalendarEvent>> eventsByDate;

  const MonthGrid({super.key, required this.viewingMonth, required this.eventsByDate});

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(viewingMonth.year, viewingMonth.month, 1);

    /// Calculate total cells needed (including leading empty cells)
    final int startOffset = first.weekday % 7;
    final int daysInMonth = DateUtils.getDaysInMonth(
      viewingMonth.year,
      viewingMonth.month,
    );
    final int totalCells = startOffset + daysInMonth;
    final int rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        spacing: 4,
        children: List<Widget>.generate(rows, (int row) {
          return Expanded(
            child: Row(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(7, (int col) {
                final int cellIndex = row * 7 + col;
                final int dayNum = cellIndex - startOffset + 1;

                DateTime cellDate;
                bool isCurrentMonth = true;

                if (dayNum < 1) {
                  /// Days from previous month
                  final DateTime prevMonth = DateTime(
                    viewingMonth.year,
                    viewingMonth.month - 1,
                  );
                  final int daysInPrev = DateUtils.getDaysInMonth(
                    prevMonth.year,
                    prevMonth.month,
                  );
                  cellDate = DateTime(prevMonth.year, prevMonth.month, daysInPrev + dayNum);
                  isCurrentMonth = false;
                } else if (dayNum > daysInMonth) {
                  /// Days from next month
                  cellDate = DateTime(
                    viewingMonth.year,
                    viewingMonth.month + 1,
                    dayNum - daysInMonth,
                  );
                  isCurrentMonth = false;
                } else {
                  cellDate = DateTime(
                    viewingMonth.year,
                    viewingMonth.month,
                    dayNum,
                  );
                }

                return Expanded(
                  child: MonthDayCell(date: cellDate, isCurrentMonth: isCurrentMonth, eventsByDate: eventsByDate),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
