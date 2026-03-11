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
          FusionAppText(text: 'Assign Zones', style: context.textTheme.l1Medium),
          const SizedBox(height: 12),

          /// Zone list or empty state
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
    final Set<Zone> selectedZones = cubit.getAssignedZonesAsSet();

    return Column(
      children: <Widget>[
        /// Add zone dropdown using FusionMultiSelectPopupMenu
        FusionMultiSelectPopupMenu<Zone>(
          items: availableZones,
          selectedItems: selectedZones,
          semanticsId: 'zone_assignment_dropdown',
          tooltip: 'Select zones',
          itemLabelBuilder: (Zone zone) => zone.name,
          onSave: cubit.updateZoneAssignments,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: context.colorScheme.elevation2,
              borderRadius:
                  selectedZones.isEmpty
                      ? BorderRadius.circular(8)
                      : const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
              border: Border.all(color: context.colorScheme.strokeLight),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.add, size: 16, color: context.colorScheme.textPrimary),
                const SizedBox(width: 8),
                FusionAppText(text: availableZones.isEmpty ? 'No zones available' : 'Select zone', style: context.textTheme.l1Regular),
              ],
            ),
          ),
        ),

        // Assigned zones list
        ...selectedZones.toList().asMap().entries.map(
          (MapEntry<int, Zone> entry) => _ZoneItem(
            zone: entry.value,
            isAssigned: true,
            isLast: entry.key == selectedZones.length - 1,
            onToggle: () => cubit.toggleZoneAssignment(entry.value.id),
          ),
        ),
      ],
    );
  }
}

class _ZoneItem extends StatelessWidget {
  final Zone zone;
  final bool isAssigned;
  final bool isLast;
  final VoidCallback onToggle;

  const _ZoneItem({
    required this.zone,
    required this.isAssigned,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius:
          isLast
              ? const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius:
              isLast
                  ? const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )
                  : null,
          border: Border(
            bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
            left: BorderSide(color: context.colorScheme.strokeLight, width: 1),
            right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
          ),
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
                style: context.textTheme.bodyMedium,
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
