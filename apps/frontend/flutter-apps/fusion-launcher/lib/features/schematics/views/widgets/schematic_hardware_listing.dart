import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/search_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../entity/schematic_hardware_component.dart';
import '../../state/device_listing_state.dart';
import '../../state/filter_state.dart';
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
    this.filterState,
  });
  final VM Function(BuildContext) create;
  final String title;
  final Widget? addAction;
  final FilterViewModelState? filterState;

  @override
  Widget build(BuildContext context) {
    Set<String>? allowedZoneNames0;
    Set<String>? allowedEquipLocationNames0;

    if (filterState != null) {
      final ProjectViewModel pvm = context.read<ProjectViewModel>();

      // ── Zone / SubZone → allowed names ─────────────────────────────────
      if (filterState!.checkedZoneIds.isNotEmpty || filterState!.checkedSubZoneIds.isNotEmpty) {
        allowedZoneNames0 = <String>{};

        for (final Zone zone in pvm.getAllZones()) {
          if (filterState!.checkedZoneIds.contains(zone.id)) {
            // Checked zone: include zone name AND all its subzone names so
            // devices in any subzone of a selected zone are shown.
            allowedZoneNames0.add(zone.name);
            for (final SubZone sub in pvm.getSubZonesForZone(parentZoneId: zone.id)) {
              allowedZoneNames0.add(sub.name);
            }
          } else {
            // Zone not directly checked — check if individual subzones are.
            for (final SubZone sub in pvm.getSubZonesForZone(parentZoneId: zone.id)) {
              if (filterState!.checkedSubZoneIds.contains(sub.id)) {
                allowedZoneNames0.add(sub.name);
              }
            }
          }
        }
      }

      // ── EquipLocation → allowed names ───────────────────────────────────
      if (filterState!.checkedLocationIds.isNotEmpty) {
        allowedEquipLocationNames0 = <String>{};
        for (final EquipLocation loc in pvm.equipLocations) {
          if (filterState!.checkedLocationIds.contains(loc.id)) {
            allowedEquipLocationNames0.add(loc.name);
          }
        }
      }
    }

    // Capture as effectively-final locals for closure use.
    final Set<String>? allowedZoneNames = allowedZoneNames0;
    final Set<String>? allowedEquipLocationNames = allowedEquipLocationNames0;

    return SchematicSection<SchematicHardwareComponent<T>, VM>(
      create: create,

      builder: (BuildContext context, DeviceListingState<SchematicHardwareComponent<T>> state) {
        final SearchResultsViewModel read = context.read<SearchResultsViewModel>();
        final List<SchematicHardwareComponent<T>> filteredDevices =
            filterState == null
                ? state.devices
                : state.devices.where((SchematicHardwareComponent<T> e) {
                  // ── Floor + Area (ID-based via LocationModel) ──────
                  if (!filterState!.passesFilter(e.hardware)) return false;

                  // ── Zone / SubZone (name-based) ────────────────────
                  // filter active).
                  if (allowedZoneNames != null) {
                    final String? name = e.zoneName;
                    if (name != null && !allowedZoneNames.contains(name)) {
                      return false;
                    }
                  }

                  // ── Equipment Location (name-based) ────────────────
                  // Skipped when allowedEquipLocationNames is null.
                  if (allowedEquipLocationNames != null) {
                    final String? name = e.equipmentLocationName;
                    if (name != null && !allowedEquipLocationNames.contains(name)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

        read.updateResults(
          filteredDevices.map((SchematicHardwareComponent<T> e) => e.hardware.id).toList(),
        );

        if (state is DeviceSearchingState && filteredDevices.isEmpty) {
          if (read.state.results.isNotEmpty) {
            return const SizedBox();
          }
        }
        return SchematicExpansionSection<SchematicHardwareComponent<T>>(
          title: title,
          items: filteredDevices,
          action: addAction,
          emptyMessage:
              state is DeviceSearchingState<SchematicHardwareComponent<T>> ? "No ${title.toLowerCase()} match search" : "No ${title.toLowerCase()} added yet",
          onReorder: (SchematicHardwareComponent<T> oldItem, SchematicHardwareComponent<T> newItem) {
            context.read<ProjectViewModel>().reOrderHardware(
              hardwareIdToMove: oldItem.hardware.id,
              hardwareAtNewIndex: newItem.hardware.id,
            );
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
              image: item.image,
              pagingSourceType: item is Source ? item.pagingSourceType : null,
              onTap: () => projectViewModel.setSelectedDevice(item.id, SelectedItemType.source),
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
