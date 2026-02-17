import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../entitity/event_item_entity.dart';
import 'events_card.dart';

enum EventTab { scheduled, upcoming }

class EventsDashboard extends StatefulWidget {
  const EventsDashboard({super.key});

  @override
  State<EventsDashboard> createState() => _EventsDashboardState();
}

class _EventsDashboardState extends State<EventsDashboard> {
  // State to track which tab is active
  EventTab _currentTab = EventTab.scheduled;

  List<EventItemEntity> get scheduledEvents {
    return serviceLocator<ProjectViewModel>().getAllScheduledEvents();
  }

  List<EventItemEntity> get upcomingEvents {
    return serviceLocator<ProjectViewModel>().getAllUpcomingEvents();
  }

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
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          // TODO: implement listener
        },
        builder: (BuildContext context, ProjectViewModelState state) {
          return Column(
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
                  itemCount: _currentTab == EventTab.scheduled ? scheduledEvents.length : upcomingEvents.length,
                  separatorBuilder: (BuildContext ctx, int index) => const SizedBox(height: 16),
                  itemBuilder: (BuildContext context, int index) {
                    final EventItemEntity item = _currentTab == EventTab.scheduled ? scheduledEvents[index] : upcomingEvents[index];

                    return EventCard(
                      item: item,
                      type: _currentTab,
                      onToggle: (bool val) {
                        serviceLocator<ProjectViewModel>().toggleEvent(eventId: item.eventId, isEnabled: val);
                      },
                      onClose: () {
                        _showEventCancelConfirmation(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEventCancelConfirmation(BuildContext context, EventItemEntity event) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => FusionConfirmationPopup(
            title: 'SKIP EVENT',
            description: 'Do you want to skip upcoming event ${event.title} ?',
            onConfirm: () {},
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
