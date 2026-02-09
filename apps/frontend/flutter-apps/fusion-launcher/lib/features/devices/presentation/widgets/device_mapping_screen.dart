import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/commission/presentation/widgets/configure_network_dialog.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_models.dart';
import 'hardware_card.dart';

class DeviceMappingScreen extends StatefulWidget {
  final List<ProjectDevice> projectDevices;
  final List<NetworkHardware> networkHardware;
  final Function(ProjectDevice, NetworkHardware?) onAssignHardware;

  const DeviceMappingScreen({
    super.key,
    required this.projectDevices,
    required this.networkHardware,
    required this.onAssignHardware,
  });

  @override
  State<DeviceMappingScreen> createState() => _DeviceMappingScreenState();
}

class _DeviceMappingScreenState extends State<DeviceMappingScreen> {
  String? _draggedHardwareId;

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
      // Use FLEX values to distribute width proportionally
      // Total flex = 1+3+3+2+3+2+4 = 18 parts
      columns: const <FusionTableColumn>[
        FusionTableColumn(key: 'status', header: 'STATUS', flex: 1),
        FusionTableColumn(key: 'deviceName', header: 'DEVICE NAME', flex: 3),
        FusionTableColumn(key: 'modelName', header: 'MODEL NAME', flex: 3),
        FusionTableColumn(key: 'location', header: 'LOCATION', flex: 2),
        FusionTableColumn(key: 'ipAddress', header: 'IP ADDRESS', flex: 3),
        FusionTableColumn(key: 'firmware', header: 'VER', flex: 2), // Shortened header
        FusionTableColumn(key: 'assignedTo', header: 'ASSIGNED TO', flex: 4), // Largest space for Dropdown
      ],
      rows: widget.projectDevices.map((ProjectDevice device) => _buildDeviceRow(device)).toList(),
    );
  }

  FusionTableRow _buildDeviceRow(ProjectDevice device) {
    final NetworkHardware assignedHardware = widget.networkHardware.firstWhere(
      (NetworkHardware hw) => hw.id == device.assignedHardwareId,
      orElse: () => NetworkHardware.empty(),
    );
    final bool isAssigned = device.assignedHardwareId != null;

    final TextStyle cellStyle = TextStyle(
      color: context.colorScheme.textPrimary,
      fontSize: 13, // Slightly smaller for dense tables
      overflow: TextOverflow.ellipsis,
    );

    final TextStyle greenLinkStyle = const TextStyle(
      color: Color(0xFF4CAF50),
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF4CAF50),
      overflow: TextOverflow.ellipsis,
    );

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
          value: isAssigned ? assignedHardware.modelName : '--',
          child: Text(isAssigned ? assignedHardware.modelName : '--', style: cellStyle, maxLines: 1),
        ),
        'location': FusionTableCell(
          value: device.location,
          child: Text(device.location, style: cellStyle, maxLines: 1),
        ),
        'ipAddress': FusionTableCell(
          value: isAssigned ? assignedHardware.ipAddress : '--',
          child: Text(isAssigned ? assignedHardware.ipAddress : '--', style: cellStyle, maxLines: 1),
        ),
        'firmware': FusionTableCell(
          value: isAssigned ? assignedHardware.firmware : '--',
          child: Text(isAssigned ? assignedHardware.firmware : '--', style: cellStyle, maxLines: 1),
        ),
        'assignedTo': FusionTableCell(
          value: isAssigned ? assignedHardware.modelName : 'unassigned',
          child: _buildAssignmentDropdown(device, assignedHardware),
        ),
      },
      // ... keep drag/drop logic same as before ...
      onDragEnter: (String id) => setState(() => _draggedHardwareId = id),
      onDragLeave: () => setState(() => _draggedHardwareId = null),
      onDrop: (String id) {
        final NetworkHardware hw = widget.networkHardware.firstWhere((NetworkHardware h) => h.id == id);
        widget.onAssignHardware(device, hw);
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
        color: isConnected ? const Color(0xFF4CAF50) : context.colorScheme.iconDefault,
      ),
    );
  }

  /// THE FIXED DROPDOWN WIDGET
  Widget _buildAssignmentDropdown(
    ProjectDevice device,
    NetworkHardware? assignedHardware,
  ) {
    final bool isAssigned = device.assignedHardwareId != null;

    return Container(
      height: 32, // Compact height
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      // DropdownButton must be wrapped to handle constraints
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: device.assignedHardwareId,
          isExpanded: true,
          // IMPORTANT: Forces button to take full width of Container
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colorScheme.iconDefault),
          dropdownColor: context.colorScheme.elevation2,
          style: TextStyle(
            color: isAssigned ? context.colorScheme.textPrimary : context.colorScheme.primaryColor,
            fontSize: 13,
            fontWeight: isAssigned ? FontWeight.w400 : FontWeight.w500,
          ),
          // When the screen is resized, the text inside the dropdown needs to handle overflow
          selectedItemBuilder: (BuildContext context) {
            return _getAllDropdownItems(device, isAssigned).map<Widget>((DropdownMenuItem<String?> item) {
              // This builder controls what is seen in the "Button" state (not the menu)
              // We extract the text from the DropdownMenuItem child to render it safely
              String text = '';
              if (item.child is Text) {
                text = (item.child as Text).data ?? '';
              } else if (item.value == null && isAssigned) {
                text = "Unassign Hardware";
              } else {
                // Fallback logic to find text in your items
                text = "Assign Hardware";
              }

              // If current item is a real hardware item
              if (item.value != null && item.value != 'null') {
                final NetworkHardware hw = widget.networkHardware.firstWhere((NetworkHardware h) => h.id == item.value, orElse: () => NetworkHardware.empty());
                if (hw.id.isNotEmpty) text = hw.modelName;
              }

              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Prevents overflow error in button
                  style: TextStyle(
                    color:
                        item.value == null && isAssigned
                            ? context.colorScheme.errorText
                            : (isAssigned ? context.colorScheme.textPrimary : context.colorScheme.primaryColor),
                  ),
                ),
              );
            }).toList();
          },
          items: _getAllDropdownItems(device, isAssigned),
          onChanged: (String? hardwareId) {
            if (hardwareId == null) {
              widget.onAssignHardware(device, null);
            } else {
              final NetworkHardware hardware = widget.networkHardware.firstWhere(
                (NetworkHardware hw) => hw.id == hardwareId,
              );
              widget.onAssignHardware(device, hardware);
            }
          },
        ),
      ),
    );
  }

  // Helper to generate items and ensure their children are overflow-safe
  List<DropdownMenuItem<String?>> _getAllDropdownItems(ProjectDevice device, bool isAssigned) {
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[];

    // 1. Unassign Option
    if (isAssigned) {
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

    // 2. Available Hardware
    final Iterable<NetworkHardware> availableHardware = widget.networkHardware.where(
      (NetworkHardware hw) => hw.assignedToDeviceId == null || hw.id == device.assignedHardwareId,
    );

    for (NetworkHardware hw in availableHardware) {
      items.add(
        DropdownMenuItem<String?>(
          value: hw.id,
          child: Text(
            hw.modelName,
            overflow: TextOverflow.ellipsis, // Prevents overflow in the open menu
            maxLines: 1,
          ),
        ),
      );
    }

    // 3. Placeholder if empty
    if (!isAssigned && availableHardware.isEmpty) {
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
    } else if (!isAssigned && items.isEmpty) {
      // Should show "Assign" prompt if not covered above
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
                text: 'Drag and drop the hardwares to the unassigned area or just select the drop down to map the devices',
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
              final NetworkHardware hardware = widget.networkHardware[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HardwareCard(
                  hardware: hardware,
                  onDragStarted: () {
                    setState(() {
                      _draggedHardwareId = hardware.id;
                    });
                  },
                  onDragEnd: () {
                    setState(() {
                      _draggedHardwareId = null;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FusionNeumorphicButton(
          text: "Add a Wireless Device",
          onTap: () {
            // Navigator.of(context).pop();
            ConfigureNetworkDialog.show(context, bluetoothOnly: true);
          },
        ),
      ],
    );
  }
}
