import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/devices/dashboard_device_listing.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../devices/presentation/pages/device_listing_page.dart';
import '../widgets/dashboard_scroll_wrapper.dart';
import '../widgets/message_player/message_player_widget.dart';
import '../widgets/zones/zone_dashboard.dart';

class FusionControlDashboardPage extends StatelessWidget {
  const FusionControlDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color bgBlack = context.colorScheme.primaryBlack;
    final Color cardDark = context.colorScheme.elevation1;

    return Scaffold(
      backgroundColor: bgBlack,
      body: DashboardScrollWrapper(
        minWidth: 1280, // Set this to the ideal width of your design
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ---------------------------------------------------------
              // LEFT COLUMN (Devices + Media + Events) - Flex 6
              // ---------------------------------------------------------
              Expanded(
                flex: 6,
                child: Column(
                  children: <Widget>[
                    // 1. DEVICES PANEL (Top Left)
                    const Expanded(
                      flex: 3,
                      child: DashboardDeviceListing(),
                    ),
                    const SizedBox(height: 16),

                    // 2. BOTTOM ROW (Media + Events)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          // MEDIA PLAYER
                          const Expanded(
                            child: MessagePlayerWidget(),
                          ),
                          const SizedBox(width: 16),
                          // UPCOMING EVENTS
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: <Widget>[
                                  _buildHeader("UPCOMING EVENTS", "View All"),
                                  // const SizedBox(height: 16),
                                  // _buildEventCard("System Shutdown", "TODAY / 24 JULY, 2025 / 5:00PM", true),
                                  // const SizedBox(height: 12),
                                  // _buildEventCard("StartUP", "EVERYDAY / 24 JULY, 2025 / 5:00PM", false),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ---------------------------------------------------------
              // MIDDLE COLUMN (ZONES) - Flex 4
              // ---------------------------------------------------------
              const Expanded(
                flex: 4,
                child: ZoneDashboard(),
              ),

              const SizedBox(width: 16),

              // ---------------------------------------------------------
              // RIGHT COLUMN (ALERTS) - Flex 3
              // ---------------------------------------------------------
              const Expanded(
                flex: 3,
                child: NotificationSidebar(), // Reusing your existing widget
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        if (action.isNotEmpty) Text(action, style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.underline)),
      ],
    );
  }
}
