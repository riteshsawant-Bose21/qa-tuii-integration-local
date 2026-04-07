import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/scheduled_items_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/schedule_vc_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Schedule tab — two-column layout.
/// State is owned by [ConfigurationControlViewmodel] so it survives tab switches.
class SchedulePanel extends StatelessWidget {
  const SchedulePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.elevation1,
      padding: const EdgeInsets.all(16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Left: SCHEDULED ITEMS filter panel
          Expanded(flex: 3, child: ScheduledItemsPanel()),
          SizedBox(width: 16),

          /// Right: VIRTUAL CONTROLLER events card
          Expanded(flex: 5, child: ScheduleVcPanel()),
        ],
      ),
    );
  }
}
