import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../../../commission/presentation/widgets/configure_network_dialog.dart';
import 'device_models.dart';
import 'hardware_card.dart';

class DeviceMappingScreen extends StatefulWidget {
  final List<HardwareComponent> devices;
  final List<NetworkHardware> networkHardware;
  // Callback: Device is the target, Hardware is the value (null to unassign)
  final Function(HardwareComponent, NetworkHardware?) onAssignHardware;

  const DeviceMappingScreen({
    super.key,
    required this.devices,
    required this.networkHardware,
    required this.onAssignHardware,
  });

  @override
  State<DeviceMappingScreen> createState() => _DeviceMappingScreenState();
}

class _DeviceMappingScreenState extends State<DeviceMappingScreen> {
  String? _draggedHardwareId;

  // Helper to find which hardware is assigned to a specific device
  NetworkHardware? _getAssignedHardware(String deviceId) {
    try {
      return widget.networkHardware.firstWhere(
        (NetworkHardware hw) => hw.assignedToDeviceId == deviceId,
      );
    } catch (e) {
      return null;
    }
  }

  String _getDeviceLocation(HardwareComponent device) {
    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = serviceLocator<ProjectViewModel>()
          .getZonesForListeningArea(
            areaId: device.locationEntity.listeningAreaId!,
          );
      if (zone != null) return zone.name;

      final SubZone? subZone = serviceLocator<ProjectViewModel>()
          .getSubZoneForListeningArea(
            areaId: device.locationEntity.listeningAreaId!,
          );
      if (subZone != null) {
        final Zone? parentZone = serviceLocator<ProjectViewModel>()
            .getZoneForSubZone(subZoneId: subZone.id);
        return parentZone != null
            ? "${parentZone.name} > ${subZone.name}"
            : subZone.name;
      }
    }
    final EquipLocation? location = serviceLocator<ProjectViewModel>()
        .getEquipLocationForHardware(hardwareId: device.id);
    return location?.name ?? "--";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // TABLE SECTION
                Expanded(
                  flex: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildDeviceTable(),
                  ),
                ),
                const SizedBox(width: 24),
                // DIVIDER
                Container(
                  width: 1,
                  height: double.infinity,
                  color: context.colorScheme.strokeLight,
                ),

                const SizedBox(width: 24),

                // PANEL SECTION
                Expanded(
                  flex: 3,
                  child: _buildHardwarePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTable() {
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
      rows:
          widget.devices
              .map((HardwareComponent device) => _buildDeviceRow(device))
              .toList(),
    );
  }

  FusionTableRow _buildDeviceRow(HardwareComponent device) {
    // LOGIC CHANGE: Find hardware where assignedToDeviceId matches device.id
    final NetworkHardware? assignedHardware = _getAssignedHardware(device.id);
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
          value: isAssigned ? assignedHardware.ipAddress : '--',
          child: Text(
            isAssigned ? assignedHardware.ipAddress : '--',
            style: cellStyle,
            maxLines: 1,
          ),
        ),
        'firmware': FusionTableCell(
          value: isAssigned ? assignedHardware.firmware : '--',
          child: Text(
            isAssigned ? assignedHardware.firmware : '--',
            style: cellStyle,
            maxLines: 1,
          ),
        ),
        'assignedTo': FusionTableCell(
          value: isAssigned ? assignedHardware.modelName : 'unassigned',
          child: _buildAssignmentDropdown(device, assignedHardware),
        ),
      },
      // DRAG & DROP LOGIC
      onDragEnter: (String id) => setState(() => _draggedHardwareId = id),
      onDragLeave: () => setState(() => _draggedHardwareId = null),
      onDrop: (String hardwareId) {
        final NetworkHardware hw = widget.networkHardware.firstWhere(
          (NetworkHardware h) => h.id == hardwareId,
          orElse: () => NetworkHardware.empty(),
        );
        if (!hw.isEmpty) {
          widget.onAssignHardware(device, hw);
        }
        setState(() => _draggedHardwareId = null);
      },
      isDragTarget: _draggedHardwareId != null,
    );
  }

  Widget _buildStatusIndicator(bool isConnected) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isConnected
                ? const Color(0xFF4CAF50)
                : context.colorScheme.iconDefault,
      ),
    );
  }

  Widget _buildAssignmentDropdown(
    HardwareComponent device,
    NetworkHardware? assignedHardware,
  ) {
    final bool isAssigned = assignedHardware != null;

    // The value of the dropdown is the ID of the assigned physical hardware
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
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: context.colorScheme.iconDefault,
          ),
          dropdownColor: context.colorScheme.elevation2,
          style: TextStyle(
            color:
                isAssigned
                    ? context.colorScheme.textPrimary
                    : context.colorScheme.primaryColor,
            fontSize: 13,
            fontWeight: isAssigned ? FontWeight.w400 : FontWeight.w500,
          ),
          // Helper to generate list based on new logic
          items: _getDropdownItems(device, assignedHardware),
          selectedItemBuilder: (BuildContext context) {
            return _getDropdownItems(device, assignedHardware).map<Widget>((
              DropdownMenuItem<String?> item,
            ) {
              String text = '';
              String ipAddress = '';
              // Handle visual text for selected item
              if (item.value == null) {
                text = isAssigned ? "Unassign Hardware" : "Assign Hardware";
              } else {
                // Find name for ID
                final NetworkHardware? hw = widget.networkHardware
                    .cast<NetworkHardware?>()
                    .firstWhere(
                      (NetworkHardware? h) => h?.id == item.value,
                      orElse: () => null,
                    );
                text = hw?.modelName ?? "Unknown";
                ipAddress = hw?.ipAddress ?? '';
              }

              return Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: text,
                      maxLine: 1,
                      textOverflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium,
                    ),
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
              // Unassign action
              widget.onAssignHardware(device, null);
            } else {
              // Assign action
              final NetworkHardware hw = widget.networkHardware.firstWhere(
                (NetworkHardware h) => h.id == hardwareId,
              );
              widget.onAssignHardware(device, hw);
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String?>> _getDropdownItems(
    HardwareComponent device,
    NetworkHardware? currentAssigned,
  ) {
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[];

    // 1. Unassign Option (Only if currently assigned)
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
    }

    // 2. Filter Available Hardware
    // Logic: Hardware is available if assignedToDeviceId is null OR assignedToDeviceId matches THIS device

    final NetworkHardwareType? requiredType = switch (device.runtimeType) {
      const (FusionDsp) => NetworkHardwareType.dsp,
      const (Amplifier) => NetworkHardwareType.amplifier,
      const (FusionController) => NetworkHardwareType.controller,
      _ => null,
    };

    final Iterable<NetworkHardware> availableHardware = widget.networkHardware
        .where(
          (NetworkHardware hw) =>
              (hw.assignedToDeviceId == null ||
                  hw.assignedToDeviceId == device.id) &&
              (requiredType == null || hw.type == requiredType),
        );

    for (NetworkHardware hw in availableHardware) {
      items.add(
        DropdownMenuItem<String?>(
          value: hw.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: hw.modelName,
                maxLine: 1,
                textOverflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium!,
              ),
              FusionAppText(
                text: hw.ipAddress,
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

    // 3. Placeholder if nothing available
    if (currentAssigned == null && availableHardware.isEmpty) {
      items.add(
        DropdownMenuItem<String?>(
          value: null,
          enabled: false,
          child: FusionAppText(
            text: 'No Hardware Available',
            style: TextStyle(color: context.colorScheme.textSecondary),
            textOverflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else if (currentAssigned == null && items.isEmpty) {
      // Should show "Assign" prompt if valid items exist but we haven't added the null option yet
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

    return items;
  }

  Widget _buildHardwarePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 16,
              color: context.colorScheme.iconDefault,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FusionAppText(
                text: 'Drag and drop hardware to map to devices.',
                style: TextStyle(
                  color: context.colorScheme.textBody,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FusionAppText(
          text: 'HARDWARES ON THE NETWORK',
          style: TextStyle(
            color: context.colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.networkHardware.length,
            itemBuilder: (BuildContext context, int index) {
              final NetworkHardware hw = widget.networkHardware[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HardwareCard(
                  hardware: hw,
                  onDragStarted:
                      () => setState(() => _draggedHardwareId = hw.id),
                  onDragEnd: () => setState(() => _draggedHardwareId = null),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FusionNeumorphicButton(
          semanticId: 'add_wireless_device_button',
          text: "Add a Wireless Device",
          height: 35,
          onTap: () {
            ConfigureNetworkDialog.show(context, bluetoothOnly: true);
          },
        ),
      ],
    );
  }
}
