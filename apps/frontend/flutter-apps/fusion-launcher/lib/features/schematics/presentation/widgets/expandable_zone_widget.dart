import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../core/service_locator.dart';
import 'add_speakers_menu.dart';
import 'circuit_device_widget.dart';
import 'expandable_sub_zone_widgets.dart';

class ExpandableZoneWidget extends StatefulWidget {
  final String zoneName;
  final String assetImagePath;
  final String? zoneId;
  final Color bgColor;
  final Function(String)? onDelete;
  final bool initiallyExpanded;
  final List<CircuitModel> zoneCircuits;
  final List<SubZone> subZones;
  final Function(String zoneId, int oldIndex, int newIndex)? onZoneReorder;
  final Function(String zoneId, int oldIndex, int newIndex)? onSubZoneReorder;
  final Function(String subZoneId, int oldIndex, int newIndex)? onDeviceReorder;

  const ExpandableZoneWidget({
    super.key,
    required this.zoneName,
    required this.assetImagePath,
    this.zoneId,
    required this.bgColor,
    this.onDelete,
    this.initiallyExpanded = false,
    required this.subZones,
    this.onZoneReorder,
    this.onSubZoneReorder,
    this.onDeviceReorder,
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
  bool _showSubzonePopup = false;

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
            final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            final bool isHovered = hoveredDevice?.id == widget.zoneId && hoveredDevice?.type == SelectedItemType.zone;
            final bool isSelected = selectedDevice?.id == widget.zoneId && selectedDevice?.type == SelectedItemType.zone;

            return Column(
              children: <Widget>[
                MouseRegion(
                  onHover: (_) {
                    if (widget.zoneId != null) {
                      _projectViewModel.setHoveredDevice(widget.zoneId, SelectedItemType.zone);
                    }
                  },
                  onExit: (_) {
                    if (widget.zoneId != null) {
                      _projectViewModel.setHoveredDevice(null, null);
                    }
                  },
                  child: _buildZoneHeader(
                    context: context,
                    expanded: zoneExpanded,
                    isHovered: isHovered,
                    isSelected: isSelected,
                  ),
                ),

                /// Zone Content - shows subzones when expanded
                if (zoneExpanded) _buildZoneContent(),
              ],
            );
          },
        );
      },
    );
  }

  /// Zone header - always visible
  Widget _buildZoneHeader({required BuildContext context, required bool expanded, required bool isHovered, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14),
      height: 36,
      decoration: BoxDecoration(
        color: isHovered ? widget.bgColor.withAlpha(150) : widget.bgColor.withAlpha(190),
      ),
      child: Row(
        children: <Widget>[
          /// Drag handle
          _buildDragHandle(),
          const SizedBox(width: 4),

          /// Expand/collapse icon
          GestureDetector(
            onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
            child: _buildExpandIcon(context, expanded),
          ),
          const SizedBox(width: 4),

          /// Zone name
          Expanded(
            child: GestureDetector(
              onTap: () {
                /// Select zone on tap
                if (widget.zoneId == null) return;
                _projectViewModel.setSelectedDevice(widget.zoneId!, SelectedItemType.zone);
              },
              // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
              child: _buildZoneName(
                context: context,
                name: widget.zoneName,
              ),
            ),
          ),

          /// Add device button
          AddSpeakersMenu(
            zoneId: widget.zoneId ?? "",
          ),
          const SizedBox(width: 8),

          /// Kebab menu for zone actions
          _buildKebabMenu(context: context, zoneId: widget.zoneId),
        ],
      ),
    );
  }

  /// Zone content (visible when expanded) - contains reorderable subzones
  Widget _buildZoneContent() {
    if (widget.subZones.isEmpty && widget.zoneCircuits.isEmpty) {
      // print("widget.subZones = ")
      return Container(
        color: widget.bgColor.withAlpha(60),
        padding: const EdgeInsets.all(30),
        child: const Center(
          child: Text(
            'No devices / subzones added yet',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        /// Zone devices list
        if (widget.zoneCircuits.isNotEmpty) ...<Widget>[
          Container(
            color: Theme.of(context).colorScheme.greyLight.withAlpha(50),
            padding: const EdgeInsets.only(left: 46, right: 8, top: 8, bottom: 8),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.zoneCircuits.length,
              onReorder: (int oldIndex, int newIndex) {
                // widget.onDeviceReorder?.call(widget.subZoneId, oldIndex, newIndex);
              },
              itemBuilder: (BuildContext context, int index) {
                final CircuitModel circuitData = widget.zoneCircuits[index];
                final List<Speaker> speakers = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
                final String deviceId = circuitData.id;
                final List<ListeningArea> location = _projectViewModel.getListeningAreasForCircuit(circuitId: circuitData.id);

                return ReorderableDragStartListener(
                  key: ValueKey<String>(deviceId),
                  index: index,
                  child: CircuitDeviceWidget(
                    deviceId: deviceId,
                    circuitDeviceName: speakers[index].name,
                    location: location,
                    projectViewModel: _projectViewModel,
                    onDecrementHardwareInCircuit: () {
                      final Speaker speaker = speakers.last;
                      serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speaker.id);
                    },
                    onIncrementHardwareInCircuit: () {
                      final Speaker speaker = speakers.first.getClone();
                      serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                      serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitData.id);
                    },
                    onRename: () {},
                    onDuplicate: () {},
                    onDelete: () {},
                    circuitDeviceCount: speakers.length,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        /// Subzones list
        Container(
          clipBehavior: Clip.none,
          color: widget.bgColor.withAlpha(30),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.subZones.length,
            onReorder: (int oldIndex, int newIndex) {
              widget.onSubZoneReorder?.call(widget.zoneId!, oldIndex, newIndex);
            },
            itemBuilder: (BuildContext context, int index) {
              final SubZone subZone = widget.subZones[index];
              return ReorderableDragStartListener(
                key: ValueKey<String>(subZone.id),
                index: index,
                child: ExpandableSubZoneWidget(
                  name: subZone.name,
                  subZoneId: subZone.id,
                  zoneId: widget.zoneId!,
                  subZoneDevices: _projectViewModel.getCircuitsInSubZone(subZoneId: subZone.id),
                  onDeviceReorder: widget.onDeviceReorder,
                  onDelete: (String subZoneId) {
                    _projectViewModel.removeSubZoneFromZone(subZoneId: subZoneId, parentZoneId: widget.zoneId!);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Drag handle widget
  Widget _buildDragHandle() {
    return Icon(
      Icons.drag_handle,
      size: 16,
      color: Colors.grey[600],
    );
  }

  Widget _buildExpandIcon(BuildContext context, bool expanded) {
    return Icon(
      expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
      color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
    );
  }

  /// Zone name widget
  Widget _buildZoneName({required BuildContext context, required String name}) {
    return FusionAppText(
      text: name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildKebabMenu({required BuildContext context, String? zoneId}) {
    return PopupMenuButton<ZoneMenuAction>(
      style: const ButtonStyle(
        overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      offset: const Offset(100, 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxHeight: 550, maxWidth: 140),
      color: Theme.of(context).colorScheme.white,
      menuPadding: EdgeInsets.zero,
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<ZoneMenuAction>>[
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
                setState(() => _showSubzonePopup = false);
                widget.onDelete?.call(widget.zoneId!);
              },
              child: FusionAppText(
                text: "Delete",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
              ),
            ),
          ],
      child: Icon(
        Icons.more_vert,
        size: 14,
        color: Colors.grey[600],
      ),
    );
  }

  /// Subzone menu item with nested popup
  Widget _buildSubzoneMenuItem(BuildContext context, String? zoneId) {
    return PopupMenuButton<void>(
      tooltip: "",
      offset: const Offset(254, 16),
      constraints: const BoxConstraints(maxWidth: 250),
      color: Theme.of(context).colorScheme.white,
      elevation: 8,
      padding: EdgeInsets.zero,
      onCanceled: () => setState(() => _showSubzonePopup = false),
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<void>>[
            PopupMenuItem<void>(
              enabled: false,
              child: _buildSubzoneContent(context, zoneId),
            ),
          ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: "Sub zone",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.fusionTextViewColor,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_sharp,
              size: 12,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Subzone creation popup content
  /// Includes name input, location selector, and action buttons
  Widget _buildSubzoneContent(BuildContext context, String? zoneId) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        /// Single function to handle all state updates
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FusionAppText(
                    text: "Create Sub Zone",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _zoneNameController.clear();
                      _selectedListeningAreaIds.clear();
                      setState(() {});
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Theme.of(context).colorScheme.dividerColor,
                thickness: 1,
              ),
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
              FusionTextField(
                controller: _zoneNameController,
                hintText: "Enter subzone name",
                decoration: FusionInputDecoration.fusionDense(
                  colorScheme: Theme.of(context).colorScheme,
                  hintText: 'Enter subzone name',
                ),
                onChanged: (String value) => updateAllStates(),
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
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                      onTap: () {
                        Navigator.of(context).pop();
                        _zoneNameController.clear();
                        _selectedListeningAreaIds.clear();
                        setState(() {}); // Reset main widget state
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FusionButton(
                      width: double.infinity,
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.fusionButtonTextColor,
                      ),
                      label: "Save",
                      isActive: _zoneNameController.text.trim().isNotEmpty && _selectedListeningAreaIds.isNotEmpty,
                      onTap: () => _saveSubZone(context, zoneId),
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
  Widget _buildLocationSelector(BuildContext context, String? zoneId, VoidCallback onStateUpdate) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 236),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Theme.of(context).colorScheme.white,
        offset: const Offset(6, 35),
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: _buildLocationList(context, zoneId, onStateUpdate),
              ),
            ],
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
                    color: _selectedListeningAreaIds.isEmpty ? Theme.of(context).colorScheme.greyDark : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Theme.of(context).colorScheme.greyDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Location list within the dropdown
  Widget _buildLocationList(BuildContext context, String? zoneId, VoidCallback onStateUpdate) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setPopupState) {
        void updateStates() {
          setPopupState(() {});
          onStateUpdate();
        }

        return SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FusionAppText(
                      text: "Select Locations",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                      ),
                    ),
                  ],
                ),
              ),

              /// Scrollable list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        serviceLocator<ProjectViewModel>()
                            .getListeningAreasForZone(zoneId: zoneId ?? "")
                            .map((ListeningArea area) => _buildLocationItem(context, area, zoneId ?? "", updateStates))
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Individual location item with checkbox
  Widget _buildLocationItem(
    BuildContext context,
    ListeningArea area,
    String zoneId,
    VoidCallback onStateUpdate,
  ) {
    final List<ListeningArea> availableAreas = _projectViewModel.getAvailableListeningAreasForZone(zoneId: zoneId);
    final FloorModel? floorName = _projectViewModel.getFloorForListeningArea(areaId: area.id);
    final Zone? zoneData = _projectViewModel.getZonesForListeningArea(areaId: area.id);
    final bool isAvailable = availableAreas.any((ListeningArea a) => a.id == area.id);

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: Checkbox(
                value: !isAvailable ? true : _selectedListeningAreaIds.contains(area.id),
                activeColor: Theme.of(context).colorScheme.greyDark,
                onChanged: isAvailable ? (bool? checked) => toggleSelection() : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(width: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Location name and zone
            Expanded(
              child: FusionAppText(
                text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Area',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: isAvailable ? Theme.of(context).textTheme.bodySmall?.color : Colors.grey[400],
                ),
              ),
            ),
            FusionAppText(
              text: zoneData?.name ?? "No zone",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: isAvailable ? Theme.of(context).colorScheme.greyDark : Theme.of(context).colorScheme.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save new subzone
  void _saveSubZone(BuildContext context, String? zoneId) {
    final SubZone newSubZone = SubZone(
      id: 'subzone_${DateTime.now().millisecondsSinceEpoch}',
      name: _zoneNameController.text.trim(),
    );

    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    viewModel.recordSnapshot();
    viewModel.addSubZone(subZone: newSubZone, autoSave: false);
    viewModel.addSubZoneToZone(
      subZoneId: newSubZone.id,
      parentZoneId: zoneId ?? "",
      autoSave: false,
    );
    viewModel.updateListeningAreasInSubZone(
      subZoneId: newSubZone.id,
      listeningAreaIds: _selectedListeningAreaIds,
      autoSave: false,
    );
    viewModel.saveProject();

    Navigator.of(context).pop();
    Navigator.of(context).pop();
    _zoneNameController.clear();
    _selectedListeningAreaIds.clear();
    setState(() {});
  }
}
