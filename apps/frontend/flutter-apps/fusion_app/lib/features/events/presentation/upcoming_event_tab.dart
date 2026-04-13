
import 'package:flutter/material.dart';
import 'package:fusion_app/features/events/models/event_model.dart';
import 'package:fusion_app/features/events/widgets/event_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';

class UpcomingEventsScreen extends StatelessWidget {
  final List<EventModel> events;
  final bool showTrailingIcon;
  const UpcomingEventsScreen({required this.events,required this.showTrailingIcon,super.key});

  @override
  Widget build(BuildContext context) {
    final upcomingEvents =
    events.where((e) => !e.enabled).toList();
    if(events.isEmpty){
      return CommonEmptyState(
        icon: Icons.edit_calendar,
        title: "No Scheduled Events",
        subtitle:"You're all caught up!",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: upcomingEvents.length,
      itemBuilder: (context, index) {
        final event = upcomingEvents[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventCard(
            showTrailingIcon:showTrailingIcon,
            event: event,
          ),
        );
      },
    );
  }
}
