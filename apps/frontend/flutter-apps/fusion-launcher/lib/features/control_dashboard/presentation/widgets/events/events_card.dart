import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/entitity/event_item_entity.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'events_dashboard.dart';

class EventCard extends StatelessWidget {
  final EventItemEntity item;
  final EventTab type;
  final Function(bool)? onToggle;
  final VoidCallback? onClose;

  const EventCard({
    super.key,
    required this.item,
    required this.type,
    this.onToggle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.accentColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: <Widget>[
                    // Time Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FusionAppText(
                          text: "${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}",
                          style: context.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              // Simple logic to choose sun or moon icon
                              item.time.hour < 12 ? Icons.wb_twilight : Icons.wb_sunny_outlined,
                              color: Colors.grey,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            FusionAppText(
                              text: item.time.hour < 12 ? "AM" : "PM",
                              style: context.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Vertical Divider
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: context.colorScheme.strokeLight,
                    ),

                    // Title & Location
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: item.title,
                            style: context.textTheme.labelLarge,
                            textOverflow: TextOverflow.ellipsis,
                            maxLine: 1,
                          ),
                          const SizedBox(height: 4),
                          FusionAppText(
                            text: item.eventName,
                            style: context.textTheme.labelMedium!.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                            textOverflow: TextOverflow.ellipsis,
                            maxLine: 1,
                          ),
                        ],
                      ),
                    ),

                    // Action Button (Toggle or Close)
                    if (type == EventTab.scheduled)
                      FusionSwitch(
                        height: 22,
                        width: 36,
                        value: item.isEnabled,
                        onChanged: (bool val) {
                          onToggle?.call(val);
                        },
                      )
                    else
                      FusionContainer(
                        borderRadius: 8,
                        color: context.colorScheme.elevation2,
                        raised: true,
                        child: GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
