import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/search_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../entity/schematic_hardware_component.dart';
import '../../state/device_listing_state.dart';
import '../../viewmodel/device_listing_cubit.dart';
import 'elements/hardware_item_card.dart';
import 'schematic_expansion_section.dart';
import 'schematic_section.dart';

class SchematicHardwareListing<T extends HardwareComponent, VM extends DeviceListingViewModel<SchematicHardwareComponent<T>>> extends StatelessWidget {
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
    return SchematicSection<SchematicHardwareComponent<T>, VM>(
      create: create,

      builder: (BuildContext context, DeviceListingState<SchematicHardwareComponent<T>> state) {
        final SearchResultsViewModel read = context.read<SearchResultsViewModel>();
        read.updateResults(state.devices.map((SchematicHardwareComponent<T> e) => e.hardware.id).toList());
        if (state is DeviceSearchingState && state.devices.isEmpty) {
          if (read.state.results.isNotEmpty) {
            return const SizedBox();
          }
        }
        return SchematicExpansionSection<SchematicHardwareComponent<T>>(
          title: title,
          items: state.devices,
          action: addAction,
          emptyMessage:
              state is DeviceSearchingState<SchematicHardwareComponent<T>> ? "No ${title.toLowerCase()} match search" : "No ${title.toLowerCase()} added yet",
          onReorder: (SchematicHardwareComponent<T> oldItem, SchematicHardwareComponent<T> newItem) {
            context.read<ProjectViewModel>().reOrderHardware(hardwareIdToMove: oldItem.hardware.id, hardwareAtNewIndex: newItem.hardware.id);
          },
          itemBuilder: (BuildContext context, SchematicHardwareComponent<T> value, int index) {
            final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
            final HardwareComponent item = value.hardware;

            return HardwareItemCard(
              name: item.name,
              index: index,
              itemId: item.id,
              highlightQuery: state is DeviceSearchingState<SchematicHardwareComponent<T>> ? (state).query : null,
              isSelected: projectViewModel.selectedDevice?.id == item.id,
              location: value.locationName, //projectViewModel.getListeningArea(areaId: item.locationEntity.listeningAreaId ?? "").name,
              zoneName: value.zoneName, //getZoneName(item.id),
              zoneColor: value.zoneColor, //getZoneColor(item.id),
              equipmentLocation: value.equipmentLocationName, //getEquipmentLocationForHardware(item.id),
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
}
