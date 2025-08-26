import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/services/project_manager.dart';

/// Multi‐selection device picker dialog (unchanged)
class MultiDevicePickerDialog extends StatefulWidget {
  final String title;
  final List<Source> devices;
  final List<Source> initiallySelected;

  const MultiDevicePickerDialog({
    super.key,
    required this.title,
    required this.devices,
    required this.initiallySelected,
  });

  @override
  MultiDevicePickerDialogState createState() => MultiDevicePickerDialogState();
}

class MultiDevicePickerDialogState extends State<MultiDevicePickerDialog> {
  late final Set<Source> _selected;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Source> get _filteredDevices {
    if (_searchQuery.isEmpty) return widget.devices;
    return widget.devices.where((Source device) {
      return device.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search devices...',
              prefixIcon: const Icon(Icons.search),
              prefixStyle: const TextStyle(
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400, // Fixed height for better UX
        child: Column(
          children: <Widget>[
            // Selected count indicator
            if (_selected.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selected.length} device${_selected.length == 1 ? '' : 's'} selected',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),

            // Device list
            Expanded(
              child:
                  _filteredDevices.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No devices found',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredDevices.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Source device = _filteredDevices[index];
                          final bool isSelected = _selected.contains(device);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: isSelected ? theme.colorScheme.surface : Colors.white30,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.grey.shade400 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selected.remove(device);
                                  } else {
                                    _selected.add(device);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: <Widget>[
                                    // Selection indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                          width: 2,
                                        ),
                                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                      ),
                                      child:
                                          isSelected
                                              ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: theme.colorScheme.onPrimary,
                                              )
                                              : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // Device icon based on type
                                    Image.asset(
                                      device.assetImagePath,
                                      height: 24,
                                      color: AppColors.primarySoft,
                                    ),

                                    const SizedBox(width: 12),

                                    // Device information
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          // Device name
                                          Text(
                                            device.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // Device details row
                                          Row(
                                            children: <Widget>[
                                              // Device type
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.outline.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  device.type.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.colorScheme.outline,
                                                  ),
                                                ),
                                              ),

                                              // Location
                                              if (device.locationEntity.listeningAreaId != null || device.locationEntity.floorId != null) ...<Widget>[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.location_on,
                                                  size: 12,
                                                  color: theme.colorScheme.outline,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  getLocation(device.locationEntity),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.outline,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),

                                          // Port numbers
                                          // if (device.portNumbers != null && device.portNumbers!.isNotEmpty) ...<Widget>[
                                          //   const SizedBox(height: 4),
                                          //   Row(
                                          //     children: <Widget>[
                                          //       Icon(
                                          //         Icons.settings_ethernet,
                                          //         size: 12,
                                          //         color: theme.colorScheme.outline,
                                          //       ),
                                          //       const SizedBox(width: 4),
                                          //       Text(
                                          //         'Ports: ${device.portNumbers!.join(', ')}',
                                          //         style: TextStyle(
                                          //           fontSize: 12,
                                          //           color: theme.colorScheme.outline,
                                          //         ),
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
          child: Text('Select (${_selected.length})'),
        ),
      ],
    );
  }

  String getLocation(LocationModel location) {
    if (location.floorId != null && location.listeningAreaId != null) {
      final FloorModel floor = serviceLocator<ProjectManager>().value.floors.firstWhere((FloorModel floor) => floor.id == location.floorId);

      final ListeningArea area = floor.listeningAreas.firstWhere((ListeningArea area) => area.id == location.listeningAreaId);

      return "${floor.name}/${area.name}"; // Display floor and listening area names
    } else if (location.floorId != null) {
      final FloorModel floor = serviceLocator<ProjectManager>().value.floors.firstWhere((FloorModel floor) => floor.id == location.floorId);
      return floor.name; // Display floor number
    } else if (location.listeningAreaId != null) {
      return "Listening Area ${location.listeningAreaId}"; // Display listening area number
    }
    return "No Location";
  }
}
