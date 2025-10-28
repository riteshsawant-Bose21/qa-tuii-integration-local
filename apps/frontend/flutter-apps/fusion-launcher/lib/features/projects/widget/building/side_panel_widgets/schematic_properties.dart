import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

// ignore: constant_identifier_names
const int _MAX_SPEAKER_COUNT = 25;

class SchematicProperties extends StatefulWidget {
  const SchematicProperties({super.key});

  @override
  SchematicPropertiesState createState() => SchematicPropertiesState();
}

class SchematicPropertiesState extends State<SchematicProperties> {
  final ExpansibleController viewMoreExpansibleController = ExpansibleController();
  final TextEditingController speakerQtyController = TextEditingController(text: "1"); // default value 1
  final TextEditingController propertyModelNameController = TextEditingController(text: "1"); // default value 1

  int get speakerQty => int.tryParse(speakerQtyController.text) ?? 1;

  void speakerQtyModify({int? qty, bool shouldIncrement = true}) {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final SelectedItem? selectedItem = context.read<ProjectViewModel>().selectedDevice;
    if (selectedItem == null || selectedItem.type != SelectedItemType.circuit) return;

    final int totalSpeakers =
        projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList().length;

    if (shouldIncrement && (qty ?? totalSpeakers) >= _MAX_SPEAKER_COUNT) {
      return FusionToast.error(context, message: "Maximum speaker count reached");
    }

    if (qty != null) {
      if (qty > totalSpeakers) {
        final int toAdd = qty - totalSpeakers;
        for (int i = 0; i < toAdd; i++) {
          addSpeaker();
        }
      } else if (qty < totalSpeakers) {
        final int toRemove = totalSpeakers - qty;
        for (int i = 0; i < toRemove; i++) {
          removeSpeaker();
        }
      }
    } else {
      final int newValue = shouldIncrement ? speakerQty + 1 : speakerQty - 1;
      speakerQtyController.text = newValue.toString();
      if (shouldIncrement) {
        addSpeaker();
      } else {
        removeSpeaker();
      }
    }
  }

  void addSpeaker() {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final SelectedItem? selectedItem = context.read<ProjectViewModel>().selectedDevice;

    if (selectedItem == null || selectedItem.type != SelectedItemType.circuit) return;
    final List<Speaker> speakers =
        projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();

    final Speaker speaker = speakers.first.getClone();
    projectViewModel.addHardware(hardware: speaker, autoSave: false);
    projectViewModel.addHardwareToCircuit(
      hwId: speaker.id,
      circuitId: selectedItem.id,
    );
  }

  void removeSpeaker() {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final SelectedItem? selectedItem = context.read<ProjectViewModel>().selectedDevice;

    if (selectedItem == null || selectedItem.type != SelectedItemType.circuit) return;
    final List<Speaker> speakers =
        projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();
    final Speaker speaker = speakers.last;
    projectViewModel.removeHardwareFromCircuit(circuitId: selectedItem.id, hwId: speaker.id);
  }

  @override
  void dispose() {
    viewMoreExpansibleController.dispose();
    propertyModelNameController.dispose();
    speakerQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SelectedItem? selectedItem = context.watch<ProjectViewModel>().selectedDevice;

    if (selectedItem?.id == null || selectedItem?.type == null) {
      return const _NoPropertiesWidget();
    }

    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();

    late final HardwareComponent? selectedDevice;

    String? assetImagePath;
    if (selectedItem!.type == SelectedItemType.circuit) {
      final List<Speaker> speakers =
          projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();

      if (speakers.isEmpty) return const _NoPropertiesWidget();
      selectedDevice = speakers.first;
      assetImagePath = selectedDevice.assetImagePath;
    } else {
      selectedDevice = projectViewModel.getHardware(hardwareId: selectedItem.id);
      assetImagePath = selectedDevice?.assetImagePath;
    }

    if (selectedItem.type == SelectedItemType.zone) {
      final Zone? zone = projectViewModel.getZone(zoneId: selectedItem.id);
      propertyModelNameController.text = zone?.name ?? 'No zone name';
    } else if (selectedItem.type == SelectedItemType.subzone) {
      final SubZone? subzone = projectViewModel.getSubZone(subZoneId: selectedItem.id);
      propertyModelNameController.text = subzone?.name ?? 'No Name';
    } else {
      propertyModelNameController.text = selectedDevice?.name ?? '';
    }

    speakerQtyController.text =
        selectedItem.type == SelectedItemType.circuit
            ? projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().length.toString()
            : '1';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          if (selectedItem.type != SelectedItemType.zone && selectedItem.type != SelectedItemType.subzone) ...<Widget>[
            Center(
              child: Builder(
                builder: (BuildContext context) {
                  if (assetImagePath == null || assetImagePath.isEmpty) {
                    return const SizedBox(
                      width: 118,
                      height: 118,
                      child: Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return Image.asset(assetImagePath, width: 118);
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Name',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    return TextField(
                      controller: propertyModelNameController,
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      onTapOutside: (PointerDownEvent event) {
                        final String value = propertyModelNameController.text.trim();
                        if (value.isEmpty) return FusionToast.error(context, message: "Name should not be empty");

                        if (selectedItem.type == SelectedItemType.zone) {
                          final Zone? zone = projectViewModel.getZone(zoneId: selectedItem.id);
                          projectViewModel.updateZone(zone: zone!.copyWith(name: value));
                        } else if (selectedItem.type == SelectedItemType.subzone) {
                          final SubZone? subzone = projectViewModel.getSubZone(subZoneId: selectedItem.id);
                          projectViewModel.updateSubZone(subZone: subzone!.copyWith(name: value));
                        } else {
                          final HardwareComponent hardware = selectedDevice!.copyWith(name: value);
                          projectViewModel.updateHardware(hardware: hardware);
                        }
                      },
                      onSubmitted: (String value) {
                        if (value.trim().isEmpty) {
                          return FusionToast.error(context, message: "Name should not be empty");
                        } else if (selectedItem.type == SelectedItemType.zone) {
                          final Zone? zone = projectViewModel.getZone(zoneId: selectedItem.id);
                          projectViewModel.updateZone(zone: zone!.copyWith(name: value));
                        } else if (selectedItem.type == SelectedItemType.subzone) {
                          final SubZone? subzone = projectViewModel.getSubZone(subZoneId: selectedItem.id);
                          projectViewModel.updateSubZone(subZone: subzone!.copyWith(name: value));
                        } else {
                          final HardwareComponent hardware = selectedDevice!.copyWith(name: value);
                          projectViewModel.updateHardware(hardware: hardware);
                        }
                      },
                      style: Theme.of(context).textTheme.bodySmall,
                      decoration: const InputDecoration.collapsed(hintText: 'Enter model name'),
                    );
                  },
                ),
              ),
            ],
          ),

          if (selectedItem.type == SelectedItemType.zone) ...<Widget>[
            Builder(
              builder: (BuildContext context) {
                final Zone? zone = projectViewModel.getZone(zoneId: selectedItem.id);
                if (zone == null) return const SizedBox();

                return Row(
                  spacing: 3,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: 'Zone color',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Flexible(
                      child: PopupMenuButton<String>(
                        position: PopupMenuPosition.under,
                        shadowColor: Colors.transparent,
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          side: BorderSide(color: Colors.black12),
                        ),
                        surfaceTintColor: Colors.transparent,
                        tooltip: "Select zone color",
                        child: Container(
                          height: 24,
                          width: 24,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: zone.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Builder(
                                builder: (BuildContext context) {
                                  final Zone? selectedZone = projectViewModel.getZone(zoneId: selectedItem.id);
                                  final Color? selectedColor = selectedZone?.color;

                                  return Wrap(
                                    children: <Widget>[
                                      ...Zone.zoneColors.map(
                                        (String hexCode) {
                                          final Color color = hexToColor(hexCode);
                                          final bool isSelected = selectedColor == color;

                                          return GestureDetector(
                                            onTap: () {
                                              if (selectedZone == null) return;
                                              projectViewModel.updateZone(
                                                zone: selectedZone.copyWith(zoneColor: hexCode),
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: Container(
                                              height: 24,
                                              width: 24,
                                              margin: const EdgeInsets.all(1),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
                                                border:
                                                    isSelected
                                                        ? Border.all(
                                                          color: Theme.of(context).colorScheme.greyDark,
                                                          width: 2,
                                                        )
                                                        : null,
                                              ),
                                              child:
                                                  isSelected
                                                      ? Container(
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.greyDark.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      )
                                                      : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          if (!<SelectedItemType>[
            SelectedItemType.zone,
            SelectedItemType.subzone,
          ].contains(selectedItem.type)) ...<Widget>[
            Row(
              spacing: 3,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Model',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: FusionAppText(
                    text: selectedDevice?.hardwareName ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],

          if (selectedItem.type == SelectedItemType.circuit) ...<Widget>[
            Row(
              spacing: 3,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Speaker Qty',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Row(
                    spacing: 3,
                    children: <Widget>[
                      GestureDetector(
                        child: const Icon(
                          Icons.remove,
                          size: 17,
                        ),
                        onTap: () => speakerQtyModify(shouldIncrement: false),
                      ),
                      Flexible(
                        child: Container(
                          width: 36,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: speakerQtyController,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            onSubmitted: (String value) {
                              if (value.isEmpty) return;
                              final int? modifiedQty = int.tryParse(value);
                              if (modifiedQty == null) return;
                              if (modifiedQty > _MAX_SPEAKER_COUNT) {
                                return FusionToast.error(
                                  context,
                                  message: "Count should be between 1 and $_MAX_SPEAKER_COUNT",
                                );
                              }
                              speakerQtyModify(qty: modifiedQty);
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration.collapsed(hintText: '0'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: const Icon(
                          Icons.add,
                          size: 17,
                        ),
                        onTap: () => speakerQtyModify(shouldIncrement: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (!<SelectedItemType>[
            SelectedItemType.zone,
            SelectedItemType.subzone,
          ].contains(selectedItem.type)) ...<Widget>[
            Row(
              spacing: 3,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Price',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: FusionAppText(
                    text: '\$${selectedDevice?.price.toStringAsFixed(2) ?? '0.00'}',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],

          if (!<SelectedItemType>[
            SelectedItemType.processor,
            SelectedItemType.amplifier,
          ].contains(selectedItem.type)) ...<Widget>[
            Builder(
              builder: (BuildContext context) {
                List<ListeningArea> listeningAreas = <ListeningArea>[];

                if (selectedItem.type == SelectedItemType.circuit && selectedDevice is Speaker) {
                  final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: selectedDevice.id);
                  if (subZone?.id != null) {
                    listeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: subZone!.id);
                  } else {
                    final Zone? zone = projectViewModel.getZoneForHardware(hardwareId: selectedDevice.id);
                    log("${zone?.name.toString()} zone found for hardware ${selectedDevice.id}");
                    if (zone?.id != null) listeningAreas = projectViewModel.getListeningAreasForZone(zoneId: zone!.id);
                  }
                } else {
                  if (selectedItem.type == SelectedItemType.zone) {
                    listeningAreas = projectViewModel.getAvailableListeningAreasForZone(zoneId: selectedItem.id);
                  } else if (selectedItem.type == SelectedItemType.subzone) {
                    listeningAreas = projectViewModel.getAvailableListeningAreasForZone();
                  } else {
                    listeningAreas = projectViewModel.getAllListeningAreas();
                  }
                }

                log("========== ${listeningAreas.length} listening areas found for circuit ${selectedItem.id}");

                final List<String> selectedListeningAreaIds =
                    listeningAreas
                        .where((ListeningArea area) => area.id == selectedDevice?.locationEntity.listeningAreaId)
                        .map((ListeningArea area) => area.id)
                        .toList();

                return Row(
                  spacing: 3,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: 'Location',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (BuildContext context) {
                          if (selectedItem.type == SelectedItemType.zone ||
                              selectedItem.type == SelectedItemType.subzone) {
                            return _CreateZoneListeningAreaSelectorDropDown(
                              selectedItem: selectedItem,
                            );
                          }

                          return _LocationSelecDropDown(
                            selectedItemType: selectedItem.type,
                            listeningAreas: listeningAreas,
                            selectedListeningAreaIds: selectedListeningAreaIds,
                            onSelectionChanged: (List<String> value, String floorId) {
                              if (value.isEmpty) return;
                              final LocationModel newLocation = LocationModel(
                                listeningAreaId: value.first,
                                floorId: floorId,
                              );
                              projectViewModel.updateHardwareLocation(
                                hardwareId: selectedDevice!.id,
                                newLocation: newLocation,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          Expansible(
            controller: viewMoreExpansibleController,
            headerBuilder: (BuildContext context, Animation<double> animation) {
              final bool isExpanded = viewMoreExpansibleController.isExpanded;

              return GestureDetector(
                onTap: () {
                  if (viewMoreExpansibleController.isExpanded) {
                    viewMoreExpansibleController.collapse();
                  } else {
                    viewMoreExpansibleController.expand();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isExpanded ? 10.0 : 0.0),
                  child: FusionAppText(
                    text: isExpanded ? 'view less' : 'view more',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF186E79)),
                  ),
                ),
              );
            },
            expansibleBuilder: (BuildContext context, Widget header, Widget body, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: body,
                  ),
                  header,
                ],
              );
            },
            bodyBuilder: (BuildContext context, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: <Widget>[
                  Row(
                    spacing: 3,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Serial Number',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: FusionAppText(
                          text: "DG221G28983",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Convert hex string to Color
Color hexToColor(String hexString) {
  final StringBuffer buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black38),
    );
  }
}

class _NoPropertiesWidget extends StatelessWidget {
  const _NoPropertiesWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FusionAppText(
          text: 'Select a device to view its properties',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}

class _LocationSelecDropDown extends StatefulWidget {
  final SelectedItemType selectedItemType;
  final List<ListeningArea> listeningAreas;
  final List<String> selectedListeningAreaIds;
  final Function(List<String>, String floorId) onSelectionChanged;

  const _LocationSelecDropDown({
    required this.selectedItemType,
    required this.listeningAreas,
    required this.selectedListeningAreaIds,
    required this.onSelectionChanged,
  });

  @override
  State<_LocationSelecDropDown> createState() => _LocationSelecDropDownState();
}

class _LocationSelecDropDownState extends State<_LocationSelecDropDown> {
  bool showCreateNewLocationForm = false;
  final TextEditingController _areaNameController = TextEditingController();
  String _selectedFloor = '';
  String _selectedFloorId = '';

  @override
  void initState() {
    super.initState();
    // Initialize with current floor data
    final FloorModel currentFloor = context.read<ProjectViewModel>().currentFloor;
    _selectedFloor = currentFloor.name;
    _selectedFloorId = currentFloor.id;
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    super.dispose();
  }

  /// Toggle selection of a listening area
  void _toggleListeningAreaSelection(String areaId, String floorId) {
    final List<String> newSelection = <String>[areaId];
    widget.onSelectionChanged(newSelection, floorId);
    Navigator.of(context).pop();
  }

  /// Create a new listening area
  // TODO: while creating new area, there is a issue that i dont know where the location is saved.
  void _createNewArea({required String floorId}) {
    if (_areaNameController.text.trim().isNotEmpty && floorId.isNotEmpty) {
      final ListeningArea newListeningArea = ListeningArea(
        name: _areaNameController.text.trim(),
        vertices: <Offset>[const Offset(0, 0), const Offset(100, 0), const Offset(100, 100), const Offset(0, 100)],
      );

      try {
        context.read<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);

        /// Clear form and close expansion
        _areaNameController.clear();
        setState(() => showCreateNewLocationForm = false);

        /// Show success message
        FusionToast.success(context, message: "Listening area '${newListeningArea.name}' created successfully");

        /// Automatically select the newly created area
        widget.onSelectionChanged(<String>[newListeningArea.id], floorId);
        Navigator.of(context).pop();
      } catch (e) {
        FusionToast.error(context, message: "Failed to create location: $e");
      }
    } else {
      FusionToast.error(context, message: "Please enter location name and select a floor");
    }
  }

  String _getSelectedAreaDisplayText() {
    if (widget.selectedListeningAreaIds.isEmpty) return "Select location";

    // Get the first selected area ID
    final String selectedId = widget.selectedListeningAreaIds.first;

    // Find the listening area by ID
    final ListeningArea? selectedArea =
        widget.listeningAreas.where((ListeningArea area) => area.id == selectedId).firstOrNull;

    if (selectedArea != null) {
      final FloorModel? floorName = context.read<ProjectViewModel>().getFloorForListeningArea(areaId: selectedArea.id);
      return selectedArea.name.isNotEmpty ? "${floorName?.name}/${selectedArea.name}" : 'Unnamed Area';
    }

    return "Unknown Area";
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: "Select Location",
      constraints: const BoxConstraints(
        maxHeight: 400,
        maxWidth: 300,
      ),
      position: PopupMenuPosition.under,
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Builder(
              builder: (BuildContext context) {
                if (widget.selectedItemType == SelectedItemType.zone) {
                  return FusionAppText(
                    text: '${widget.listeningAreas.length} zones selected',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  );
                } else if (widget.selectedItemType == SelectedItemType.subzone) {
                  return FusionAppText(
                    text: '${widget.listeningAreas.length} zones selected',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  );
                }

                return FusionAppText(
                  text: _getSelectedAreaDisplayText(),
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          if (widget.selectedItemType != SelectedItemType.circuit)
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
        ],
      ),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          if (widget.selectedItemType != SelectedItemType.circuit)
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setDropdownState) {
                  return Container(
                    width: 300,
                    constraints: const BoxConstraints(
                      maxHeight: 380,
                      maxWidth: 300,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /// Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: "Location",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                        /// Listening Areas List
                        if (widget.listeningAreas.isNotEmpty)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  ...widget.listeningAreas.map(
                                    (ListeningArea area) {
                                      final bool isSelected = widget.selectedListeningAreaIds.contains(area.id);
                                      final Zone? zoneData = context.read<ProjectViewModel>().getZonesForListeningArea(
                                        areaId: area.id,
                                      );
                                      final FloorModel? floorName = context
                                          .read<ProjectViewModel>()
                                          .getFloorForListeningArea(areaId: area.id);

                                      return InkWell(
                                        onTap: () {
                                          _toggleListeningAreaSelection(area.id, floorName?.id ?? '');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Theme.of(context).colorScheme.grey : null,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              /// Radio Button
                                              Radio<String>(
                                                value: area.id,
                                                activeColor: Theme.of(context).colorScheme.greyDark,
                                                groupValue:
                                                    widget.selectedListeningAreaIds.isNotEmpty
                                                        ? widget.selectedListeningAreaIds.first
                                                        : null,
                                                onChanged: (String? value) {
                                                  if (value != null) {
                                                    _toggleListeningAreaSelection(value, floorName?.id ?? '');
                                                  }
                                                },
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: FusionAppText(
                                                  text:
                                                      area.name.isNotEmpty
                                                          ? "${floorName?.name}/${area.name}"
                                                          : 'Unnamed Location',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              FusionAppText(
                                                text: zoneData?.name ?? "No zone",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 9,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        /// Create New Location Section
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              /// Create LoCATION Header
                              InkWell(
                                onTap: () {
                                  setDropdownState(() {
                                    showCreateNewLocationForm = !showCreateNewLocationForm;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12, right: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: FusionAppText(
                                          text: "Create new location",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        showCreateNewLocationForm
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// Create location form
                              if (showCreateNewLocationForm)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      /// Floor Dropdown
                                      FusionAppText(
                                        text: "Floor",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.white,
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Builder(
                                          builder: (BuildContext context) {
                                            return DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                dropdownColor: Theme.of(context).colorScheme.white,
                                                hint: const FusionAppText(text: "Select floor"),
                                                value: _selectedFloor,
                                                isExpanded: true,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                items: <DropdownMenuItem<String>>[
                                                  ...context.read<ProjectViewModel>().getAllFloors().map((
                                                    FloorModel floor,
                                                  ) {
                                                    return DropdownMenuItem<String>(
                                                      value: floor.name,
                                                      child: FusionAppText(
                                                        text: floor.name,
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                      ),
                                                    );
                                                  }),
                                                ],
                                                onChanged: (String? newValue) {
                                                  if (newValue != null) {
                                                    setDropdownState(() {
                                                      _selectedFloor = newValue;
                                                      _selectedFloorId =
                                                          context
                                                              .read<ProjectViewModel>()
                                                              .getAllFloors()
                                                              .firstWhere((FloorModel floor) => floor.name == newValue)
                                                              .id;
                                                    });
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      /// location Name Field
                                      FusionAppText(
                                        text: "Location Name",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FusionTextField(
                                        controller: _areaNameController,
                                        hintText: "Enter location name",
                                        decoration: FusionInputDecoration.fusionDense(
                                          colorScheme: Theme.of(context).colorScheme,
                                          hintText: 'Enter location name',
                                        ),
                                        onChanged: (String value) {
                                          setDropdownState(() {}); // Update button state
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      /// Create and Select Button
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FusionButton(
                                          height: 32,
                                          label: "Add",
                                          isActive:
                                              _areaNameController.text.trim().isNotEmpty &&
                                              _selectedFloorId.isNotEmpty,
                                          onTap: () {
                                            _createNewArea(floorId: _selectedFloorId);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ];
      },
    );
  }
}

// THIS IS FOR ZONE AND SUBZONE.
class _CreateZoneListeningAreaSelectorDropDown extends StatefulWidget {
  final SelectedItem selectedItem;
  const _CreateZoneListeningAreaSelectorDropDown({required this.selectedItem});

  @override
  State<_CreateZoneListeningAreaSelectorDropDown> createState() => _CreateZoneListeningAreaSelectorDropDownState();
}

class _CreateZoneListeningAreaSelectorDropDownState extends State<_CreateZoneListeningAreaSelectorDropDown> {
  bool isCreateAreaExpanded = false;
  final String selectedFloor = '';
  final String selectedFloorId = '';
  final TextEditingController areaNameController = TextEditingController();

  void onLocationSaveTap(String areaID, StateSetter popupSetState) {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();

    if (widget.selectedItem.type == SelectedItemType.zone) {
      final List<String> selectedListeningAreaIds =
          projectViewModel
              .getListeningAreasForZone(zoneId: widget.selectedItem.id)
              .map((ListeningArea e) => e.id)
              .toList();

      if (selectedListeningAreaIds.contains(areaID)) {
        selectedListeningAreaIds.remove(areaID);
      } else {
        selectedListeningAreaIds.add(areaID);
      }

      projectViewModel.updateListeningAreasInZone(
        zoneId: widget.selectedItem.id,
        listeningAreaIds: selectedListeningAreaIds,
      );
    } else {
      final List<String> selectedListeningAreaIds =
          projectViewModel
              .getListeningAreasInSubZone(subZoneId: widget.selectedItem.id)
              .map((ListeningArea e) => e.id)
              .toList();

      if (selectedListeningAreaIds.contains(areaID)) {
        selectedListeningAreaIds.remove(areaID);
      } else {
        selectedListeningAreaIds.add(areaID);
      }

      projectViewModel.updateListeningAreasInSubZone(
        subZoneId: widget.selectedItem.id,
        listeningAreaIds: selectedListeningAreaIds,
      );
    }

    popupSetState(() {});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    final List<ListeningArea> allListeningAreas = projectViewModel.getAllListeningAreas();

    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.white,
      position: PopupMenuPosition.under,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

                List<ListeningArea> listeningAreas;

                if (widget.selectedItem.type == SelectedItemType.zone) {
                  listeningAreas = projectViewModel.getListeningAreasForZone(
                    zoneId: widget.selectedItem.id,
                  );
                } else {
                  listeningAreas = projectViewModel.getListeningAreasInSubZone(
                    subZoneId: widget.selectedItem.id,
                  );
                }

                return FusionAppText(
                  text:
                      listeningAreas.isEmpty
                          ? "Select Location"
                          : "${listeningAreas.length} location${listeningAreas.length > 1 ? '(s)' : ''} selected",
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        listeningAreas.isEmpty
                            ? Theme.of(context).colorScheme.greyDark
                            : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                );
              },
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Theme.of(context).colorScheme.greyDark,
          ),
        ],
      ),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) popupSetState) {
                List<ListeningArea> availableListeningAreas;
                List<ListeningArea> zoneOrSubZoneListeningAreas;

                if (widget.selectedItem.type == SelectedItemType.zone) {
                  availableListeningAreas = projectViewModel.getAvailableListeningAreasForZone();

                  zoneOrSubZoneListeningAreas = projectViewModel.getListeningAreasForZone(
                    zoneId: widget.selectedItem.id,
                  );
                } else {
                  final Zone? zone = projectViewModel.getZoneForSubZone(subZoneId: widget.selectedItem.id);
                  availableListeningAreas = projectViewModel.getAvailableListeningAreasForSubZone(
                    parentZoneId: zone!.id,
                  );

                  zoneOrSubZoneListeningAreas = projectViewModel.getListeningAreasInSubZone(
                    subZoneId: widget.selectedItem.id,
                  );
                }

                allListeningAreas.sort((ListeningArea a, ListeningArea b) {
                  final bool selected = zoneOrSubZoneListeningAreas.any((ListeningArea element) => element.id == a.id);
                  final bool available = availableListeningAreas.any((ListeningArea element) => element.id == a.id);
                  return selected || available ? -1 : 1;
                });

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    /// Header with close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: "Select Locations",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: Navigator.of(context).pop,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context).colorScheme.fusionTextViewColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Scrollable list of listening areas
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Builder(
                          builder: (BuildContext context) {
                            return Column(
                              children: <Widget>[
                                ...allListeningAreas.map(
                                  (ListeningArea area) {
                                    final FloorModel? floorName = projectViewModel.getFloorForListeningArea(
                                      areaId: area.id,
                                    );

                                    final Zone? zoneData = projectViewModel.getZonesForListeningArea(
                                      areaId: area.id,
                                    );

                                    /// Check if this area is in the available list
                                    final bool isAvailable = availableListeningAreas.any(
                                      (ListeningArea availableArea) => availableArea.id == area.id,
                                    );

                                    bool isAlreadySelectedInZone;
                                    if (widget.selectedItem.type == SelectedItemType.zone) {
                                      isAlreadySelectedInZone = projectViewModel
                                          .getListeningAreasForZone(zoneId: widget.selectedItem.id)
                                          .any((ListeningArea element) => element.id == area.id);
                                    } else {
                                      isAlreadySelectedInZone = projectViewModel
                                          .getListeningAreasInSubZone(subZoneId: widget.selectedItem.id)
                                          .any((ListeningArea element) => element.id == area.id);
                                    }

                                    return InkWell(
                                      onTap:
                                          isAlreadySelectedInZone || isAvailable
                                              ? () => onLocationSaveTap(area.id, popupSetState)
                                              : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        child: Row(
                                          children: <Widget>[
                                            /// Checkbox for selection
                                            SizedBox(
                                              width: 14,
                                              height: 4,
                                              child: Checkbox(
                                                value: !isAvailable ? true : isAlreadySelectedInZone,
                                                activeColor: Theme.of(context).colorScheme.greyDark,
                                                onChanged:
                                                    !isAvailable && !isAlreadySelectedInZone
                                                        ? null
                                                        : (bool? v) => onLocationSaveTap(area.id, popupSetState),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.compact,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.zero,
                                                  side: BorderSide(width: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            /// Area and zone names
                                            Expanded(
                                              child: FusionAppText(
                                                text:
                                                    area.name.isNotEmpty
                                                        ? "${floorName?.name}/${area.name}"
                                                        : 'Unnamed Area',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10,
                                                  color:
                                                      !isAvailable && !isAlreadySelectedInZone
                                                          ? Colors.grey[400]
                                                          : Theme.of(context).textTheme.bodySmall?.color,
                                                ),
                                              ),
                                            ),
                                            FusionAppText(
                                              text: zoneData?.name ?? "No zone",
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 9,
                                                color:
                                                    !isAvailable && !isAlreadySelectedInZone
                                                        ? Theme.of(context).colorScheme.grey
                                                        : Theme.of(context).colorScheme.greyDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ];
      },
    );
  }
}
