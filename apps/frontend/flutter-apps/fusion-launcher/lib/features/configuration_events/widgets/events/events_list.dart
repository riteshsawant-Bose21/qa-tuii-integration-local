import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';
import 'event_item_card.dart';

class EventList extends StatelessWidget {
  final List<FusionEvent> eventList;
  final ConfigEventsViewmodel cubit;

  final Function(String eventId) onDelete;
  final Function(String eventId)? onSelect;
  final Function(String eventId)? onSwitchChanged;

  final String? selectedEventId;
  final Function(int oldIndex, int newIndex)? onReorder;

  const EventList({
    super.key,
    required this.eventList,
    required this.onDelete,
    this.onSelect,
    this.selectedEventId,
    this.onReorder,
    this.onSwitchChanged,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (eventList.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return FadeTransition(
          opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        );
      },
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shrinkWrap: false,
      itemCount: eventList.length,
      onReorder: (int oldIndex, int newIndex) {
        if (onReorder != null) {
          onReorder!(oldIndex, newIndex);
        }
      },
      itemBuilder: (BuildContext context, int index) {
        final FusionEvent eventData = eventList[index];

        return Container(
          key: ValueKey<String>(eventData.id),
          margin: const EdgeInsets.only(bottom: 4),
          child: EventItemCard(
            index: index,
            cubit: cubit,
            eventData: eventData,
            isSelected: selectedEventId == eventData.id,
            onSwitchChanged: (String eventId) {
              if (onSwitchChanged != null) {
                onSwitchChanged!(eventData.id);
              }
            },
            onDelete: () {
              onDelete(eventData.id);
            },
            onTap: () {
              if (onSelect != null) {
                onSelect!(eventData.id);
              }
            },
          ),
        );
      },
    );
  }
}
