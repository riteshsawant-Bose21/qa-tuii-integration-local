import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Header row for the week day labels.
/// When [dates] is provided (week view) each cell also shows the date number,
/// with today's cell highlighted in the primary colour.
class WeekDayRowHeader extends StatelessWidget {
  /// The 7 dates (Sun → Sat) for the currently displayed week.
  /// Pass `null` (or omit) to render the plain month-view header (day names only).
  final List<DateTime>? dates;

  const WeekDayRowHeader({super.key, this.dates});

  static const List<String> _dayNames = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Row(
        spacing: 4,
        children: List<Widget>.generate(7, (int i) {
          final String dayName = _dayNames[i];
          final DateTime? date = dates?[i];
          final bool isToday = date != null && date.year == today.year && date.month == today.month && date.day == today.day;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday ? context.colorScheme.primary : context.colorScheme.strokeLight,
                  width: 1,
                ),
              ),
              child:
                  date == null
                      // ── Month view: day name only ───────────────────────────
                      ? FusionAppText(
                        text: dayName,
                        textAlign: TextAlign.center,
                        style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                      )
                      // ── Week view: day name + date number ──────────────────
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FusionAppText(
                            text: dayName,
                            style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday ? context.colorScheme.primary : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: FusionAppText(
                              text: '${date.day}',
                              style: context.textTheme.l1Regular.withColor(
                                isToday ? Colors.white : context.colorScheme.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          );
        }),
      ),
    );
  }
}
