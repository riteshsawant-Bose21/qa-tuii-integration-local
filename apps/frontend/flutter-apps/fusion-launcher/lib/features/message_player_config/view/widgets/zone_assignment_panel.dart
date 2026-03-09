import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/message_player_config/viewmodel/message_player_config_cubit.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Right panel for assigning zones to the selected message
class ZoneAssignmentPanel extends StatelessWidget {
  const ZoneAssignmentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.elevation1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'Assign Zones',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<MessagePlayerConfigCubit, MessagePlayerConfigState>(
              builder: (BuildContext context, MessagePlayerConfigState state) {
                final MessageModel? selectedMessage = state.selectedMessage;

                if (selectedMessage == null) {
                  return Center(
                    child: FusionAppText(
                      text: 'Select a message to assign zones',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return _ZoneList(
                  availableZones: state.availableZones,
                  selectedMessageId: selectedMessage.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneList extends StatelessWidget {
  final List<Zone> availableZones;
  final String selectedMessageId;

  const _ZoneList({
    required this.availableZones,
    required this.selectedMessageId,
  });

  @override
  Widget build(BuildContext context) {
    final MessagePlayerConfigCubit cubit = context.read<MessagePlayerConfigCubit>();

    // Get assigned zone IDs from RelationshipManager
    final Set<String> assignedZoneIds = cubit.getAssignedZonesForSelectedMessage();

    // Separate assigned and unassigned zones
    final List<Zone> assignedZones = availableZones.where((Zone z) => assignedZoneIds.contains(z.id)).toList();

    return Column(
      children: <Widget>[
        // Assigned zones at the top
        ...assignedZones.map(
          (Zone zone) => _ZoneItem(
            zone: zone,
            isAssigned: true,
            onToggle: () => cubit.toggleZoneAssignment(zone.id),
          ),
        ),

        // Add zone button/dropdown
        _AddZoneDropdown(
          availableZones: availableZones,
          assignedZoneIds: assignedZoneIds.toList(),
          onZoneSelected: (String zoneId) => cubit.toggleZoneAssignment(zoneId),
        ),
      ],
    );
  }
}

class _ZoneItem extends StatelessWidget {
  final Zone zone;
  final bool isAssigned;
  final VoidCallback onToggle;

  const _ZoneItem({
    required this.zone,
    required this.isAssigned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(
          SemanticTypes.button,
          'zone_item_${zone.id}',
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: FusionContainer(
              raised: false,
              borderRadius: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    FusionCheckbox(
                      value: isAssigned,
                      semanticId: 'zone_checkbox_${zone.id}',
                      onChanged: onToggle,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FusionAppText(
                        text: zone.name,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddZoneDropdown extends StatelessWidget {
  final List<Zone> availableZones;
  final List<String> assignedZoneIds;
  final Function(String zoneId) onZoneSelected;

  const _AddZoneDropdown({
    required this.availableZones,
    required this.assignedZoneIds,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get unassigned zones for the dropdown
    final List<Zone> unassignedZones = availableZones.where((Zone z) => !assignedZoneIds.contains(z.id)).toList();

    if (unassignedZones.isEmpty && assignedZoneIds.isEmpty) {
      return FusionContainer(
        raised: false,
        borderRadius: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                size: 16,
                color: context.colorScheme.textSecondary,
              ),
              const SizedBox(width: 8),
              FusionAppText(
                text: 'No zones available',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FusionDropDown<Zone>(
      semanticId: 'add_zone_dropdown',
      items: unassignedZones,
      selectedIndex: null,
      backgroundColor: context.colorScheme.elevation2,
      offset: const Offset(0, 50),
      trigger: FusionContainer(
        raised: false,
        borderRadius: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.add,
                size: 16,
                color: context.colorScheme.textPrimary,
              ),
              const SizedBox(width: 8),
              FusionAppText(
                text: 'Select zone',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (BuildContext context, Zone zone, bool isSelected) {
        return FusionAppText(
          text: zone.name,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.textPrimary,
          ),
        );
      },
      onSelected: (int index) {
        if (index >= 0 && index < unassignedZones.length) {
          onZoneSelected(unassignedZones[index].id);
        }
      },
    );
  }
}
