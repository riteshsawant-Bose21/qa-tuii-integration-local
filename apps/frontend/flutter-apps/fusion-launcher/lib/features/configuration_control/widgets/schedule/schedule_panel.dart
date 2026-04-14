import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/scheduled_items_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/schedule_vc_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Schedule tab — two-column layout.
class SchedulePanel extends StatelessWidget {
  /// The name of the currently selected controller, shown as event subtitle.
  final String controllerName;

  const SchedulePanel({super.key, this.controllerName = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.elevation1,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Left: SCHEDULED ITEMS filter panel
          const Expanded(flex: 3, child: ScheduledItemsPanel()),
          const SizedBox(width: 16),

          /// Right: VIRTUAL CONTROLLER events card
          Expanded(flex: 5, child: ScheduleVcPanel(controllerName: controllerName)),
        ],
      ),
    );
  }
}
