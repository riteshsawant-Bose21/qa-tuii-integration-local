import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/devices/dashboard_device_listing.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../devices/presentation/pages/device_listing_page.dart';
import '../widgets/dashboard_scroll_wrapper.dart';
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
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: <Widget>[
                                  _buildHeader("MEDIA PLAYER", "View All"),
                                  const SizedBox(height: 16),
                                  _buildMediaCard("Morning Vibes", "Now playing", true),
                                  const SizedBox(height: 12),
                                  _buildMediaCard("Beast Mode", "", false),
                                ],
                              ),
                            ),
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

  // --- MEDIA & EVENT CARDS ---

  Widget _buildMediaCard(String title, String status, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(color: isPlaying ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.equalizer, color: Colors.grey, size: 20), // Placeholder for waveform
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (status.isNotEmpty) Text(status, style: const TextStyle(color: Colors.green, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.tune, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  // --- UPDATED EVENT CARD TO MATCH REFERENCE IMAGE ---

  Widget _buildEventCard(String title, String date, bool isAction) {
    // Theme colors matching the dashboard
    const Color cardColor = Color(0xFF222222);
    const Color accentColor = Color(0xFF4CAF50); // Green accent
    const Color textColor = Colors.white;
    const MaterialColor subTextColor = Colors.grey;

    return Container(
      // The main card background and rounding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      // Clip behavior ensures the accent bar doesn't bleed out of rounded corners
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        // Ensures the row stretches to fit the tallest element
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. The Vertical Accent Bar
            Container(
              width: 4,
              color: accentColor,
            ),

            // 2. Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Title and Edit Icon Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(title, style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        // Neumorphic Edit Icon (using your existing wrapper if available)
                        // Or standard icon for now:
                        FusionNeumorphicButton(
                          width: 26,
                          height: 26,
                          borderRadius: 6,
                          onTap: () {
                            // Handle click action here
                            print("Clicked Edit Event");
                          },
                          child: const Icon(Icons.mode_edit_outlined, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Date / Subtitle
                    Text(date, style: const TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w400)),

                    // Action Buttons (only if isAction is true)
                    if (isAction) ...<Widget>[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FusionNeumorphicButton(
                            width: 100,
                            height: 26,
                            borderRadius: 6,
                            onTap: () {
                              // Handle click action here
                              print("Clicked Run Now");
                            },
                            child: _buildTextActionButton("Run Now", Colors.white),
                          ),
                          const SizedBox(width: 16),
                          _buildTextActionButton("Cancel", subTextColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New helper for the subtle text-based action buttons
  Widget _buildTextActionButton(String label, Color color) {
    return InkWell(
      onTap: () {}, // Add action handler
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
