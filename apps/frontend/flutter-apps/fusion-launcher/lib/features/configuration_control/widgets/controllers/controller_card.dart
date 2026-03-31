import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Card widget displaying a single controller with its zones
class ControllerCard extends StatelessWidget {
  final FusionController controller;
  final bool isSelected;
  final List<Zone> zones;
  final Map<String, List<SubZone>> subZonesInZones;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ControllerCard({
    super.key,
    required this.controller,
    this.isSelected = false,
    this.zones = const <Zone>[],
    this.subZonesInZones = const <String, List<SubZone>>{},
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? context.colorScheme.primary : context.colorScheme.elevation2,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Controller name and menu
            Row(
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: controller.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildMenuButton(context),
              ],
            ),
            const SizedBox(height: 8),

            /// Zones list
            ..._buildZonesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: FusionIcon.icon(
        Icons.more_vert,
        size: 16,
        color: context.colorScheme.iconDefault,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: <Widget>[
                  Icon(Icons.delete_outline, size: 16, color: context.colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: context.colorScheme.error)),
                ],
              ),
            ),
          ],
      onSelected: (String value) {
        if (value == 'delete') {
          onDelete?.call();
        }
      },
    );
  }

  List<Widget> _buildZonesList(BuildContext context) {
    // Show zones associated with this controller
    // For now, showing a few sample zones from the project
    final List<Zone> displayZones = zones.take(3).toList();

    return displayZones.map((Zone zone) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: zone.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FusionAppText(
                text: zone.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
