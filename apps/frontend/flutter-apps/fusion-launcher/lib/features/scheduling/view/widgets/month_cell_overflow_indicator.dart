import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/event_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:intl/intl.dart';

class MonthCellOverflowIndicator extends StatelessWidget {
  final int overflowCount;
  final List<CalendarEvent> allEvents;
  final DateTime date;

  const MonthCellOverflowIndicator({
    super.key,
    required this.overflowCount,
    required this.allEvents,
    required this.date,
  });

  Widget _buildPopupContent(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Header row: date + close button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: <Widget>[
                FusionAppText(
                  text: DateFormat('d EEE, MMMM').format(date),
                  style: context.textTheme.b3SemiBold,
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(
                      semanticId: 'close_overflow_popup',
                      Icons.close,
                      size: 18,
                      color: context.colorScheme.iconDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// All events list
          ...allEvents.map((CalendarEvent event) => EventCard(event: event)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget indicator = Container(
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FusionIcon.icon(
            semanticId: 'month_cell_overflow_icon',
            Icons.add,
            size: 16,
            color: context.colorScheme.iconDefault,
          ),
          const SizedBox(width: 4),
          FusionAppText(
            text: '$overflowCount more',
            style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
          ),
        ],
      ),
    );

    return FusionArrowPopup(
      semanticId: 'month_cell_overflow_popup',
      backgroundColor: context.colorScheme.elevation2,
      barrierColor: Colors.black54,

      content: Builder(
        builder: (BuildContext ctx) => _buildPopupContent(ctx),
      ),
      child: indicator,
    );
  }
}
