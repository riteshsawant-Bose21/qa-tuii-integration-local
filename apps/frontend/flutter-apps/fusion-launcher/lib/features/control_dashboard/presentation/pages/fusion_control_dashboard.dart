import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/devices/dashboard_device_listing.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/alerts/alerts_dashboard.dart';
import '../widgets/dashboard_scroll_wrapper.dart';
import '../widgets/events/events_dashboard.dart';
import '../widgets/message_player/message_player_widget.dart';
import '../widgets/zones/zone_dashboard.dart';

class FusionControlDashboardPage extends StatelessWidget {
  const FusionControlDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color bgBlack = context.colorScheme.primaryBlack;

    return Scaffold(
      backgroundColor: bgBlack,
      body: const DashboardScrollWrapper(
        minWidth: 1280, // Set this to the ideal width of  design
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // LEFT COLUMN (Devices + Media + Events) - Flex 6
              Expanded(
                flex: 6,
                child: Column(
                  children: <Widget>[
                    // 1. DEVICES PANEL (Top Left)
                    Expanded(
                      flex: 3,
                      child: DashboardDeviceListing(),
                    ),
                    SizedBox(height: 16),

                    // 2. BOTTOM ROW (Media + Events)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          // MEDIA PLAYER
                          Expanded(
                            child: MessagePlayerWidget(),
                          ),
                          SizedBox(width: 16),
                          // UPCOMING EVENTS
                          Expanded(
                            child: EventsDashboard(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // MIDDLE COLUMN (ZONES) - Flex 4
              Expanded(
                flex: 4,
                child: ZoneDashboard(),
              ),

              SizedBox(width: 16),

              // RIGHT COLUMN (ALERTS) - Flex 3
              Expanded(
                flex: 3,
                child: AlertsDashboard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
