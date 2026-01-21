import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

// ignore: constant_identifier_names
const int _MAX_SPEAKER_COUNT = 25;

class SchematicProperties extends StatefulWidget {
  const SchematicProperties({super.key});

  @override
  SchematicPropertiesState createState() => SchematicPropertiesState();
}

class SchematicPropertiesState extends State<SchematicProperties> {
  final TextEditingController speakerQtyController = TextEditingController(text: "1"); // default value 1
  final TextEditingController propertyModelNameController = TextEditingController(text: "1"); // default value 1
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
  bool get isListingViewMode => projectViewModel.currentProjectMode == ProjectMode.systemListingMode;

  int get speakerQty => int.tryParse(speakerQtyController.text) ?? 1;

  void speakerQtyModify({int? qty, bool shouldIncrement = true}) {
    // final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final SelectedItem? selectedItem = context.read<ProjectViewModel>().selectedDevice;
    if (selectedItem == null || selectedItem.type != SelectedItemType.circuit) return;

    final int totalSpeakers = projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList().length;

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
    final List<Speaker> speakers = projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();

    final Speaker speaker = speakers.first.getClone();
    projectViewModel.addHardware(hardware: speaker, autoSave: false);
    projectViewModel.addHardwareToCircuit(hwId: speaker.id, circuitId: selectedItem.id);
  }

  void removeSpeaker() {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final SelectedItem? selectedItem = context.read<ProjectViewModel>().selectedDevice;

    if (selectedItem == null || selectedItem.type != SelectedItemType.circuit) return;
    final List<Speaker> speakers = projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();
    final Speaker speaker = speakers.last;
    projectViewModel.removeHardwareFromCircuit(circuitId: selectedItem.id, hwId: speaker.id);
  }

  @override
  void dispose() {
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
      final List<Speaker> speakers = projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id).whereType<Speaker>().toList();

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
      padding: const EdgeInsets.all(16.0),
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
                    return PropertyTextField(
                      controller: propertyModelNameController,
                      hintText: 'Enter name',
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
                        } else if (selectedItem.type == SelectedItemType.circuit) {
                          final CircuitModel? circuit = projectViewModel.getCircuitById(circuitId: selectedItem.id);
                          projectViewModel.updateCircuit(circuit: circuit!.copyWith(name: value));
                        } else {
                          final HardwareComponent hardware = selectedDevice!.copyWith(name: value);
                          projectViewModel.updateHardware(hardware: hardware);
                        }
                      },
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
                                              projectViewModel.updateZone(zone: selectedZone.copyWith(zoneColor: hexCode));
                                              Navigator.of(context).pop();
                                            },
                                            child: Container(
                                              height: 24,
                                              width: 24,
                                              margin: const EdgeInsets.all(1),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
                                                border: isSelected ? Border.all(color: context.colorScheme.primaryBlack, width: 2) : null,
                                              ),
                                              child:
                                                  isSelected
                                                      ? Container(
                                                        decoration: BoxDecoration(
                                                          color: context.colorScheme.primaryBlack.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(Icons.check, color: Colors.white, size: 16),
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

          if ((selectedItem.type == SelectedItemType.circuit && isListingViewMode)) ...<Widget>[
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
                        child: const Icon(Icons.remove, size: 17),
                        onTap: () => speakerQtyModify(shouldIncrement: false),
                      ),
                      SizedBox(
                        width: 36,
                        child: PropertyTextField(
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
                          if (selectedItem.type == SelectedItemType.zone || selectedItem.type == SelectedItemType.subzone) {
                            return _ZonesListeningAreaSelectionWidget(selectedItem: selectedItem);
                          }

                          return _LocationSelecDropDown(
                            selectedItemType: selectedItem.type,
                            listeningAreas: listeningAreas,
                            selectedListeningAreaIds: selectedListeningAreaIds,
                            onSelectionChanged: (List<String> value) {
                              if (value.isEmpty) return;
                              // As of know, we are using single. In future there might be option
                              // to select multiple. For safer side, here kept List<String>.
                              final String? floorID = projectViewModel.getFloorForListeningArea(areaId: value.first)?.id;
                              final LocationModel newLocation = LocationModel(listeningAreaId: value.first, floorId: floorID);
                              projectViewModel.updateHardwareLocation(hardwareId: selectedDevice!.id, newLocation: newLocation);
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
        ],
      ),
    );
  }
}

class PropertyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final Function(PointerDownEvent event)? onTapOutside;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextAlign? textAlign;

  const PropertyTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.onTapOutside,
    this.keyboardType,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      textAlign: textAlign ?? TextAlign.start,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      onTapOutside: onTapOutside,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.colorScheme.elevation5,
        ),
        isDense: true,
        fillColor: context.colorScheme.elevation1,
        contentPadding: const EdgeInsets.all(8),
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: context.colorScheme.elevation5, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: context.colorScheme.elevation2, width: 1),
        ),
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
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.black38),
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
          text: 'Select device, zone or subzone to view properties',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}

class _LocationSelecDropDown extends StatelessWidget {
  final SelectedItemType selectedItemType;
  final List<ListeningArea> listeningAreas;
  final List<String> selectedListeningAreaIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const _LocationSelecDropDown({
    required this.selectedItemType,
    required this.listeningAreas,
    required this.selectedListeningAreaIds,
    required this.onSelectionChanged,
  });

  void _toggleListeningAreaSelection(BuildContext context, String areaId) {
    final List<String> newSelection = <String>[areaId];
    onSelectionChanged(newSelection);
    Navigator.of(context).pop();
  }

  String _getSelectedAreaDisplayText(BuildContext context) {
    if (selectedListeningAreaIds.isEmpty) return "Select location";

    // Get the first selected area ID
    final String selectedId = selectedListeningAreaIds.first;

    // Find the listening area by ID
    final ListeningArea? selectedArea = listeningAreas.where((ListeningArea area) => area.id == selectedId).firstOrNull;

    if (selectedArea != null) {
      final FloorModel? floorName = context.read<ProjectViewModel>().getFloorForListeningArea(areaId: selectedArea.id);
      return selectedArea.name.isNotEmpty ? "${floorName?.name}/${selectedArea.name}" : 'Unnamed Area';
    }

    return "Unknown Area";
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    return PopupMenuButton<void>(
      tooltip: "Select Location",
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
        side: BorderSide(color: context.colorScheme.elevation4),
      ),
      offset: const Offset(100, 20),
      padding: EdgeInsets.zero,
      color: context.colorScheme.elevation1,
      menuPadding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Builder(
              builder: (BuildContext context) {
                if (selectedItemType == SelectedItemType.zone) {
                  return FusionAppText(
                    text: '${listeningAreas.length} zones selected',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  );
                } else if (selectedItemType == SelectedItemType.subzone) {
                  return FusionAppText(
                    text: '${listeningAreas.length} zones selected',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  );
                }

                return FusionAppText(
                  text: _getSelectedAreaDisplayText(context),
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          if (selectedItemType != SelectedItemType.circuit)
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: context.colorScheme.primaryWhite,
            ),
        ],
      ),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          if (selectedItemType != SelectedItemType.circuit)
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setDropdownState) {
                  return Container(
                    width: 300,
                    constraints: const BoxConstraints(maxHeight: 380, maxWidth: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /// Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: context.colorScheme.elevation2,
                              ),
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
                        if (listeningAreas.isNotEmpty)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  ...listeningAreas.map(
                                    (ListeningArea area) {
                                      final bool isSelected = selectedListeningAreaIds.contains(area.id);

                                      String? zoneName = projectViewModel.getZonesForListeningArea(areaId: area.id)?.name;
                                      if (zoneName == null || zoneName.trim().isEmpty) {
                                        zoneName = projectViewModel.getSubZoneForListeningArea(areaId: area.id)?.name;
                                      }

                                      final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);

                                      return InkWell(
                                        onTap: () => _toggleListeningAreaSelection(context, area.id),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected ? context.colorScheme.elevation2 : null,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              /// Radio Button
                                              Icon(
                                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                size: 16,
                                                color: isSelected ? context.colorScheme.primaryWhite : null,
                                              ),

                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: FusionAppText(
                                                  text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Location',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              FusionAppText(
                                                text: zoneName ?? "No zone",
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
                        /// Create location form
                        AddNewLocationWidget(
                          onLocationAdd: (ListeningArea value) {
                            /// Automatically select the newly created area
                            onSelectionChanged(<String>[value.id]);
                            Navigator.of(context).pop();
                          },
                          onExpanded: (bool value) {},
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
class _ZonesListeningAreaSelectionWidget extends StatelessWidget {
  final SelectedItem selectedItem;
  const _ZonesListeningAreaSelectionWidget({required this.selectedItem});
  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      tooltip: "Select Location",
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
        side: BorderSide(color: context.colorScheme.elevation4),
      ),
      offset: const Offset(100, 20),
      padding: EdgeInsets.zero,
      color: context.colorScheme.elevation1,
      menuPadding: EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                List<ListeningArea> listeningAreas;

                if (selectedItem.type == SelectedItemType.zone) {
                  listeningAreas = projectViewModel.getListeningAreasForZone(zoneId: selectedItem.id);
                } else {
                  listeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: selectedItem.id);
                }

                return FusionAppText(
                  text: listeningAreas.isEmpty ? "Select Location" : "${listeningAreas.length} location${listeningAreas.length > 1 ? '(s)' : ''} selected",
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: listeningAreas.isEmpty ? context.colorScheme.primaryBlack : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          RotatedBox(
            quarterTurns: 2,
            child: FusionSvgIcon(
              icon: AssetSvg.expandUp,
              size: FusionSizes.iconSize12,
              color: context.colorScheme.iconWhite,
            ),
          ),
        ],
      ),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SelectListeningAreaForZoneAndSubzonePopupWidget(
              selectedItem: selectedItem,
            ),
          ),
        ];
      },
    );
  }
}

class SelectListeningAreaForZoneAndSubzonePopupWidget extends StatefulWidget {
  final SelectedItem selectedItem;
  const SelectListeningAreaForZoneAndSubzonePopupWidget({super.key, required this.selectedItem});

  @override
  State<SelectListeningAreaForZoneAndSubzonePopupWidget> createState() => _SelectListeningAreaForZoneAndSubzonePopupWidgetState();
}

class _SelectListeningAreaForZoneAndSubzonePopupWidgetState extends State<SelectListeningAreaForZoneAndSubzonePopupWidget> {
  ValueNotifier<bool> showAddNewLocation = ValueNotifier<bool>(false);
  List<ListeningArea> allListeningAreas = <ListeningArea>[];

  List<ListeningArea> availableListeningAreas = <ListeningArea>[];
  Set<String> selectedListeningAreaIDs = <String>{};

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  void getDetails() {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    late List<ListeningArea> alreadySelectedListeningAreas;

    if (widget.selectedItem.type == SelectedItemType.zone) {
      availableListeningAreas = projectViewModel.getAvailableListeningAreasForZone();
      alreadySelectedListeningAreas = projectViewModel.getListeningAreasForZone(zoneId: widget.selectedItem.id);
    } else {
      final Zone? zone = projectViewModel.getZoneForSubZone(subZoneId: widget.selectedItem.id);
      availableListeningAreas = projectViewModel.getAvailableListeningAreasForSubZone(parentZoneId: zone!.id);
      alreadySelectedListeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: widget.selectedItem.id);
    }

    availableListeningAreas.addAll(alreadySelectedListeningAreas);

    allListeningAreas = projectViewModel.getAllListeningAreas(); // Define helper function to determine priority for each area

    int getPriority(ListeningArea area) {
      final bool isSelected = alreadySelectedListeningAreas.any((ListeningArea e) => e.id == area.id);
      final bool isAvailable = availableListeningAreas.any((ListeningArea e) => e.id == area.id);
      if (isSelected) return 0; // highest priority
      if (isAvailable) return 1;
      return 2; // not available → lowest
    }

    allListeningAreas.sort((ListeningArea a, ListeningArea b) {
      final int priorityA = getPriority(a);
      final int priorityB = getPriority(b);

      // First sort by priority (selected → available → unavailable)
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);

      // Then sort alphabetically by name within each group
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    selectedListeningAreaIDs.addAll(alreadySelectedListeningAreas.map((ListeningArea e) => e.id));
  }

  void onListeningAreaTap(String listeningAreaId) {
    if (selectedListeningAreaIDs.contains(listeningAreaId)) {
      selectedListeningAreaIDs.remove(listeningAreaId);
    } else {
      selectedListeningAreaIDs.add(listeningAreaId);
    }
    setState(() {});
  }

  void onSaveTap() {
    if (selectedListeningAreaIDs.isEmpty) return FusionToast.error(context, message: "Atleast one listening area should be selected");

    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    if (widget.selectedItem.type == SelectedItemType.zone) {
      projectViewModel.updateListeningAreasInZone(zoneId: widget.selectedItem.id, listeningAreaIds: selectedListeningAreaIDs.toList());
    } else {
      projectViewModel.updateListeningAreasInSubZone(subZoneId: widget.selectedItem.id, listeningAreaIds: selectedListeningAreaIDs.toList());
    }
    Navigator.of(context).pop();
  }

  void onNewLocationAdd(ListeningArea value) {
    allListeningAreas.insert(0, value);
    availableListeningAreas.insert(0, value);
    selectedListeningAreaIDs.add(value.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        /// Header with close button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

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
                  color: Theme.of(context).colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: context.colorScheme.elevation2),

        /// Scrollable list of listening areas
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height / 3),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: <Widget>[
                  ...allListeningAreas.map(
                    (ListeningArea area) {
                      final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);

                      String? zoneName = projectViewModel.getZonesForListeningArea(areaId: area.id)?.name;
                      if (zoneName == null || zoneName.trim().isEmpty) {
                        zoneName = projectViewModel.getSubZoneForListeningArea(areaId: area.id)?.name;
                      }

                      /// Check if this area is in the available list
                      final bool isAvailable = availableListeningAreas.any((ListeningArea availableArea) => availableArea.id == area.id);
                      final bool isSelected = selectedListeningAreaIDs.contains(area.id);

                      final bool isAvailableToSelectOrDeselect = isAvailable || zoneName == null;

                      return InkWell(
                        onTap: isSelected || isAvailableToSelectOrDeselect ? () => onListeningAreaTap(area.id) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            children: <Widget>[
                              /// Checkbox for selection
                              SizedBox(
                                width: 14,
                                height: 4,
                                child: Checkbox(
                                  value: !isAvailableToSelectOrDeselect ? true : isSelected,
                                  activeColor: context.colorScheme.elevation5,
                                  onChanged: !isAvailableToSelectOrDeselect ? null : (_) => onListeningAreaTap(area.id),
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
                                  text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Area',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                    color: !isAvailableToSelectOrDeselect ? context.colorScheme.elevation5 : context.colorScheme.textPrimary,
                                  ),
                                ),
                              ),
                              FusionAppText(
                                text: zoneName ?? "No zone",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: context.colorScheme.elevation5,
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
              ),
            ),
          ),
        ),
        AddNewLocationWidget(
          onExpanded: (bool value) => showAddNewLocation.value = value,
          onLocationAdd: onNewLocationAdd,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: showAddNewLocation,
          builder: (BuildContext context, bool isAddNewLocationExpanded, Widget? child) {
            if (isAddNewLocationExpanded) return const SizedBox();

            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
              child: Row(
                spacing: 20,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: FusionAppText(
                      text: "Cancel",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FusionButton(
                    width: 100,
                    label: "Save",
                    onTap: onSaveTap,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class AddNewLocationWidget extends StatefulWidget {
  final ValueChanged<bool> onExpanded;
  final ValueChanged<ListeningArea> onLocationAdd;
  const AddNewLocationWidget({super.key, required this.onLocationAdd, required this.onExpanded});

  @override
  State<AddNewLocationWidget> createState() => _AddNewLocationWidgetState();
}

class _AddNewLocationWidgetState extends State<AddNewLocationWidget> {
  bool _isExpanded = false;
  FloorModel? _selectedFloor;
  final TextEditingController locationNameController = TextEditingController();

  bool get isDetailsFilled => locationNameController.text.trim().isNotEmpty && (_selectedFloor?.id.isNotEmpty ?? false);

  @override
  void dispose() {
    super.dispose();
    locationNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Column(
        children: <Widget>[
          /// Header
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onExpanded.call(_isExpanded);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
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
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          /// Expanded form
          if (_isExpanded) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.colorScheme.elevation1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Floor label
                  FusionAppText(
                    text: "Floor",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Floor dropdown
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.elevation1,
                      border: Border.all(color: Theme.of(context).colorScheme.elevation3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Theme.of(context).colorScheme.elevation1,
                        hint: FusionAppText(
                          text: "Select floor",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _selectedFloor?.name,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        items: <DropdownMenuItem<String>>[
                          ...serviceLocator<ProjectViewModel>().getAllFloors().map((FloorModel floor) {
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
                            setState(() {
                              _selectedFloor = serviceLocator<ProjectViewModel>().getAllFloors().firstWhere((FloorModel f) => f.name == newValue);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Location Name
                  FusionAppText(
                    text: "Location Name",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  PropertyTextField(
                    controller: locationNameController,
                    hintText: "Enter location name",
                  ),
                  const SizedBox(height: 12),

                  FusionButton(
                    height: 32,
                    width: double.infinity,
                    label: "Add",
                    onTap: () {
                      if (isDetailsFilled) {
                        final String locationName = locationNameController.text.trim();

                        final ListeningArea newListeningArea = ListeningArea(
                          name: locationName,
                          vertices: <Offset>[],
                          isDrawn: false,
                        );

                        final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
                        projectViewModel.addListeningArea(area: newListeningArea, floorId: _selectedFloor!.id);
                        widget.onLocationAdd.call(newListeningArea);
                        setState(() => _isExpanded = !_isExpanded);
                        widget.onExpanded.call(_isExpanded);
                      } else {
                        FusionToast.error(
                          context,
                          message: "Please enter location name and select a floor",
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
