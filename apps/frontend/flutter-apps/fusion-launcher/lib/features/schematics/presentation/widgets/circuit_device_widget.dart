import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';

/// Reusable widget for displaying a device item with hover, selection, and menu actions
class CircuitDeviceWidget extends StatelessWidget {
  final String deviceName;
  final String location;
  final String deviceId;
  final String circuitDeviceName;
  final ProjectViewModel projectViewModel;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const CircuitDeviceWidget({
    super.key,
    required this.deviceName,
    required this.location,
    required this.deviceId,
    required this.circuitDeviceName,
    required this.projectViewModel,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? hoveredDevice = projectViewModel.hoveredDevice;
        final SelectedItem? selectedDevice = projectViewModel.selectedDevice;
        final bool isHovered = hoveredDevice?.id == deviceId && hoveredDevice?.type == SelectedItemType.circuit;
        final bool isSelected = selectedDevice?.id == deviceId && selectedDevice?.type == SelectedItemType.circuit;

        return MouseRegion(
          onHover: (_) => projectViewModel.setHoveredDevice(deviceId, SelectedItemType.circuit),
          onExit: (_) => projectViewModel.setHoveredDevice(null, null),
          child: GestureDetector(
            onTap: () => projectViewModel.setSelectedDevice(deviceId, SelectedItemType.circuit),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isHovered
                        ? Theme.of(context).colorScheme.grey.withOpacity(0.2)
                        : (isSelected ? Theme.of(context).colorScheme.grey.withOpacity(0.3) : Theme.of(context).colorScheme.white),
                border: Border.all(color: isSelected ? Colors.black : Theme.of(context).colorScheme.grey, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Draggable icon
                  Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),

                  /// Device icon, name and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /// Device name with circuit/device type label
                        Row(
                          children: <Widget>[
                            const FusionImage.asset(
                              "assets/images/speakers/designmax_dm8se.png",
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
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

                        /// Device location
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHovered ? Colors.white.withOpacity(0.8) : (isSelected ? Colors.white.withOpacity(0.9) : Colors.white),
                            border: Border.all(color: Theme.of(context).colorScheme.greyDark, width: 1),
                          ),
                          child: FusionAppText(
                            text: location,
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

                  /// Kebab menu
                  const SizedBox(width: 8),
                  _buildKebabMenu(context),
                ],
              ),
            ),
          ),
        );
      },
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
              onRename();
            case 'duplicate':
              onDuplicate();
            case 'delete':
              onDelete();
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

/// Usage example in your parent widget:
///
/// Widget _buildDeviceItem(String deviceName, String location, String deviceId, String circuitDeviceName) {
///   return DeviceItemWidget(
///     deviceName: deviceName,
///     location: location,
///     deviceId: deviceId,
///     circuitDeviceName: circuitDeviceName,
///     projectViewModel: _projectViewModel,
///     onRename: () {
///       print('Rename device: $deviceName');
///       // Add your rename logic here
///     },
///     onDuplicate: () {
///       print('Duplicate device: $deviceName');
///       // Add your duplicate logic here
///     },
///     onDelete: () {
///       setState(() {
///         widget.devices.removeWhere((Map<String, dynamic> d) => d['id'] == deviceId);
///       });
///       FusionToast.show(
///         context,
///         message: 'Device "$deviceName" deleted',
///         icon: Icons.delete_outline,
///         backgroundColor: Colors.red[600],
///       );
///     },
///   );
/// }
