import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Header row for the week day labels in the Schedule List.
/// Displays the abbreviated names of the days of the week in a row with styling.
class WeekDayRowHeader extends StatelessWidget {
  const WeekDayRowHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> days = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Row(
        spacing: 4,
        children:
            days
                .map(
                  (String day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                      ),
                      child: FusionAppText(
                        text: day,
                        textAlign: TextAlign.center,
                        style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
