import 'package:flutter/material.dart';
import 'package:fusion_app/features/events/models/event_model.dart';
import 'package:fusion_app/features/events/widgets/event_item_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';

class ScheduledEventsScreen extends StatelessWidget {
  final List<EventModel> events;
  const ScheduledEventsScreen({required this.events,super.key});

  @override
  Widget build(BuildContext context) {

    if(events.isEmpty){
      return CommonEmptyState(
        icon: Icons.edit_calendar,
        title: "No Scheduled Events",
        subtitle:"You're all caught up!",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return EventCard(
         event: event,
        );
      },separatorBuilder: (context, index) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 16));
    }
    );
  }
}
