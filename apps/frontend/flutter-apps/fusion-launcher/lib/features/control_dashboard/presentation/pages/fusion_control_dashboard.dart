import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../devices/presentation/pages/device_listing_page.dart';
import '../../../devices/presentation/widgets/themostat_painter.dart';
import '../widgets/dashboard_scroll_wrapper.dart';
import '../widgets/zones/zone_dashboard.dart';

class FusionControlDashboardPage extends StatelessWidget {
  const FusionControlDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF000000);
    const Color cardDark = Color(0xFF111111);

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
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: <Widget>[
                            _buildHeader("DEVICES", "View All"),
                            const SizedBox(height: 16),
                            _buildTableHeader(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "Equipment Location",
                                    temp: 33,
                                    cpu: 0.92,
                                    disk: 0.92,
                                    alertMsg: "Open Circuit Fault Channel: 3 , Zone: Reception, Circuit: DM5SE",
                                    isCritical: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "model name",
                                    temp: 46,
                                    cpu: 0.92,
                                    disk: 0.71,
                                    alertMsg: "High Temperature Warning",
                                    isWarning: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "Equipment Location",
                                    temp: 21,
                                    cpu: 0.43,
                                    disk: 0.43,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(name: "Powersmart 8300", location: "Equipment Location", isOffline: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // --- DEVICE PANEL WIDGETS ---
  Widget _buildTableHeader() {
    const TextStyle headerStyle = TextStyle(color: Color(0xFF616161), fontSize: 10, fontWeight: FontWeight.bold);

    return const Padding(
      // MATCHED PADDING: Matches the internal padding of _buildDeviceRow (12.0)
      // plus the border width (1.0) to line up text perfectly.
      padding: EdgeInsets.symmetric(horizontal: 13.0),
      child: Row(
        children: <Widget>[
          // FLEX 4: Device Name
          Expanded(flex: 4, child: Text("DEVICE NAME", style: headerStyle)),
          // FLEX 2: Temp
          Expanded(flex: 2, child: Text("TEMP", style: headerStyle)),
          // FLEX 2: CPU
          Expanded(flex: 2, child: Text("CPU", style: headerStyle)),
          // FLEX 2: Disk
          Expanded(flex: 2, child: Text("DISK", style: headerStyle)),
          // FLEX 2: Controls
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("CONTROLS", style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildDeviceRow({
    required String name,
    required String location,
    double temp = 0,
    double cpu = 0,
    double disk = 0,
    String? alertMsg,
    bool isCritical = false,
    bool isWarning = false,
    bool isOffline = false,
  }) {
    final Color bgColor = (isCritical || isWarning) ? const Color(0xFF1E1E1E) : const Color(0xFF161616);
    final Color borderColor = Colors.white.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            // PADDING: 12.0 horizontal (Matches Header's effective padding)
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: <Widget>[
                // 1. Device Info (FLEX 4 - MATCHES HEADER)
                Expanded(
                  flex: 4,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
                        child: const Icon(Icons.router, color: Colors.white54, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Metrics (FLEX 2 EACH - MATCHES HEADER)
                Expanded(
                  flex: 2,
                  child:
                      isOffline
                          ? _buildDash()
                          : Align(
                            alignment: Alignment.centerLeft,
                            child: CompactThermostatWidget(temperature: temp.toInt(), maxTemperature: 100),
                          ),
                ),
                Expanded(
                  flex: 2,
                  child: isOffline ? _buildDash() : UsageMeterWidget(value: cpu, label: "${(cpu * 100).toInt()}%", color: _getUsageColor(cpu)),
                ),
                Expanded(
                  flex: 2,
                  child: isOffline ? _buildDash() : UsageMeterWidget(value: disk, label: "${(disk * 100).toInt()}%", color: _getUsageColor(disk)),
                ),

                // 3. Controls (FLEX 2 - MATCHES HEADER)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _buildMiniControl(Icons.settings_power),
                      const SizedBox(width: 10),
                      _buildMiniControl(Icons.refresh),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alert Banner code remains same...
          if (alertMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCritical ? const Color(0xFF3E1A1A) : const Color(0xFF3E2E1A),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                    color: isCritical ? const Color(0xFFE57373) : const Color(0xFFFFB74D),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertMsg,
                      style: TextStyle(color: isCritical ? const Color(0xFFE57373) : const Color(0xFFFFB74D), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDash() => const Align(alignment: Alignment.centerLeft, child: Text("-", style: TextStyle(color: Colors.grey)));

  Widget _buildMiniControl(IconData icon) {
    return FusionNeumorphicButton(
      width: 26,
      height: 26,
      borderRadius: 6,
      onTap: () {
        // Handle click action here
        print("Clicked $icon");
      },
      child: Icon(
        icon,
        size: 13,
        color: const Color(0xFF888888),
      ),
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

  Color _getUsageColor(double val) {
    if (val < 0.5) return const Color(0xFF4CAF50);
    if (val < 0.8) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _getZoneColor(String name) {
    if (name.contains("1")) return const Color(0xFF5C6BC0);
    if (name.contains("2")) return const Color(0xFFEF5350);
    if (name.contains("3")) return const Color(0xFFFFCA28);
    return const Color(0xFF66BB6A);
  }
}
