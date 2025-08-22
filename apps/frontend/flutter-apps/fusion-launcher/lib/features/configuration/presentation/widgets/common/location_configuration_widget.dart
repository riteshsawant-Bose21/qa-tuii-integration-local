import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/models/floor_entity.dart';
import '../../../../../core/models/project_entity.dart';
import '../../../../../core/service_locator.dart';

/// Call this function from anywhere in your app to show the "Configure Device" dialog.
Future<LocationEntity?> showConfigureDeviceDialog(
  BuildContext context,
  LocationEntity locationEntity,
  Function(Floor) onNewFloorCreated,
  Function(Floor) onFloorUpdated,
) async {
  String? selectedFloorId = locationEntity.floorId;
  String? selectedListeningAreaId = locationEntity.listeningAreaId;

  bool isLocationSelected = locationEntity.floorId != null && locationEntity.listeningAreaId != null;

  final ProjectManager projectManager = serviceLocator<ProjectManager>();

  final LocationEntity? result = await showDialog<LocationEntity?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      final double width = 400;
      final bool isSmallScreen = MediaQuery.of(context).size.width < 700;

      return ValueListenableBuilder<ProjectEntity>(
        valueListenable: projectManager,
        builder: (BuildContext context, ProjectEntity data, _) {
          final List<Floor> floors = data.floors;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Container(
                  width: width,
                  height: 700,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: <Widget>[
                      // Header with icon and title
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Configure Device',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Set location and port assignments',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.withAlpha((0.1 * 255).toInt()),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Location Section
                              _buildSectionHeader(
                                context,
                                'Device Location',
                                Icons.location_on,
                                'Choose where this device is located',
                              ),
                              const SizedBox(height: 16),

                              // No location option - Enhanced design
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: !isLocationSelected ? Theme.of(context).primaryColor : Colors.grey.withAlpha((0.3 * 255).toInt()),
                                    width: !isLocationSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: !isLocationSelected ? Theme.of(context).primaryColor.withAlpha((0.05 * 255).toInt()) : Colors.transparent,
                                ),
                                child: RadioListTile<String>(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.location_off,
                                        size: 20,
                                        color: !isLocationSelected ? Theme.of(context).primaryColor : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('No specific location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  value: 'none',
                                  groupValue: selectedListeningAreaId ?? "none",
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (String? val) {
                                    if (val == null) return;
                                    setState(() {
                                      selectedListeningAreaId = null;
                                      locationEntity = locationEntity.clearFloorAndListeningArea();
                                      isLocationSelected = false;
                                    });
                                  },
                                ),
                              ),

                              for (final Floor floor in floors) ...<Widget>[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      childrenPadding: const EdgeInsets.all(16),
                                      leading: Icon(
                                        Icons.home,
                                        color: Theme.of(context).primaryColor,
                                      ),

                                      title: TextFormField(
                                        initialValue: floor.name,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        ),
                                        enabled: false,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        onChanged: (String val) {
                                          final Floor updatedFloor = floor.copyWith(name: val);
                                          onFloorUpdated(updatedFloor);
                                        },
                                      ),

                                      children: <Widget>[
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 1,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            mainAxisExtent: 56,
                                          ),
                                          itemCount: floor.listeningAreas.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final ListeningArea listeningArea = floor.listeningAreas[index];
                                            final bool isSelected = selectedListeningAreaId == listeningArea.id;
                                            return Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withAlpha((0.3 * 255).toInt()),
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                color: isSelected ? Theme.of(context).primaryColor.withAlpha((0.05 * 255).toInt()) : Colors.transparent,
                                              ),
                                              child: RadioListTile<String>(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                title: TextFormField(
                                                  initialValue: listeningArea.name,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    border: InputBorder.none,
                                                    disabledBorder: InputBorder.none,
                                                  ),
                                                  enabled: false,
                                                  style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.black, fontSize: 14),
                                                  onChanged: (String val) {
                                                    // Update the ListeningArea name in the parent widget
                                                    final ListeningArea updatedArea = listeningArea.copyWith(name: val);
                                                    final Floor updatedFloor = floor.copyWith(
                                                      listeningAreas: List<ListeningArea>.from(floor.listeningAreas)..[index] = updatedArea,
                                                    );
                                                    onFloorUpdated(updatedFloor);
                                                  },
                                                ),
                                                value: listeningArea.id,
                                                groupValue: selectedListeningAreaId,
                                                activeColor: Theme.of(context).primaryColor,
                                                onChanged: (String? val) {
                                                  setState(() {
                                                    locationEntity = locationEntity.copyWith(
                                                      floorId: floor.id,
                                                      listeningAreaId: val,
                                                    );
                                                    selectedFloorId = floor.id;
                                                    selectedListeningAreaId = val;
                                                    isLocationSelected = true;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            // Create a new ListeningArea
                                            final String areaName = "Area ${floor.listeningAreas.length + 1}";
                                            final ListeningArea newListeningArea = ListeningArea(
                                              name: areaName,
                                              vertices: <Offset>[
                                                const Offset(-0.5, -0.5),
                                                const Offset(0.5, -0.5),
                                                const Offset(0.5, 0.5),
                                                const Offset(-0.5, 0.5),
                                              ],
                                            );

                                            // Add the new ListeningArea to the current FloorEntity using copy with
                                            final Floor updatedFloor = floor.copyWith(
                                              listeningAreas: List<ListeningArea>.from(floor.listeningAreas)..add(newListeningArea),
                                            );
                                            // Update the floors list in the parent widget
                                            onFloorUpdated(updatedFloor);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Icon(
                                                  Icons.add,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                                const Text(
                                                  "Add new area",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              //Button to add new floor
                              InkWell(
                                onTap: () {
                                  //Create a new FloorEntity
                                  final Floor newFloor = Floor(
                                    name: 'Floor ${floors.length + 1}',
                                    listeningAreas: <ListeningArea>[],
                                    floorPlan: FloorPlanEntity.defaultFloorPlan,
                                  );
                                  onNewFloorCreated(newFloor);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.add,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      title: const Text(
                                        "Add new floor",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // LocationConfigurationTab(
                              //   floors: floors,
                              //   selectedListeningAreaId: selectedListeningAreaId,
                              //   onLocationSelected: (LocationEntity location) {
                              //     setState(() {
                              //       selectedFloorId = location.floorId;
                              //       selectedListeningAreaId = location.listeningAreaId;
                              //       isLocationSelected = location.floorId != null || location.listeningAreaId != null;
                              //     });
                              //   },
                              //   onFloorUpdated: (List<FloorEntity> updatedFloors, LocationEntity newLocation) {
                              //     setState(() {
                              //       floors = updatedFloors;
                              //       selectedFloorId = newLocation.floorId;
                              //       selectedListeningAreaId = newLocation.listeningAreaId;
                              //       isLocationSelected = newLocation.floorId != null || newLocation.listeningAreaId != null;
                              //     });
                              //   },
                              // ),

                              // Rooms Section
                            ],
                          ),
                        ),
                      ),

                      // Footer with actions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withAlpha((0.05 * 255).toInt()),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(locationEntity);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );

  return result;
}

// Helper method for section headers
Widget _buildSectionHeader(BuildContext context, String title, IconData icon, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
      ),
    ],
  );
}

class LocationConfigurationTab extends StatefulWidget {
  final List<Floor> floors;
  final String? selectedListeningAreaId;
  final Function(LocationEntity) onLocationSelected;
  final Function(List<Floor>, LocationEntity) onFloorUpdated;

  const LocationConfigurationTab({
    super.key,
    required this.floors,
    required this.selectedListeningAreaId,
    required this.onLocationSelected,
    required this.onFloorUpdated,
  });

  @override
  State<LocationConfigurationTab> createState() => _LocationConfigurationTabState();
}

class _LocationConfigurationTabState extends State<LocationConfigurationTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final TextEditingController roomController = TextEditingController();
  final TextEditingController floorController = TextEditingController();

  Floor? selectedFloor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.black,
            tabs: <Widget>[
              const Tab(text: 'Select'),
              const Tab(text: 'Create new'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    for (final Floor floor in widget.floors) ...<Widget>[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            childrenPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              Icons.home,
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(
                              floor.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            children: <Widget>[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 56,
                                ),
                                itemCount: floor.listeningAreas.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ListeningArea listeningArea = floor.listeningAreas[index];
                                  final bool isSelected = widget.selectedListeningAreaId == listeningArea.id;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withAlpha((0.3 * 255).toInt()),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isSelected ? Theme.of(context).primaryColor.withAlpha((0.05 * 255).toInt()) : Colors.transparent,
                                    ),
                                    child: RadioListTile<String>(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      title: Text(
                                        listeningArea.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      value: listeningArea.id,
                                      groupValue: widget.selectedListeningAreaId,
                                      activeColor: Theme.of(context).primaryColor,
                                      onChanged: (String? val) {
                                        setState(() {
                                          final LocationEntity location = LocationEntity(
                                            floorId: floor.id,
                                            listeningAreaId: val,
                                          );
                                          widget.onLocationSelected(location);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                NewFloorRoomEntry(
                  existingFloors: widget.floors,
                  onFloorUpdated: (List<Floor> updatedFloors, LocationEntity newLocation) {
                    setState(() {
                      widget.onFloorUpdated(updatedFloors, newLocation);
                    });
                  },
                  floorController: floorController,
                  roomController: roomController,
                  updateSelectedFloor: (Floor? value) {
                    setState(() {
                      selectedFloor = value;
                    });
                  },
                  selectedFloor: selectedFloor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewFloorRoomEntry extends StatefulWidget {
  final List<Floor> existingFloors;
  final Function(List<Floor>, LocationEntity) onFloorUpdated;
  final TextEditingController floorController;

  final TextEditingController roomController;
  final Floor? selectedFloor;
  final Function(Floor?) updateSelectedFloor;

  const NewFloorRoomEntry({
    super.key,
    required this.existingFloors,
    required this.onFloorUpdated,
    required this.floorController,
    required this.roomController,
    this.selectedFloor,
    required this.updateSelectedFloor,
  });

  @override
  _NewFloorRoomEntryState createState() => _NewFloorRoomEntryState();
}

class _NewFloorRoomEntryState extends State<NewFloorRoomEntry> {
  bool _isCreatingNewFloor = false;

  void _addNewListeningArea(Floor floor) {
    final String area = widget.roomController.text.trim();
    if (area.isNotEmpty) {
      final ListeningArea newListeningArea = ListeningArea(
        name: area,
        //small Square at center, calculate default vertices for that
        vertices: <Offset>[const Offset(-0.5, -0.5), const Offset(0.5, -0.5), const Offset(0.5, 0.5), const Offset(-0.5, 0.5)],
      );

      floor.listeningAreas.add(newListeningArea);
      widget.onFloorUpdated(widget.existingFloors, LocationEntity(floorId: floor.id, listeningAreaId: newListeningArea.id));
    }
  }

  void _submit() {
    if ((widget.selectedFloor != null || widget.floorController.text.trim().isNotEmpty) && widget.roomController.text.trim().isNotEmpty) {
      final Floor floorEntity =
          widget.selectedFloor ??
          Floor(
            name: widget.floorController.text,
            listeningAreas: <ListeningArea>[],
            floorPlan: FloorPlanEntity.defaultFloorPlan,
          );

      _addNewListeningArea(floorEntity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a floor and enter a room name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Create New Floor'),
              Switch(
                value: _isCreatingNewFloor,
                onChanged: (bool val) {
                  setState(() {
                    widget.updateSelectedFloor(null);
                    _isCreatingNewFloor = val;
                  });
                },
              ),
            ],
          ),
          if (_isCreatingNewFloor)
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: widget.floorController,
                    decoration: const InputDecoration(
                      labelText: 'New Floor Name',
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<Floor>(
                    value: widget.selectedFloor,
                    decoration: const InputDecoration(labelText: 'Select Floor'),
                    items:
                        widget.existingFloors
                            .map(
                              (Floor floor) => DropdownMenuItem<Floor>(
                                value: floor,
                                child: Text(floor.name),
                              ),
                            )
                            .toList(),
                    onChanged: (Floor? value) {
                      setState(() {
                        widget.updateSelectedFloor(value);
                      });
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.roomController,
            decoration: const InputDecoration(
              labelText: 'Area Name',
            ),
          ),
        ],
      ),
    );
  }
}
