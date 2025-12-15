import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'event_item_card.dart';

class EventList extends StatelessWidget {
  final List<FusionEvent> eventList;
  final Function(String eventId) onDelete;
  final Function(String eventId)? onSelect;
  final String? selectedEventId;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String eventId)? onDragStarted;
  final VoidCallback? onDragEnd;

  const EventList({
    super.key,
    required this.eventList,
    required this.onDelete,
    this.onSelect,
    this.selectedEventId,
    this.onReorder,
    this.onDragStarted,
    this.onDragEnd,
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
            color: Colors.white,
            child: child,
          ),
        );
      },
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
          child: Draggable<FusionEvent>(
            data: eventData,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: () {
              if (onDragStarted != null) {
                onDragStarted!(eventData.id);
              }
            },
            onDraggableCanceled: (_, __) {
              if (onDragEnd != null) {
                onDragEnd!();
              }
            },
            onDragEnd: (_) {
              if (onDragEnd != null) {
                onDragEnd!();
              }
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  maxHeight: 36,
                ),
                child: Opacity(
                  opacity: 0.8,
                  child: EventItemCard(
                    index: index,
                    eventData: eventData,
                    isSelected: selectedEventId == eventData.id,
                    onDelete: () {
                      onDelete(eventData.id);
                    },
                    onTap: () {
                      if (onSelect != null) {
                        onSelect!(eventData.id);
                      }
                    },
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: EventItemCard(
                index: index,
                eventData: eventData,
                isSelected: selectedEventId == eventData.id,
                onDelete: () {
                  onDelete(eventData.id);
                },
                onTap: () {
                  if (onSelect != null) {
                    onSelect!(eventData.id);
                  }
                },
              ),
            ),
            child: EventItemCard(
              index: index,
              eventData: eventData,
              isSelected: selectedEventId == eventData.id,
              onDelete: () {
                onDelete(eventData.id);
              },
              onTap: () {
                if (onSelect != null) {
                  onSelect!(eventData.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
