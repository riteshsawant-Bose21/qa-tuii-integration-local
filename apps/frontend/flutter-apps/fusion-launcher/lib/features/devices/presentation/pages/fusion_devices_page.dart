import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_global_settings_tab.dart';
import 'device_listing_page.dart';

// --- Models ---

// Represents the "Physical" hardware available on the network
class NetworkHardware {
  final String id;
  final String modelName;
  final String ip;
  final String firmware;

  NetworkHardware({
    required this.id,
    required this.modelName,
    required this.ip,
    required this.firmware,
  });
}

// Represents the "Project" row in the table
class ProjectDeviceRow {
  final String id;
  final String deviceName; // e.g. "FM6-1"
  final String targetModel; // The model this row EXPECTS (e.g. "FusionMini FM6")
  final String location;

  // -- Dynamic State Fields --
  bool isMapped; // Is a physical device assigned?
  String? assignedHardwareId; // ID of the assigned hardware
  String displayIp;
  String displayFirmware;
  bool isOnline;

  ProjectDeviceRow({
    required this.id,
    required this.deviceName,
    required this.targetModel,
    required this.location,
    this.isMapped = false,
    this.assignedHardwareId,
    this.displayIp = '-',
    this.displayFirmware = '-',
    this.isOnline = false,
  });
}

class FusionDevicesPage extends StatefulWidget {
  const FusionDevicesPage({super.key});

  @override
  State<FusionDevicesPage> createState() => _FusionDevicesPageState();
}

class _FusionDevicesPageState extends State<FusionDevicesPage> {
  // --- State ---
  String _selectedTab = 'Mapping'; // Default Tab
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // --- Mock Data ---

  // 1. Available Physical Hardware (The "Source" of truth for IP/Firmware)
  final List<NetworkHardware> _availableHardware = <NetworkHardware>[
    NetworkHardware(id: 'hw_1', modelName: 'Fusion Mini FM6', ip: '192.168.50.101', firmware: 'v1.1.0'),
    NetworkHardware(id: 'hw_2', modelName: 'PowerSmart 8300', ip: '192.168.50.102', firmware: 'v1.2.5'),
    NetworkHardware(id: 'hw_3', modelName: 'Control Pal Pro', ip: '192.168.50.103', firmware: 'v2.0.0'),
    NetworkHardware(id: 'hw_4', modelName: 'Control Pal LT', ip: '192.168.50.104', firmware: 'v1.0.1'),
  ];

  // 2. The Project Rows (Initially Unassigned)
  late List<ProjectDeviceRow> _rows;

  @override
  void initState() {
    super.initState();
    // Initialize rows with empty/unassigned state
    _rows = <ProjectDeviceRow>[
      ProjectDeviceRow(id: '1', deviceName: 'FM6-1', targetModel: 'FusionMini FM6', location: 'Zone_Reception'),
      ProjectDeviceRow(id: '2', deviceName: 'PSM8300-1', targetModel: 'PowerSmart 8300', location: 'Equipment Location'),
      ProjectDeviceRow(id: '3', deviceName: 'CPLT-1', targetModel: 'Control Pal Pro', location: 'Zone_Reception'),
      ProjectDeviceRow(id: '4', deviceName: 'CPLT-2', targetModel: 'Control Pal LT', location: 'Zone_Studio_Platinum'),
    ];
  }

  // --- Logic ---

  void _assignDevice(ProjectDeviceRow row, NetworkHardware hardware) {
    setState(() {
      row.isMapped = true;
      row.assignedHardwareId = hardware.id;
      row.displayIp = hardware.ip;
      row.displayFirmware = hardware.firmware;
      row.isOnline = true; // Assume online if mapped for this demo
    });
  }

  void _unassignDevice(ProjectDeviceRow row) {
    setState(() {
      row.isMapped = false;
      row.assignedHardwareId = null;
      row.displayIp = '-';
      row.displayFirmware = '-';
      row.isOnline = false;
    });
  }

  void _onSort<T>(Comparable<T> Function(ProjectDeviceRow d) getField, int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _isAscending = !_isAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _isAscending = true;
      }

      _rows.sort((ProjectDeviceRow a, ProjectDeviceRow b) {
        final Comparable<T> aValue = getField(a);
        final Comparable<T> bValue = getField(b);
        return _isAscending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgBlack = const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgBlack,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. TABS HEADER
            Row(
              children: <Widget>[
                _buildTab('Device List'),
                const SizedBox(width: 32),
                _buildTab('Updates', hasNotification: true),
                const SizedBox(width: 32),
                _buildTab('Mapping'), // Active
                const SizedBox(width: 32),
                _buildTab('Settings'),
              ],
            ),
            const SizedBox(height: 32),

            // 2. TAB CONTENT
            Expanded(
              child:
                  _selectedTab == 'Mapping'
                      ? _buildMappingContent()
                      : _selectedTab == "Device List"
                      ? const DeviceListTab()
                      : _selectedTab == "Settings"
                      ? const GlobalDeviceSettingsTab()
                      : _buildPlaceholderContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Views ---

  Widget _buildPlaceholderContent() {
    return Center(
      child: Text(
        "$_selectedTab Page Content",
        style: TextStyle(color: Colors.grey[700], fontSize: 18),
      ),
    );
  }

  Widget _buildMappingContent() {
    final Color cardDark = context.colorScheme.cardDark;
    final Color borderGrey = context.colorScheme.borderGrey;
    final Color textGrey = context.colorScheme.textGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // LEFT: DATA TABLE
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 900),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.transparent),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _isAscending,
                    headingTextStyle: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    dataTextStyle: TextStyle(color: context.colorScheme.primaryBlack, fontSize: 13),
                    border: TableBorder(
                      horizontalInside: BorderSide(color: borderGrey, width: 1),
                    ),
                    dividerThickness: 0.5,
                    columns: <DataColumn>[
                      _buildSortableHeader('STATUS', 0, (ProjectDeviceRow d) => d.isOnline.toString()),
                      _buildSortableHeader('DEVICE NAME', 1, (ProjectDeviceRow d) => d.deviceName),
                      _buildSortableHeader('MODEL NAME', 2, (ProjectDeviceRow d) => d.targetModel),
                      _buildSortableHeader('LOCATION', 3, (ProjectDeviceRow d) => d.location),
                      _buildSortableHeader('IP ADDRESS', 4, (ProjectDeviceRow d) => d.displayIp),
                      _buildSortableHeader('FIRMWARE', 5, (ProjectDeviceRow d) => d.displayFirmware),
                      _buildSortableHeader('ASSIGNED TO', 6, (ProjectDeviceRow d) => d.assignedHardwareId ?? ''),
                    ],
                    rows: _rows.map((ProjectDeviceRow row) => _buildDataRow(row)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // RIGHT: SIDEBAR
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'HARDWARES ON THE NETWORK',
                  style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline, color: textGrey, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag and drop the hardwares to the unassigned area or just select the drop down to map the devices',
                        style: TextStyle(color: textGrey, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Available Hardware List
                ..._availableHardware.map((NetworkHardware hw) => _buildSidebarItem(hw)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Header Builder with Sort Arrow ---
  DataColumn _buildSortableHeader(String label, int index, Comparable<dynamic> Function(ProjectDeviceRow) getField) {
    final bool isSelected = _sortColumnIndex == index;

    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label),
          if (isSelected) ...<Widget>[
            const SizedBox(width: 4),
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: Colors.white,
            ),
          ] else ...<Widget>[
            // Placeholder to keep alignment or show faint icon indicating sortable
            const SizedBox(width: 4),
            Icon(Icons.unfold_more, size: 14, color: Colors.grey[800]),
          ],
        ],
      ),
      onSort: (int idx, _) => _onSort(getField, idx),
    );
  }

  // --- Row Builder ---
  DataRow _buildDataRow(ProjectDeviceRow row) {
    final Color textGreen = const Color(0xFF4CAF50);
    final Color textGrey = const Color(0xFF9E9E9E);

    return DataRow(
      cells: <DataCell>[
        DataCell(
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: row.isOnline ? textGreen : Colors.grey[800], // Grey when offline/unassigned
              shape: BoxShape.circle,
            ),
          ),
        ),
        DataCell(
          Text(
            row.deviceName,
            style: TextStyle(
              color: row.isMapped ? textGreen : Colors.white, // Highlight name if active
              decoration: row.isMapped ? TextDecoration.underline : TextDecoration.none,
              decorationColor: textGreen,
            ),
          ),
        ),
        DataCell(Text(row.targetModel)),
        DataCell(Text(row.location)),
        DataCell(Text(row.displayIp, style: TextStyle(color: row.isMapped ? Colors.white : Colors.grey[700]))),
        DataCell(Text(row.displayFirmware, style: TextStyle(color: row.isMapped ? Colors.white : Colors.grey[700]))),
        DataCell(
          _buildAssignmentDropdown(row),
        ),
      ],
    );
  }

  // --- Complex Dropdown Logic ---
  // --- Updated Dropdown Logic ---
  Widget _buildAssignmentDropdown(ProjectDeviceRow row) {
    // 1. STATE: UNASSIGNED
    if (!row.isMapped) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colorScheme.borderGrey),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<NetworkHardware>(
            isExpanded: true,
            // Important: Standard height for simple list items
            itemHeight: 48,
            dropdownColor: context.colorScheme.cardDark, // Or your dark theme color
            icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colorScheme.greyLight),
            hint: Row(
              children: <Widget>[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.colorScheme.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Unassigned",
                  style: TextStyle(color: context.colorScheme.primaryBlack, fontSize: 13),
                ),
              ],
            ),
            items:
                _availableHardware.map((NetworkHardware hw) {
                  return DropdownMenuItem<NetworkHardware>(
                    value: hw,
                    // Assuming you have this helper method from previous steps
                    child: _buildHardwareDropdownItem(hw),
                  );
                }).toList(),
            onChanged: (NetworkHardware? hw) {
              if (hw != null) _assignDevice(row, hw);
            },
          ),
        ),
      );
    }
    // 2. STATE: ASSIGNED / MATCHED
    else {
      final NetworkHardware hw = _availableHardware.firstWhere((NetworkHardware h) => h.id == row.assignedHardwareId, orElse: () => _availableHardware[0]);

      return Container(
        height: 40, // Keep button height compact
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.colorScheme.cardDark,
          border: Border.all(color: context.colorScheme.borderGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: "assigned_value", // The 'current' selected value
            isExpanded: true,
            dropdownColor: context.colorScheme.cardDark,
            icon: const SizedBox.shrink(), // Hide arrow for the custom "Matched" look
            // --- FIX 1: Allow Variable Height Items ---
            itemHeight: null,
            isDense: true,

            // --- COLLAPSED VIEW (What you see in the table) ---
            selectedItemBuilder: (BuildContext context) {
              return <Widget>[
                // We only need to return ONE widget corresponding to "assigned_value"
                // This widget must match the Container height (40px)
                Row(
                  children: <Widget>[
                    // Matched Check Icon
                    Icon(Icons.check_circle, size: 14, color: context.colorScheme.greyLight),
                    const SizedBox(width: 8),
                    // Device Name
                    Expanded(
                      child: Text(
                        hw.modelName,
                        style: TextStyle(
                          color: context.colorScheme.primaryBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ];
            },

            // --- EXPANDED MENU (The Custom Card) ---
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                // --- FIX 2: Value must be different to trigger onChanged ---
                value: "assigned_value",
                child: Container(
                  // Give the card explicit padding/styling
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink to fit content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Matched Header
                      Row(
                        children: <Widget>[
                          Text("Matched", style: TextStyle(color: context.colorScheme.greyLight, fontSize: 10)),
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, size: 12, color: context.colorScheme.greyLight),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 2. Device Name
                      Text(
                        hw.modelName,
                        style: TextStyle(
                          color: context.colorScheme.primaryBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 3. Location
                      Row(
                        children: <Widget>[
                          Container(width: 8, height: 8, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "Main Rack",
                            style: TextStyle(color: context.colorScheme.greyLight, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              DropdownMenuItem<String>(
                // --- FIX 2: Value must be different to trigger onChanged ---
                value: "unassigned_value",
                child: Container(
                  // Give the card explicit padding/styling
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink to fit content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 4. Unassign Button Look-alike
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242), // Lighter grey for button
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Unassign",
                              style: TextStyle(
                                color: context.colorScheme.primaryBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (String? val) {
              // Because value is 'unassign_action', this triggers
              if (val == "unassigned_value") {
                _unassignDevice(row);
              }
            },
          ),
        ),
      );
    }
  }

  // --- Helper: Build Hardware List Item ---
  Widget _buildHardwareDropdownItem(NetworkHardware hw) {
    return Row(
      children: <Widget>[
        // Device Icon (simulated with icon)
        Icon(Icons.router, color: context.colorScheme.greyLight, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            hw.modelName,
            style: TextStyle(color: context.colorScheme.primaryBlack, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Link Icon (Mock: show if ID is even for demo)
        if (hw.id.hashCode % 2 == 0) ...<Widget>[
          Icon(Icons.link, color: context.colorScheme.greyLight, size: 16),
          const SizedBox(width: 8),
        ],
        // Lightbulb Icon
        Icon(Icons.lightbulb_outline, color: context.colorScheme.primaryBlack, size: 16),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildTab(String title, {bool hasNotification = false}) {
    final bool isActive = _selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = title),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: isActive ? const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 2))) : null,
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (hasNotification)
            Positioned(
              right: -6,
              top: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(NetworkHardware hw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            hw.modelName,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
