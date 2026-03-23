import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceMappingTable extends StatefulWidget {
  final List<HardwareComponent> devices;
  final List<FusionNetworkDevice> networkDevices;
  final String? draggedHardwareId;
  final Function(String) onDragEnter;
  final VoidCallback onDragLeave;
  final Function(HardwareComponent, FusionNetworkDevice?) onAssignHardware;

  const DeviceMappingTable({
    super.key,
    required this.devices,
    required this.networkDevices,
    required this.draggedHardwareId,
    required this.onDragEnter,
    required this.onDragLeave,
    required this.onAssignHardware,
  });

  @override
  State<DeviceMappingTable> createState() => _DeviceMappingTableState();
}

class _DeviceMappingTableState extends State<DeviceMappingTable> {
  FusionNetworkDevice? _getAssignedHardware(String deviceId) {
    try {
      return widget.networkDevices.firstWhere(
        (FusionNetworkDevice hw) => hw.id == deviceId,
      );
    } catch (e) {
      return null;
    }
  }

  String _getDeviceLocation(HardwareComponent device) {
    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: device.locationEntity.listeningAreaId!);
      if (zone != null) return zone.name;

      final SubZone? subZone = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(areaId: device.locationEntity.listeningAreaId!);
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>().getZoneForSubZone(subZoneId: subZone.id);
        return parentZone != null ? "${parentZone.name} > ${subZone.name}" : subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id);
    return location?.name ?? "--";
  }

  @override
  Widget build(BuildContext context) {
    return FusionTable(
      columns: const <FusionTableColumn>[
        FusionTableColumn(key: 'status', header: 'STATUS', flex: 1),
        FusionTableColumn(key: 'deviceName', header: 'DEVICE NAME', flex: 2),
        FusionTableColumn(key: 'modelName', header: 'MODEL NAME', flex: 2),
        FusionTableColumn(key: 'location', header: 'LOCATION', flex: 3),
        FusionTableColumn(key: 'ipAddress', header: 'IP ADDRESS', flex: 2),
        FusionTableColumn(key: 'firmware', header: 'VER', flex: 2),
        FusionTableColumn(key: 'assignedTo', header: 'ASSIGNED TO', flex: 4),
      ],
      rows: widget.devices.map((HardwareComponent device) => _buildDeviceRow(device)).toList(),
    );
  }

  FusionTableRow _buildDeviceRow(HardwareComponent device) {
    final FusionNetworkDevice? assignedHardware = _getAssignedHardware(device.id);
    final bool isAssigned = assignedHardware != null;

    final TextStyle cellStyle = TextStyle(
      color: context.colorScheme.textPrimary,
      fontSize: 13,
      overflow: TextOverflow.ellipsis,
    );

    final TextStyle greenLinkStyle = const TextStyle(
      color: Color(0xFF4CAF50),
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF4CAF50),
      overflow: TextOverflow.ellipsis,
    );

    final String locationName = _getDeviceLocation(device);

    return FusionTableRow(
      key: device.id,
      cells: <String, FusionTableCell>{
        'status': FusionTableCell(
          value: isAssigned ? 1 : 0,
          child: _buildStatusIndicator(isAssigned),
        ),
        'deviceName': FusionTableCell(
          value: device.name,
          child: Text(device.name, style: greenLinkStyle, maxLines: 1),
        ),
        'modelName': FusionTableCell(
          value: device.hardwareName,
          child: Text(device.hardwareName, style: cellStyle, maxLines: 1),
        ),
        'location': FusionTableCell(
          value: locationName,
          child: Text(locationName, style: cellStyle, maxLines: 1),
        ),
        'ipAddress': FusionTableCell(
          value: isAssigned ? assignedHardware.address : '--',
          child: Text(isAssigned ? assignedHardware.address : '--', style: cellStyle, maxLines: 1),
        ),
        'firmware': FusionTableCell(
          value: isAssigned ? assignedHardware.serialNumber : '--',
          child: Text(isAssigned ? assignedHardware.serialNumber : '--', style: cellStyle, maxLines: 1),
        ),
        'assignedTo': FusionTableCell(
          value: isAssigned ? assignedHardware.modelName : 'unassigned',
          child: _buildAssignmentDropdown(device, assignedHardware),
        ),
      },
      onWillAccept: (String hardwareId) {
        final FusionNetworkDevice? hw = widget.networkDevices.cast<FusionNetworkDevice?>().firstWhere(
          (FusionNetworkDevice? h) => h?.id == hardwareId,
          orElse: () => null,
        );
        return hw != null && hw.modelName == device.hardwareName;
      },
      onDragEnter: (String id) => widget.onDragEnter(id),
      onDragLeave: () => widget.onDragLeave(),
      onDrop: (String hardwareId) {
        final FusionNetworkDevice? hw = widget.networkDevices.cast<FusionNetworkDevice?>().firstWhere(
          (FusionNetworkDevice? h) => h?.id == hardwareId,
          orElse: () => null,
        );
        if (hw != null && hw.modelName == device.hardwareName) {
          widget.onAssignHardware(device, hw);
        }
        widget.onDragLeave();
      },
      isDragTarget: widget.draggedHardwareId != null,
    );
  }

  Widget _buildStatusIndicator(bool isConnected) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? const Color(0xFF4CAF50) : context.colorScheme.iconDefault,
      ),
    );
  }

  Widget _buildAssignmentDropdown(
    HardwareComponent device,
    FusionNetworkDevice? assignedHardware,
  ) {
    final bool isAssigned = assignedHardware != null;
    final String? dropdownValue = isAssigned ? assignedHardware.id : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: dropdownValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colorScheme.iconDefault),
          dropdownColor: context.colorScheme.elevation2,
          style: TextStyle(
            color: isAssigned ? context.colorScheme.textPrimary : context.colorScheme.primaryColor,
            fontSize: 13,
            fontWeight: isAssigned ? FontWeight.w400 : FontWeight.w500,
          ),
          items: _getDropdownItems(device, assignedHardware),
          selectedItemBuilder: (BuildContext context) {
            return _getDropdownItems(device, assignedHardware).map<Widget>((DropdownMenuItem<String?> item) {
              String text = '';
              String ipAddress = '';
              if (item.value == null) {
                text = isAssigned ? "Unassign Hardware" : "Assign Hardware";
              } else {
                final FusionNetworkDevice? hw = widget.networkDevices.cast<FusionNetworkDevice?>().firstWhere(
                  (FusionNetworkDevice? h) => h?.id == item.value,
                  orElse: () => null,
                );
                text = hw?.name ?? "Unknown";
                ipAddress = hw?.address ?? '';
              }

              return Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FusionAppText(
                      text: text,
                      maxLine: 1,
                      textOverflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium,
                    ),
                    if (ipAddress.isNotEmpty)
                      FusionAppText(
                        text: ipAddress,
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall!.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              );
            }).toList();
          },
          onChanged: (String? hardwareId) {
            if (hardwareId == null) {
              widget.onAssignHardware(device, null);
            } else {
              final FusionNetworkDevice hw = widget.networkDevices.firstWhere((FusionNetworkDevice h) => h.id == hardwareId);
              widget.onAssignHardware(device, hw);
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String?>> _getDropdownItems(HardwareComponent device, FusionNetworkDevice? currentAssigned) {
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[];

    if (currentAssigned != null) {
      items.add(
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'Unassign Hardware',
            style: TextStyle(color: context.colorScheme.errorText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      items.add(
        DropdownMenuItem<String?>(
          value: null,
          enabled: false,
          child: FusionAppText(
            text: 'Assign Hardware',
            style: TextStyle(color: context.colorScheme.primaryColor),
            textOverflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final Iterable<FusionNetworkDevice> availableHardware = widget.networkDevices.where((FusionNetworkDevice hw) {
      final bool isAssignedToThis = hw.id == device.id;
      if (isAssignedToThis) return true;

      final bool isAssignedToAnother = widget.devices.any((HardwareComponent d) => d.id == hw.id);
      return !isAssignedToAnother && (hw.modelName == device.hardwareName);
    });

    final Set<String> addedIds = <String>{};
    for (FusionNetworkDevice hw in availableHardware) {
      if (addedIds.contains(hw.id)) continue;
      addedIds.add(hw.id);

      items.add(
        DropdownMenuItem<String?>(
          value: hw.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FusionAppText(
                text: hw.name,
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium!,
              ),
              FusionAppText(
                text: hw.address,
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (currentAssigned == null && addedIds.isEmpty) {
      items[0] = DropdownMenuItem<String?>(
        value: null,
        enabled: false,
        child: FusionAppText(
          text: 'No Hardware Available',
          style: TextStyle(color: context.colorScheme.textSecondary),
          textOverflow: TextOverflow.ellipsis,
        ),
      );
    }

    return items;
  }
}
