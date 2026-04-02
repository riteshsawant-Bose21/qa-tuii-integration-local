import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/zoneControl/zone_item_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Panel displaying zones and subzones in a tree structure
class ZonesListPanel extends StatelessWidget {
  final List<Zone> zones;
  final Map<String, List<SubZone>> subZonesInZones;
  final Set<String> selectedZoneIds;
  final String? selectedZoneId;
  final Set<String> selectedSubZoneIds;
  final String? activeSubZoneId;
  final bool isProController;

  const ZonesListPanel({
    super.key,
    required this.zones,
    this.subZonesInZones = const <String, List<SubZone>>{},
    this.selectedZoneIds = const <String>{},
    this.selectedZoneId,
    this.selectedSubZoneIds = const <String>{},
    this.activeSubZoneId,
    this.isProController = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          /// Header
          _buildHeader(context),

          /// Zones list
          Expanded(
            child: _buildZonesList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          FusionAppText(text: 'ZONES', style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildZonesList(BuildContext context) {
    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FusionAppText(
            text: 'No zones available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: zones.length,
      itemBuilder: (BuildContext context, int index) {
        final Zone zone = zones[index];
        final List<SubZone> subZones = subZonesInZones[zone.id] ?? <SubZone>[];
        final bool isSelected = selectedZoneIds.contains(zone.id);
        final bool isActiveZone = zone.id == selectedZoneId;

        return ZoneItemWidget(
          zone: zone,
          subZones: subZones,
          isSelected: isSelected,
          isActiveZone: isActiveZone,
          isProController: isProController,
          selectedSubZoneIds: selectedSubZoneIds,
          activeSubZoneId: activeSubZoneId,
          onToggleSelection: () {
            context.read<ConfigurationControlViewmodel>().toggleZoneSelection(zone.id);
          },
          onSelectZone: () {
            context.read<ConfigurationControlViewmodel>().selectZone(zone.id);
          },
          onToggleSubZoneSelection: (String subZoneId) {
            context.read<ConfigurationControlViewmodel>().toggleSubZoneSelection(subZoneId);
          },
          onSelectSubZone: (String subZoneId) {
            context.read<ConfigurationControlViewmodel>().selectSubZone(subZoneId);
          },
        );
      },
    );
  }
}
