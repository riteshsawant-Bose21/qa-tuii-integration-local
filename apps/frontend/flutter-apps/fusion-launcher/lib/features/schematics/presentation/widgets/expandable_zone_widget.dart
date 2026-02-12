import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/select_speaker_popup.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/assets/asset_svg.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'circuit_device_widget.dart';
import 'create_new_location_widget.dart';
import 'expandable_sub_zone_widgets.dart';

class ExpandableZoneWidget extends StatefulWidget {
  final int index;
  final String zoneName;
  final String zoneId;
  final Color bgColor;
  final Function(String)? onDelete;
  final bool initiallyExpanded;
  final List<CircuitModel> zoneCircuits;
  final List<SubZone> subZones;

  const ExpandableZoneWidget({
    super.key,
    required this.index,
    required this.zoneName,
    required this.zoneId,
    required this.bgColor,
    this.onDelete,
    this.initiallyExpanded = false,
    required this.subZones,
    required this.zoneCircuits,
  });

  @override
  State<ExpandableZoneWidget> createState() => _ExpandableZoneWidgetState();
}

class _ExpandableZoneWidgetState extends State<ExpandableZoneWidget> {
  late ValueNotifier<bool> _isZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  final TextEditingController _zoneNameController = TextEditingController();
  List<String> _selectedListeningAreaIds = <String>[];
  bool showSubzonePopup = false;
  bool isKebabMenuOpen = false;
  bool isHovered = false;

  List<Map<String, dynamic>> newlyCreatedAreas = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(widget.initiallyExpanded);
  }

  @override
  void dispose() {
    _isZoneExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isZoneExpanded,
      builder: (BuildContext context, bool zoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            final bool isSelected = selectedDevice?.id == widget.zoneId && selectedDevice?.type == SelectedItemType.zone;

            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_item_${widget.index}"),
              child: Column(
                children: <Widget>[
                  MouseRegion(
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: _buildZoneHeader(
                      context: context,
                      expanded: zoneExpanded,
                      isHovered: isHovered,
                      isSelected: isSelected,
                      index: widget.index,
                    ),
                  ),

                  /// Zone Content - shows subzones when expanded
                  if (zoneExpanded) _buildZoneContent(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Zone header - always visible
  Widget _buildZoneHeader({
    required BuildContext context,
    required bool expanded,
    required bool isHovered,
    required bool isSelected,
    required int index,
  }) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_header_container_$index"),
      child: Container(
        height: 36,
        width: double.infinity,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FusionSizes.borderRadius8),
          color: isHovered ? widget.bgColor.withAlpha(80) : widget.bgColor.withAlpha(100),
          border: Border.all(color: isSelected ? context.colorScheme.elevation5 : Colors.transparent),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.drag_indicator,
              size: FusionSizes.iconSize16,
              color: context.colorScheme.textPlaceholder,
            ),
            const SizedBox(width: 4),

            /// Expand/collapse icon
            GestureDetector(
              onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_expand_collapse_icon_container_$index"),
                child: _buildExpandIcon(context, expanded),
              ),
            ),
            const SizedBox(width: 4),

            /// Zone name
            Expanded(
              child: GestureDetector(
                onTap: () {
                  /// Select zone on tap
                  _projectViewModel.setSelectedDevice(widget.zoneId, SelectedItemType.zone);
                },
                // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
                child: _buildZoneName(
                  context: context,
                  name: widget.zoneName,
                ),
              ),
            ),
            const SizedBox(width: 4),

            /// Add device button
            if (widget.subZones.isEmpty)
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "add_speakers_menu_container_$index"),
                child: FusionArrowPopup(
                  content: SpeakerQueryPopup(isFromBuildingPage: false, zoneId: widget.zoneId),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        LucideIcons.plus200,
                        size: FusionSizes.fontSize12,
                        color: context.colorScheme.primaryWhite,
                      ),
                      const SizedBox(width: 4),
                      FusionAppText(
                        text: "Speaker",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w400,
                          color: context.colorScheme.primaryWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),

            /// Kebab menu for zone actions
            SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_kebab_menu_container_$index"),
              child: _buildKebabMenu(context: context, zoneId: widget.zoneId),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Zone content (visible when expanded) - contains reorderable subzones
  Widget _buildZoneContent() {
    if (widget.subZones.isEmpty && widget.zoneCircuits.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.bgColor.withAlpha(60),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(FusionSizes.borderRadius4),
          ),
        ),
        // padding: const EdgeInsets.all(30),
        child: const Center(
          child: Text(
            'No devices / subzones added yet',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "zones_content"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation3.withAlpha(50),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(FusionSizes.borderRadius4),
          ),
        ),
        child: Column(
          children: <Widget>[
            /// Zone devices list
            if (widget.zoneCircuits.isNotEmpty) ...<Widget>[
              BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: widget.zoneCircuits.length,
                    padding: EdgeInsets.zero,
                    onReorder: (int oldIndex, int newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      _projectViewModel.reOrderCircuitInZone(parentId: widget.zoneId, oldIndex: oldIndex, newIndex: newIndex);
                      _projectViewModel.setSelectedDevice(widget.zoneCircuits[oldIndex].id, SelectedItemType.circuit);
                    },
                    proxyDecorator: (Widget child, int index, Animation<double> animation) => child,
                    itemBuilder: (BuildContext context, int index) {
                      final CircuitModel circuitData = widget.zoneCircuits[index];
                      final List<Speaker> speakers = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
                      final String deviceId = circuitData.id;
                      final List<ListeningArea> location = _projectViewModel.getListeningAreasForCircuit(circuitId: circuitData.id);

                      return DragTarget<CircuitModel>(
                        key: ValueKey<String>(deviceId),
                        // ignore: deprecated_member_use
                        onWillAccept: (CircuitModel? incoming) {
                          /// Only accept if the incoming circuit has the same name but different ID
                          ///
                          if (incoming == null) return false;
                          // return incoming != null && incoming.name == circuitData.name && incoming.id != circuitData.id;
                          // _projectViewModel.setSelectedDevice(circuitData.id, SelectedItemType.circuit);
                          if (circuitData.addedInBuildingPage || incoming.addedInBuildingPage) {
                            return false;
                          }
                          final List<Speaker> incomingSpeakers = _projectViewModel.getHardwareForCircuit(circuitId: incoming.id).whereType<Speaker>().toList();
                          final List<Speaker> currentData = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();

                          final Zone? incomingZone = _projectViewModel.getZoneForCircuit(circuitId: incoming.id);

                          return incomingSpeakers.first.speakerSKU == currentData.first.speakerSKU &&
                              incoming.id != circuitData.id &&
                              incomingZone != null &&
                              incomingZone.id == widget.zoneId;
                        },
                        // ignore: deprecated_member_use
                        onAccept: (CircuitModel incoming) {
                          /// Add speaker to target circuit
                          final List<Speaker> incomingSpeakers = _projectViewModel.getHardwareForCircuit(circuitId: incoming.id).whereType<Speaker>().toList();

                          if (incomingSpeakers.isNotEmpty) {
                            for (final Speaker speaker in incomingSpeakers) {
                              // serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                              // serviceLocator<ProjectViewModel>().removeHardwareFromCircuit(hwId: speaker.id, circuitId: incoming.id);
                              serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitData.id);
                            }
                            _projectViewModel.setSelectedDevice(circuitData.id, SelectedItemType.circuit);
                          }

                          /// Remove the dragged circuit from the zone
                          _projectViewModel.removeCircuit(circuitId: incoming.id);
                          setState(() {});
                        },
                        builder: (BuildContext context, List<CircuitModel?> candidateData, List<dynamic> rejectedData) {
                          return Draggable<CircuitModel>(
                            data: circuitData,
                            feedback: SizedBox(
                              width: 220,

                              child: Material(
                                color: Colors.transparent,
                                child: AbsorbPointer(
                                  absorbing: true,

                                  child: CircuitDeviceWidget(
                                    prefix: "feedback_",
                                    index: index,
                                    deviceId: deviceId,
                                    circuitModel: circuitData,
                                    circuitDeviceName: circuitData.name,
                                    assetImagePath:
                                        serviceLocator<ProjectViewModel>().getHardwareImage(
                                          productId: speakers.isNotEmpty ? speakers.first.productId ?? 0 : 0,
                                          currentImagePath: speakers.isNotEmpty ? speakers.first.assetImagePath : '',
                                        ) ??
                                        "",
                                    location: location,
                                    speakers: speakers,
                                    projectViewModel: _projectViewModel,
                                    circuitDeviceCount: speakers.length,
                                    onDecrementHardwareInCircuit: () {},
                                    onIncrementHardwareInCircuit: () {},
                                    onRename: () {},
                                    onDuplicate: () {},
                                    onDelete: () {},
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Material(
                              color: Colors.transparent,
                              child: AbsorbPointer(
                                absorbing: true,
                                child: Opacity(
                                  opacity: 0.8,
                                  child: SizedBox(
                                    width: 220,

                                    child: CircuitDeviceWidget(
                                      prefix: "child_drag_",
                                      index: index,
                                      deviceId: deviceId,
                                      circuitModel: circuitData,
                                      circuitDeviceName: circuitData.name,
                                      assetImagePath:
                                          serviceLocator<ProjectViewModel>().getHardwareImage(
                                            productId: speakers.isNotEmpty ? speakers.first.productId ?? 0 : 0,
                                            currentImagePath: speakers.isNotEmpty ? speakers.first.assetImagePath : '',
                                          ) ??
                                          "",
                                      location: location,
                                      speakers: speakers,
                                      projectViewModel: _projectViewModel,
                                      circuitDeviceCount: speakers.length,
                                      onDecrementHardwareInCircuit: () {},
                                      onIncrementHardwareInCircuit: () {},
                                      onRename: () {},
                                      onDuplicate: () {},
                                      onDelete: () {},
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: CircuitDeviceWidget(
                              prefix: "child_",
                              index: index,
                              deviceId: deviceId,
                              circuitModel: circuitData,
                              circuitDeviceName: circuitData.name,
                              assetImagePath:
                                  serviceLocator<ProjectViewModel>().getHardwareImage(
                                    productId: speakers.isNotEmpty ? speakers.first.productId ?? 0 : 0,
                                    currentImagePath: speakers.isNotEmpty ? speakers.first.assetImagePath : '',
                                  ) ??
                                  "",
                              location: location,
                              speakers: speakers,
                              projectViewModel: _projectViewModel,
                              onDecrementHardwareInCircuit: () {
                                if (speakers.isNotEmpty) {
                                  final Speaker speaker = speakers.last;
                                  serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speaker.id);
                                }
                              },
                              onIncrementHardwareInCircuit: () {
                                if (speakers.isNotEmpty) {
                                  final Speaker speaker = speakers.first.getClone();
                                  serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                                  serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitData.id);
                                }
                              },
                              onRename: () {},
                              onDuplicate: () {},
                              onDelete: () {
                                _projectViewModel.removeCircuit(circuitId: circuitData.id);
                              },
                              circuitDeviceCount: speakers.length,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],

            /// Subzones list
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.subZones.length,
              padding: EdgeInsets.zero,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                _projectViewModel.reOrderSubZoneInZone(parentId: widget.zoneId, oldIndex: oldIndex, newIndex: newIndex);
                _projectViewModel.setSelectedDevice(widget.subZones[oldIndex].id, SelectedItemType.subzone);
              },
              itemBuilder: (BuildContext context, int index) {
                final SubZone subZone = widget.subZones[index];

                final bool isLast = index == widget.subZones.length - 1;

                return ReorderableDragStartListener(
                  key: ValueKey<String>(subZone.id),
                  index: index,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isLast ? Colors.transparent : context.colorScheme.elevation2,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ExpandableSubZoneWidget(
                      name: subZone.name,
                      subZoneId: subZone.id,
                      zoneId: widget.zoneId,
                      index: index,
                      subZoneCircuit: _projectViewModel.getCircuitsInSubZone(subZoneId: subZone.id),
                      onDelete: (String subZoneId) {
                        _projectViewModel.removeSubZoneFromZone(subZoneId: subZoneId, parentZoneId: widget.zoneId);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandIcon(BuildContext context, bool expanded) {
    return Icon(
      expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
      color: Theme.of(context).colorScheme.textPrimary.withAlpha(90),
    );
  }

  /// Zone name widget
  Widget _buildZoneName({required BuildContext context, required String name}) {
    return FusionAppText(
      text: name,
      maxLine: 1,
      textOverflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildKebabMenu({required BuildContext context, required String zoneId}) {
    return PopupMenuButton<ZoneMenuAction>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
        side: BorderSide(color: context.colorScheme.elevation4),
      ),
      tooltip: "",
      offset: const Offset(100, 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxHeight: 550, maxWidth: 200),
      color: context.colorScheme.elevation1,
      menuPadding: EdgeInsets.zero,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<ZoneMenuAction>>[
          /// --- Sub zone (with nested PopupMenuButton) ---
          PopupMenuItem<ZoneMenuAction>(
            height: 30,
            enabled: false,
            padding: EdgeInsets.zero,
            child: _buildSubzoneMenuItem(context, zoneId),
          ),

          // --- Delete ---
          PopupMenuItem<ZoneMenuAction>(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            onTap: () {
              widget.onDelete?.call(widget.zoneId);
            },
            child: FusionAppText(
              text: "Delete",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.textPrimary,
              ),
            ),
          ),
        ];
      },
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "zone_item_kebab_menu"),
        child: Icon(
          Icons.more_vert,
          size: FusionSizes.fontSize16,
          color: context.colorScheme.textPrimary,
        ),
      ),
    );
  }

  /// Subzone menu item with nested popup
  Widget _buildSubzoneMenuItem(BuildContext context, String zoneId) {
    return PopupMenuButton<void>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
        side: BorderSide(color: context.colorScheme.elevation4),
      ),
      tooltip: "",
      offset: const Offset(254, 16),
      constraints: const BoxConstraints(maxWidth: 250),
      color: context.colorScheme.elevation1,
      elevation: 8,
      padding: EdgeInsets.zero,
      onOpened: () => setState(() => showSubzonePopup = true),
      onCanceled: () {
        setState(() => showSubzonePopup = false);
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            enabled: false,
            child: _buildSubzoneContent(context, zoneId),
          ),
        ];
      },
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "add_subzone_menu"),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: "Sub zone",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_right_sharp,
                size: FusionSizes.fontSize12,
                color: context.colorScheme.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Subzone creation popup content
  /// Includes name input, location selector, and action buttons
  Widget _buildSubzoneContent(BuildContext context, String zoneId) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        void updateAllStates() {
          setDialogState(() {});
          setState(() {});
        }

        return SizedBox(
          width: 268,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Section Header
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "Create Sub Zone",
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Close only the subzone popup by popping once
                      Navigator.of(context).pop();
                      // Clear the state
                      _zoneNameController.clear();
                      _selectedListeningAreaIds.clear();
                      newlyCreatedAreas.clear(); // <-- Clear on close
                      setState(() => showSubzonePopup = false);
                    },
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "add_subzone_close_button"),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.elevation2, thickness: 1),
              const SizedBox(height: 8),

              /// SubZone Name Input
              FusionAppText(
                text: "Subzone Name",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SemanticHelper.formControl(
                testId: SemanticHelper.createTestId(SemanticTypes.textInput, "add_subzone_name_field"),
                child: PropertyTextField(
                  controller: _zoneNameController,
                  hintText: "Enter subzone name",
                  // color: Theme.of(context).colorScheme.primaryBlack,
                  onChanged: (String value) => updateAllStates(),
                ),
              ),

              const SizedBox(height: 18),

              /// Location Dropdown
              FusionAppText(
                text: "Location",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              _buildLocationSelector(context, zoneId, updateAllStates),

              const SizedBox(height: 16),

              /// Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Flexible(
                    child: FusionOutlinedButton(
                      width: double.infinity,
                      label: "Cancel",
                      semanticsId: "add_subzone_cancel_button",
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                      onTap: () {
                        // Close only the subzone popup
                        Navigator.of(context).pop();
                        // Clear the state
                        _zoneNameController.clear();
                        _selectedListeningAreaIds.clear();
                        newlyCreatedAreas.clear(); // <-- Clear on cancel
                        setState(() => showSubzonePopup = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "add_subzone_save_button"),
                      child: FusionButton(
                        width: double.infinity,
                        activeBackgroundColor: context.colorScheme.primaryColor,
                        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        label: "Save",
                        isActive: _zoneNameController.text.trim().isNotEmpty && _selectedListeningAreaIds.isNotEmpty,
                        onTap: () => _saveSubZone(context, zoneId),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Location selector dropdown
  Widget _buildLocationSelector(BuildContext context, String zoneId, VoidCallback onStateUpdate) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "location_selector_container"),
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.elevation2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: PopupMenuButton<String>(
          constraints: const BoxConstraints(maxHeight: 250, maxWidth: 236),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
            side: BorderSide(color: context.colorScheme.elevation4),
          ),
          tooltip: "",
          color: Theme.of(context).colorScheme.elevation1,
          offset: const Offset(6, 35),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: _buildLocationList(context, zoneId, onStateUpdate),
              ),
            ];
          },
          child: SemanticHelper.button(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "location_selector_button"),
            child: Container(
              height: 29,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text:
                          _selectedListeningAreaIds.isEmpty
                              ? "Select Location"
                              : "${_selectedListeningAreaIds.length} location${_selectedListeningAreaIds.length > 1 ? '(s)' : ''} selected",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedListeningAreaIds.isEmpty ? context.colorScheme.elevation5 : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: 2,
                    child: FusionSvgIcon(
                      icon: AssetSvg.expandUp,
                      size: FusionSizes.iconSize12,
                      color: context.colorScheme.primaryWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Location list within the dropdown
  Widget _buildLocationList(BuildContext context, String zoneId, VoidCallback onStateUpdate) {
    bool isCreateAreaExpanded = false;
    final String selectedFloor = '';
    final String selectedFloorId = '';
    final TextEditingController areaNameController = TextEditingController();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setPopupState) {
        /// Always recompute availableAreas and allAreas inside the builder so they update with state
        final List<ListeningArea> availableAreas = <ListeningArea>[
          ..._projectViewModel.getAvailableListeningAreasForSubZone(parentZoneId: zoneId),
          ...newlyCreatedAreas.map((Map<String, dynamic> e) => e['area'] as ListeningArea),
        ];
        final List<String> selectedListeningAreaIds = List<String>.from(_selectedListeningAreaIds);

        /// Combine assigned areas and available areas to show all
        final List<ListeningArea> allAreas = <ListeningArea>[
          ...serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zoneId),
          ...availableAreas.where(
            (ListeningArea a) => !serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zoneId).any((ListeningArea b) => b.id == a.id),
          ),
        ];

        void updateStates() {
          setPopupState(() {});
          onStateUpdate();
        }

        /// Helper to get floor name for area
        String getFloorNameForArea(ListeningArea area) {
          final Map<String, dynamic> newArea = newlyCreatedAreas.firstWhere(
            (Map<String, dynamic> e) => (e['area'] as ListeningArea).id == area.id,
            orElse: () => <String, dynamic>{},
          );
          if (newArea.isNotEmpty) {
            return newArea['floorName'] as String? ?? '';
          }
          final FloorModel? floorData = _projectViewModel.getFloorForListeningArea(areaId: area.id);
          return floorData?.name ?? '';
        }

        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "location_list_container"),
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.colorScheme.elevation2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FusionAppText(
                        text: "Select Locations",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.primaryWhite,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, "location_list_close_button"),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Theme.of(context).colorScheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Scrollable list
                allAreas.isEmpty
                    ? Container(
                      padding: const EdgeInsets.all(16),
                      child: FusionAppText(
                        text: "No locations found in this zone",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    )
                    : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              allAreas.map((ListeningArea area) {
                                final int index = allAreas.indexOf(area);

                                final String floorName = getFloorNameForArea(area);
                                final Zone? zoneData = _projectViewModel.getZonesForListeningArea(areaId: area.id);
                                final bool isAvailable = availableAreas.any((ListeningArea a) => a.id == area.id);
                                return _buildLocationItem(
                                  index: index,
                                  context: context,
                                  area: area,
                                  zoneId: zoneId,
                                  onStateUpdate: () {
                                    if (selectedListeningAreaIds.contains(area.id)) {
                                      selectedListeningAreaIds.remove(area.id);
                                    } else {
                                      selectedListeningAreaIds.add(area.id);
                                    }
                                    _selectedListeningAreaIds = List<String>.from(selectedListeningAreaIds);
                                    updateStates();
                                  },
                                  availableAreas: availableAreas,
                                  zoneData: zoneData,
                                  isAvailable: isAvailable,
                                  floorData: null, // not used, see below
                                  floorName: floorName, // pass floorName here
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                /// Create New Location Section
                CreateNewLocationWidget(
                  areaNameController: areaNameController,
                  isCreateAreaExpanded: isCreateAreaExpanded,
                  setDropdownState: setPopupState,
                  selectedFloor: selectedFloor,
                  selectedFloorId: selectedFloorId,
                  onCreateNewArea: ({required String floorId, required String floorName, required String locationName}) {
                    if (locationName.trim().isNotEmpty && floorId.isNotEmpty) {
                      final ListeningArea newListeningArea = ListeningArea(
                        name: locationName.trim(),
                        vertices: <Offset>[],
                        isDrawn: false,
                      );

                      try {
                        newlyCreatedAreas.add(<String, dynamic>{
                          'area': newListeningArea,
                          'floorId': floorId,
                          'floorName': floorName,
                        });
                        // Select all newly created locations
                        final List<String> allNewIds = newlyCreatedAreas.map((Map<String, dynamic> e) => (e['area'] as ListeningArea).id).toList();
                        _selectedListeningAreaIds = allNewIds;
                        setPopupState(() {});
                        areaNameController.clear();
                        isCreateAreaExpanded = false;

                        FusionToast.success(
                          context,
                          message: "Listening area '$locationName' created successfully on floor '$floorName'",
                        );
                        onStateUpdate(); // Force parent rebuild so location count updates
                      } catch (e) {
                        FusionToast.error(
                          context,
                          message: "Failed to create listening area: $e",
                        );
                      }
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
        );
      },
    );
  }

  /// Individual location item with checkbox
  Widget _buildLocationItem({
    required BuildContext context,
    required int index,
    required ListeningArea area,
    required String zoneId,
    required VoidCallback onStateUpdate,
    required List<ListeningArea> availableAreas,
    FloorModel? floorData,
    Zone? zoneData,
    required bool isAvailable,
    String? floorName, // add this parameter
  }) {
    void toggleSelection() {
      if (_selectedListeningAreaIds.contains(area.id)) {
        _selectedListeningAreaIds.remove(area.id);
      } else {
        _selectedListeningAreaIds.add(area.id);
      }
      onStateUpdate();
    }

    return InkWell(
      onTap: isAvailable ? toggleSelection : null,
      child: SemanticHelper.toggle(
        testId: SemanticHelper.createTestId(SemanticTypes.toggle, "location_item_checkbox_${index}_container"),
        value: isAvailable ? !_selectedListeningAreaIds.contains(area.id) : true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: SemanticHelper.toggle(
                  testId: SemanticHelper.createTestId(SemanticTypes.toggle, "location_item_checkbox_$index"),
                  value: isAvailable ? !_selectedListeningAreaIds.contains(area.id) : true,
                  child: Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: !isAvailable ? true : _selectedListeningAreaIds.contains(area.id),
                      activeColor: context.colorScheme.primaryWhite,
                      onChanged: isAvailable ? (bool? checked) => toggleSelection() : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// Location name and zone
              Expanded(
                child: FusionAppText(
                  text: area.name.isNotEmpty ? "${floorName ?? floorData?.name ?? ''}/${area.name}" : 'Unnamed Area',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: isAvailable ? context.colorScheme.primaryWhite : context.colorScheme.elevation5,
                  ),
                ),
              ),
              FusionAppText(
                text: zoneData?.name ?? "No zone",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: context.colorScheme.elevation5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save new subzone
  void _saveSubZone(BuildContext context, String? zoneId) {
    print("Started ______________________________");
    final SubZone newSubZone = SubZone(
      name: _zoneNameController.text.trim(),
    );

    _projectViewModel.recordSnapshot();
    for (Map<String, dynamic> entry in newlyCreatedAreas) {
      final ListeningArea area = entry['area'] as ListeningArea;
      final String floorId = entry['floorId'] as String;
      // _projectViewModel.addFloor(floor: floor);

      _projectViewModel.addListeningArea(area: area, floorId: floorId);
    }
    // _projectViewModel.addListeningArea(area: , floorId: floorId);
    _projectViewModel.addSubZone(subZone: newSubZone, autoSave: false);
    _projectViewModel.addSubZoneToZone(
      subZoneId: newSubZone.id,
      parentZoneId: zoneId ?? "",
      autoSave: false,
    );

    _projectViewModel.updateListeningAreasInSubZone(
      subZoneId: newSubZone.id,
      listeningAreaIds: _selectedListeningAreaIds,
      autoSave: false,
    );
    print("Ended ______________________________");

    _projectViewModel.saveProject();

    Navigator.of(context).pop(); // Close subzone popup
    Navigator.of(context).pop(); // Close kebab menu
    _zoneNameController.clear();
    _selectedListeningAreaIds.clear();
    newlyCreatedAreas.clear();
  }

  /// Called when a new speaker is added to the zone
  void onSpeakerAdded() {
    _isZoneExpanded.value = true;
  }
}
