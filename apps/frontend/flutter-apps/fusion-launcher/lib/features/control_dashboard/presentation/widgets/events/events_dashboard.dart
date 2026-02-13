import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'events_card.dart';

// --- 1. Data Models ---

enum EventTab { scheduled, upcoming }

class EventItem {
  final String time;
  final String period; // AM or PM
  final String title;
  final String location;
  final Color accentColor;
  bool isEnabled; // For the toggle switch

  EventItem({
    required this.time,
    required this.period,
    required this.title,
    required this.location,
    required this.accentColor,
    this.isEnabled = true,
  });
}

// --- 2. Main Screen ---

class EventsDashboard extends StatefulWidget {
  const EventsDashboard({super.key});

  @override
  State<EventsDashboard> createState() => _EventsDashboardState();
}

class _EventsDashboardState extends State<EventsDashboard> {
  // State to track which tab is active
  EventTab _currentTab = EventTab.scheduled;

  // Sample Data for "Scheduled"
  final List<EventItem> _scheduledEvents = <EventItem>[
    EventItem(
      time: "06:00",
      period: "AM",
      title: "Yoga Session",
      location: "Studio Gold",
      accentColor: const Color(0xFF2E8BFF),
      // Blue
      isEnabled: true,
    ),
    EventItem(
      time: "08:00",
      period: "AM",
      title: "Cardio Session",
      location: "Studio Gold",
      accentColor: const Color(0xFFFF6B4A),
      // Orange
      isEnabled: true,
    ),
    EventItem(
      time: "10:00",
      period: "AM",
      title: "Gym Session",
      location: "Studio Gold",
      accentColor: const Color(0xFF00C853),
      // Green
      isEnabled: true,
    ),
    EventItem(
      time: "04:00",
      period: "PM",
      title: "Yoga Session",
      location: "Studio Gold",
      accentColor: const Color(0xFF2E8BFF),
      // Blue
      isEnabled: false,
    ),
  ];

  // Sample Data for "Upcoming"
  final List<EventItem> _upcomingEvents = <EventItem>[
    EventItem(
      time: "06:00",
      period: "AM",
      title: "Yoga Session",
      location: "Studio Gold",
      accentColor: const Color(0xFF2E8BFF),
    ),
    EventItem(
      time: "08:00",
      period: "AM",
      title: "Cardio Session",
      location: "Studio Gold",
      accentColor: const Color(0xFFFF6B4A),
    ),
    EventItem(
      time: "11:30",
      period: "AM",
      title: "Yoga Session",
      location: "Studio Gold",
      accentColor: const Color(0xFFD500F9), // Purple
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardSectionHeader(
            title: "EVENTS",
          ),

          // Custom Tab Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildTabButton("Scheduled", EventTab.scheduled),
                ),
                const SizedBox(width: 16), // Gap between buttons
                Expanded(
                  child: _buildTabButton("Upcoming", EventTab.upcoming),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List of Cards
          Expanded(
            child: ListView.separated(
              itemCount: _currentTab == EventTab.scheduled ? _scheduledEvents.length : _upcomingEvents.length,
              separatorBuilder: (BuildContext ctx, int index) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final EventItem item = _currentTab == EventTab.scheduled ? _scheduledEvents[index] : _upcomingEvents[index];

                return EventCard(
                  item: item,
                  type: _currentTab,
                  onToggle: (bool val) {
                    setState(() {
                      item.isEnabled = val;
                    });
                  },
                  onClose: () {
                    // Logic to remove item
                    setState(() {
                      _upcomingEvents.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, EventTab tab) {
    final bool isActive = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: context.colorScheme.elevation2), // Subtle border for inactive
        ),
        alignment: Alignment.center,
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
