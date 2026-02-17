import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/search_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../presentation/widgets/hardware_item_card.dart';
import '../../state/device_listing_state.dart';
import '../../viewmodel/device_listing_cubit.dart';
import 'schematic_expansion_section.dart';
import 'schematic_section.dart';

class SchematicHardwareListing<T extends HardwareComponent, VM extends DeviceListingViewModel<T>> extends StatelessWidget {
  const SchematicHardwareListing({
    super.key,
    required this.create,
    required this.title,
    this.addAction,
  });
  final VM Function(BuildContext) create;
  final String title;
  final Widget? addAction;
  @override
  Widget build(BuildContext context) {
    return SchematicSection<T, VM>(
      create: create,

      builder: (BuildContext context, DeviceListingState<T> state) {
        final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
        final SearchResultsViewModel read = context.read<SearchResultsViewModel>();
        read.updateResults(state.devices);
        if (state is DeviceSearchingState && state.devices.isEmpty) {
          return const SizedBox();
        }
        return SchematicExpansionSection<T>(
          title: title,
          items: state.devices,
          action: addAction,
          emptyMessage: state is DeviceSearchingState ? "No ${title.toLowerCase()} match search" : "No ${title.toLowerCase()} added yet",
          onReorder: (T oldItem, T newItem) {
            context.read<ProjectViewModel>().reOrderHardware(hardwareIdToMove: oldItem.id, hardwareAtNewIndex: newItem.id);
          },
          itemBuilder: (BuildContext context, T item, int index) {
            return HardwareItemCard(
              name: item.name,
              index: index,
              itemId: item.id,
              highlightQuery: state is DeviceSearchingState<T> ? (state).query : null,
              isSelected: projectViewModel.selectedDevice?.id == item.id,
              location: getLocationName(item.locationEntity.listeningAreaId),
              zoneName: getZoneName(item.id),
              zoneColor: getZoneColor(item.id),
              equipmentLocation: getEquipmentLocationForHardware(item.id),
              assetImagePath: item.assetImagePath,
              onTap:
                  () => projectViewModel.setSelectedDevice(
                    item.id,
                    SelectedItemType.source,
                  ),
              onDelete: (String id) {
                projectViewModel.removeHardware(
                  hardwareId: id,
                );
                FusionToast.error(
                  context,
                  message: '"${item.name}" deleted',
                );
              },
            );
          },
        );
      },
    );
  }

  /// Get location name from listeningAreaId
  String? getLocationName(String? listeningAreaId) {
    if (listeningAreaId == null) return null;

    final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);

    return area.name;
  }

  /// Get zone data from hardwareId
  String? getZoneName(String hardwareId) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    String? zoneName = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.name;
    if (zoneName == null || zoneName.trim().isEmpty) {
      zoneName = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId)?.name;
    }
    return zoneName;
  }

  Color? getZoneColor(String hardwareId) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    Color? zoneColor = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.color;
    if (zoneColor == null) {
      final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId);
      if (subZone != null) zoneColor = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.color;
    }
    return zoneColor;
  }

  String? getEquipmentLocationForHardware(String hardwareId) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    return projectViewModel.getEquipLocationForHardware(hardwareId: hardwareId)?.name;
  }
}
