import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../core/service_locator.dart';
import 'add_speakers_menu.dart';
import 'circuit_device_widget.dart';

/// Separate widget for subzones with its own expansion state and full features
class ExpandableSubZoneWidget extends StatefulWidget {
  final String name;
  final String subZoneId;
  final String zoneId;
  final List<CircuitModel> subZoneDevices;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final Function(String subZoneId, int oldIndex, int newIndex)? onDeviceReorder;

  const ExpandableSubZoneWidget({
    super.key,
    required this.name,
    required this.subZoneId,
    required this.zoneId,
    required this.subZoneDevices,
    this.onDelete,
    this.onEdit,
    this.onDeviceReorder,
  });

  @override
  State<ExpandableSubZoneWidget> createState() => _ExpandableSubZoneWidgetState();
}

class _ExpandableSubZoneWidgetState extends State<ExpandableSubZoneWidget> {
  late ValueNotifier<bool> _isSubZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
    _isSubZoneExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isSubZoneExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSubZoneExpanded,
      builder: (BuildContext context, bool subZoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            final bool isSubZoneHovered = hoveredDevice?.id == widget.subZoneId && hoveredDevice?.type == SelectedItemType.subzone;
            final bool isSubZoneSelected = selectedDevice?.id == widget.subZoneId && selectedDevice?.type == SelectedItemType.subzone;

            return Column(
              children: <Widget>[
                MouseRegion(
                  onHover: (_) => _projectViewModel.setHoveredDevice(widget.subZoneId, SelectedItemType.subzone),
                  onExit: (_) => _projectViewModel.setHoveredDevice(null, null),
                  child: Container(
                    padding: const EdgeInsets.only(left: 30, right: 14),
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSubZoneHovered ? Theme.of(context).colorScheme.greyLight.withAlpha(200) : Theme.of(context).colorScheme.greyLight,
                    ),
                    child: Row(
                      children: <Widget>[
                        _buildDragHandle(),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _isSubZoneExpanded.value = !_isSubZoneExpanded.value,
                          child: _buildExpandIcon(context, subZoneExpanded),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              /// Select  subzone on tap
                              if (widget.subZoneId == null) return;
                              _projectViewModel.setSelectedDevice(widget.subZoneId!, SelectedItemType.subzone);
                            },
                            // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
                            child: _buildZoneName(context, widget.name),
                          ),
                        ),

                        /// Add device button
                        AddSpeakersMenu(
                          zoneId: widget.zoneId ?? "",
                          subZoneId: widget.subZoneId,
                        ),
                        const SizedBox(width: 8),
                        _buildKebabMenu(context),
                      ],
                    ),
                  ),
                ),
                if (subZoneExpanded) _buildSubZoneContent(),
              ],
            );
          },
        );
      },
    );
  }

  /// SubZone content - properly contained within ReorderableListView
  Widget _buildSubZoneContent() {
    if (widget.subZoneDevices.isEmpty) {
      print("no devices in subzone ${widget.subZoneId}");
      return Container(
        color: Theme.of(context).colorScheme.greyLight.withAlpha(50),
        padding: const EdgeInsets.only(left: 46, right: 8, top: 8, bottom: 8),
        child: const Center(
          child: Text(
            'No devices added yet',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.greyLight.withAlpha(50),
      padding: const EdgeInsets.only(left: 46, right: 8, top: 8, bottom: 8),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: widget.subZoneDevices.length,
        onReorder: (int oldIndex, int newIndex) {
          widget.onDeviceReorder?.call(widget.subZoneId, oldIndex, newIndex);
        },
        itemBuilder: (BuildContext context, int index) {
          final CircuitModel device = widget.subZoneDevices[index];
          print('Building device widget for ${device.name} at index $index');
          final String deviceId = device.id;
          final String deviceName = device.name;
          final String location = device.name;

          return ReorderableDragStartListener(
            key: ValueKey<String>(deviceId),
            index: index,
            child: CircuitDeviceWidget(
              deviceId: deviceId,
              deviceName: deviceName,
              location: location,
              circuitDeviceName: '',
              projectViewModel: _projectViewModel,
              onRename: () {},
              onDuplicate: () {},
              onDelete: () {},
            ),
          );
        },
      ),
    );
  }

  /// drag handle icon
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

  Widget _buildZoneName(BuildContext context, String name) {
    return FusionAppText(
      text: name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAddDeviceButton(BuildContext context) {
    return GestureDetector(
      onTap: () => print('Add device to ${widget.name}'),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.add,
            size: 10,
            color: Colors.grey[800],
          ),
          const SizedBox(width: 4),
          FusionAppText(
            text: "Speaker",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Kebab menu for subzone actions
  Widget _buildKebabMenu(BuildContext context) {
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
            /// --- Edit ---
            PopupMenuItem<ZoneMenuAction>(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onTap: () {
                widget.onEdit?.call(widget.zoneId!);
              },
              child: FusionAppText(
                text: "Edit",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
              ),
            ),

            // --- Delete ---
            PopupMenuItem<ZoneMenuAction>(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onTap: () {
                widget.onDelete?.call(widget.zoneId!);
              },
              child: FusionAppText(
                text: "Delete",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
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
}
