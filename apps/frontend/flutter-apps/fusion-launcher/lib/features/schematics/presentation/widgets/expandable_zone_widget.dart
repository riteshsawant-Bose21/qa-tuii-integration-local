import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../core/service_locator.dart';

class ExpandableZoneWidget extends StatefulWidget {
  final String name;
  final String assetImagePath;
  final String? speakerId;
  final Color bgColor;
  final Function(String)? onDelete;
  final Function(String)? onRename;
  final Function(String)? onDuplicate;
  final Function()? onAddDevice;
  final bool initiallyExpanded;
  final List<Map<String, dynamic>> subZones;
  final Map<String, List<Map<String, dynamic>>> devices;
  final Function(String zoneId, int oldIndex, int newIndex)? onZoneReorder;
  final Function(String zoneId, int oldIndex, int newIndex)? onSubZoneReorder;
  final Function(String subZoneId, int oldIndex, int newIndex)? onDeviceReorder;

  const ExpandableZoneWidget({
    super.key,
    required this.name,
    required this.assetImagePath,
    this.speakerId,
    required this.bgColor,
    this.onDelete,
    this.onRename,
    this.onDuplicate,
    this.onAddDevice,
    this.initiallyExpanded = false,
    required this.subZones,
    required this.devices,
    this.onZoneReorder,
    this.onSubZoneReorder,
    this.onDeviceReorder,
  });

  @override
  State<ExpandableZoneWidget> createState() => _ExpandableZoneWidgetState();
}

class _ExpandableZoneWidgetState extends State<ExpandableZoneWidget> {
  late ValueNotifier<bool> _isZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

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
            final bool isHovered = hoveredDevice?.id == widget.speakerId && hoveredDevice?.type == SelectedItemType.zone;
            final bool isSelected = selectedDevice?.id == widget.speakerId && selectedDevice?.type == SelectedItemType.zone;

            return Column(
              children: <Widget>[
                MouseRegion(
                  onHover: (_) {
                    if (widget.speakerId != null) {
                      _projectViewModel.setHoveredDevice(widget.speakerId, SelectedItemType.zone);
                    }
                  },
                  onExit: (_) {
                    if (widget.speakerId != null) {
                      _projectViewModel.setHoveredDevice(null, null);
                    }
                  },
                  child: _buildZoneHeader(context, zoneExpanded, isHovered, isSelected),
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

  Widget _buildZoneHeader(BuildContext context, bool expanded, bool isHovered, bool isSelected) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14),
      height: 36,
      decoration: BoxDecoration(
        color: isHovered ? widget.bgColor.withAlpha(150) : widget.bgColor,
      ),
      child: Row(
        children: <Widget>[
          _buildDragHandle(),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
            child: _buildExpandIcon(context, expanded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
              child: _buildZoneName(context, widget.name),
            ),
          ),
          _buildAddDeviceButton(context),
          const SizedBox(width: 8),
          _buildKebabMenu(context),
        ],
      ),
    );
  }

  /// Zone content (visible when expanded) - contains subzones without ReorderableListView
  Widget _buildZoneContent() {
    return Container(
      color: widget.bgColor.withAlpha(30),
      child: Column(
        children:
            widget.subZones.map((Map<String, dynamic> subZone) {
              return SubZoneWidget(
                key: ValueKey<String>(subZone['id'] as String),
                name: subZone['name'] as String,
                subZoneId: subZone['id'] as String,
                zoneId: widget.speakerId!,
                devices: widget.devices[subZone['id']] ?? <Map<String, dynamic>>[],
                onDeviceReorder: widget.onDeviceReorder,
              );
            }).toList(),
      ),
    );
  }

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
            text: "Speakers",
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

  Widget _buildKebabMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: Colors.white,
        itemBuilder:
            (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'rename',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit, size: 12),
                    SizedBox(width: 6),
                    Text('Rename'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'duplicate',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'delete',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
        onSelected: (String value) {
          if (widget.speakerId == null) return;

          switch (value) {
            case 'rename':
              widget.onRename?.call(widget.speakerId!);
            case 'duplicate':
              widget.onDuplicate?.call(widget.speakerId!);
            case 'delete':
              widget.onDelete?.call(widget.speakerId!);
          }
        },
        child: Icon(
          Icons.more_vert,
          size: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

/// Separate widget for subzones with its own expansion state and full features
class SubZoneWidget extends StatefulWidget {
  final String name;
  final String subZoneId;
  final String zoneId;
  final List<Map<String, dynamic>> devices;
  final Function(String subZoneId, int oldIndex, int newIndex)? onDeviceReorder;

  const SubZoneWidget({
    super.key,
    required this.name,
    required this.subZoneId,
    required this.zoneId,
    required this.devices,
    this.onDeviceReorder,
  });

  @override
  State<SubZoneWidget> createState() => _SubZoneWidgetState();
}

class _SubZoneWidgetState extends State<SubZoneWidget> {
  late ValueNotifier<bool> _isZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(false);
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
                          onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
                          child: _buildExpandIcon(context, subZoneExpanded),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
                            child: _buildZoneName(context, widget.name),
                          ),
                        ),
                        _buildAddDeviceButton(context),
                        const SizedBox(width: 8),
                        _buildKebabMenu(context), // Show kebab menu only on hover
                      ],
                    ),
                  ),
                ),
                // SubZone Content - shows reorderable devices when expanded
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
    if (widget.devices.isEmpty) {
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
        itemCount: widget.devices.length,
        onReorder: (int oldIndex, int newIndex) {
          widget.onDeviceReorder?.call(widget.subZoneId, oldIndex, newIndex);
        },
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> device = widget.devices[index];
          final String deviceId = device['id'] as String;
          final String deviceName = device['name'] as String;
          final String position = device['position'] as String;

          return ReorderableDragStartListener(
            key: ValueKey<String>(deviceId),
            index: index,
            child: _buildDeviceItem(deviceName, position, deviceId),
          );
        },
      ),
    );
  }

  /// Individual device/speaker item within a subzone with full interaction features
  Widget _buildDeviceItem(String deviceName, String position, String deviceId) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final bool isHovered = hoveredDevice?.id == deviceId && hoveredDevice?.type == SelectedItemType.device;
        final bool isSelected = selectedDevice?.id == deviceId && selectedDevice?.type == SelectedItemType.device;

        return MouseRegion(
          onHover: (_) => _projectViewModel.setHoveredDevice(deviceId, SelectedItemType.device),
          onExit: (_) => _projectViewModel.setHoveredDevice(null, null),
          child: GestureDetector(
            onTap: () => _projectViewModel.setSelectedDevice(deviceId, SelectedItemType.device),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isHovered ? Colors.white.withOpacity(0.5) : (isSelected ? Colors.transparent : Colors.white),
                border: Border.all(color: isSelected ? Colors.grey[400]! : Colors.transparent, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// draggable icon
                  Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),

                  /// device icon, name and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /// device name
                        Row(
                          children: <Widget>[
                            const FusionImage.asset("assets/images/speakers/designmax_dm8se.png", width: 22, height: 22, fit: BoxFit.contain),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FusionAppText(
                                text: deviceName,
                                maxLine: 1,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        /// device location
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHovered ? Colors.white.withOpacity(0.8) : (isSelected ? Colors.white.withOpacity(0.9) : Colors.white),
                            border: Border.all(color: Theme.of(context).colorScheme.greyDark, width: 1),
                          ),
                          child: FusionAppText(
                            text: position,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  FusionAppText(
                    text: "Edit",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                  ),

                  /// kebab menu
                  const SizedBox(width: 8),

                  /// Kebab menu for device actions
                  Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      style: const ButtonStyle(
                        overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.white,

                      itemBuilder:
                          (BuildContext context) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'rename',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.edit, size: 12),
                                  SizedBox(width: 6),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'duplicate',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.copy, size: 16),
                                  SizedBox(width: 8),
                                  Text('Duplicate'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                      onSelected: (String value) {
                        switch (value) {
                          case 'rename':
                            print('Rename device: $deviceName');
                          case 'duplicate':
                            print('Duplicate device: $deviceName');
                          case 'delete':
                            // Remove device from list and show toast
                            setState(() {
                              widget.devices.removeWhere((Map<String, dynamic> d) => d['id'] == deviceId);
                            });
                            FusionToast.show(
                              context,
                              message: 'Device "$deviceName" deleted',
                              icon: Icons.delete_outline,
                              backgroundColor: Colors.red[600],
                            );
                        }
                      },
                      child: Icon(
                        Icons.more_vert,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods for SubZoneWidget
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
            text: "Speakers",
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
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: Colors.white,
        itemBuilder:
            (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'rename',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit, size: 12),
                    SizedBox(width: 6),
                    Text('Rename'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'duplicate',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                value: 'delete',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
        onSelected: (String value) {
          switch (value) {
            case 'rename':
              print('Rename subzone: ${widget.name}');
            case 'duplicate':
              print('Duplicate subzone: ${widget.name}');
            case 'delete':
              FusionToast.show(
                context,
                message: 'SubZone "${widget.name}" deleted',
                icon: Icons.delete_outline,
                backgroundColor: Colors.red[600],
              );
          }
        },
        child: Icon(
          Icons.more_vert,
          size: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
