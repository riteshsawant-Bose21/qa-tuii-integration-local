import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'alerts_card.dart';

// --- 1. Data Models ---

enum AlertType { critical, warning }

class AlertItem {
  final String title;
  final String description;
  final String time;
  final String deviceId;
  final String location;
  final AlertType type;

  AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.deviceId,
    required this.location,
    required this.type,
  });
}

// --- 2. Main Screen ---

class AlertsDashboard extends StatefulWidget {
  const AlertsDashboard({super.key});

  @override
  State<AlertsDashboard> createState() => _AlertsDashboardState();
}

class _AlertsDashboardState extends State<AlertsDashboard> {
  // State for filtering
  bool _showCriticalOnly = false;

  // Sample Data
  final List<AlertItem> _allAlerts = <AlertItem>[
    AlertItem(
      title: "Open Circuit Fault Channel...",
      description: "Zone: Reception, Circuit: DM5S",
      time: "10:00 PM",
      deviceId: "PSM8300-1",
      location: "Reception",
      type: AlertType.critical,
    ),
    AlertItem(
      title: "High Temperature Warning",
      description: "High Temperature Warning",
      time: "10:00 PM",
      deviceId: "PSM8300-1",
      location: "Equipment Location",
      type: AlertType.warning,
    ),
    AlertItem(
      title: "Battery Low Voltage",
      description: "Backup battery requires replacement",
      time: "09:45 PM",
      deviceId: "PSM8300-2",
      location: "Server Room",
      type: AlertType.warning,
    ),
    AlertItem(
      title: "Fire Alarm Triggered",
      description: "Smoke detected in Hallway B",
      time: "08:15 PM",
      deviceId: "FA-202",
      location: "Hallway B",
      type: AlertType.critical,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    ;

    // Filter the list based on selection
    final List<AlertItem> displayedAlerts = _showCriticalOnly ? _allAlerts.where((AlertItem item) => item.type == AlertType.critical).toList() : _allAlerts;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardSectionHeader(title: "ALERTS & NOTIFICATIONS"),
          // --- Filter Tabs ---
          Row(
            children: <Widget>[
              _buildFilterButton("All Notifications", false),
              const SizedBox(width: 16),
              _buildFilterButton("Critical", true),
            ],
          ),
          const SizedBox(height: 24),

          // --- Section Header (Today + Count) ---
          Row(
            children: <Widget>[
              FusionAppText(
                text: "Today",
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FusionAppText(
                  text: displayedAlerts.length.toString(),
                  style: context.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Alert List ---
          Expanded(
            child: ListView.separated(
              itemCount: displayedAlerts.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return AlertCard(item: displayedAlerts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the top tabs
  Widget _buildFilterButton(String label, bool isCriticalFilter) {
    // Determine if this button is currently active
    final bool isActive = _showCriticalOnly == isCriticalFilter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showCriticalOnly = isCriticalFilter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FusionAppText(
          text: label,
          style: context.textTheme.labelMedium!.copyWith(
            color: isActive ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
