import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/listening_area_model.dart';
import 'package:fusion_lib/models/project_entities/speaker_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

/// Reusable widget for displaying a device item with hover, selection, and menu actions
class CircuitDeviceWidget extends StatefulWidget {
  final List<ListeningArea> location;
  final List<Speaker> speakers;
  final String deviceId;
  final String circuitDeviceName;
  final String assetImagePath;
  final int circuitDeviceCount;
  final ProjectViewModel projectViewModel;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onDecrementHardwareInCircuit;
  final VoidCallback onIncrementHardwareInCircuit;

  final int index;

  const CircuitDeviceWidget({
    super.key,
    required this.location,
    required this.deviceId,
    required this.circuitDeviceName,
    required this.projectViewModel,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.circuitDeviceCount,
    required this.onDecrementHardwareInCircuit,
    required this.onIncrementHardwareInCircuit,
    required this.assetImagePath,
    required this.index,
    required this.speakers,
  });

  @override
  State<CircuitDeviceWidget> createState() => _CircuitDeviceWidgetState();
}

class _CircuitDeviceWidgetState extends State<CircuitDeviceWidget> {
  bool _isHovered = false;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = widget.projectViewModel.selectedDevice;
        final bool isSelected = selectedDevice?.id == widget.deviceId && selectedDevice?.type == SelectedItemType.circuit;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => widget.projectViewModel.setSelectedDevice(widget.deviceId, SelectedItemType.circuit),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _isHovered
                        ? Theme.of(context).colorScheme.grey.withOpacity(0.2)
                        : (isSelected ? Theme.of(context).colorScheme.grey.withOpacity(0.3) : Theme.of(context).colorScheme.white),
                border: Border.all(color: isSelected ? Colors.black : Theme.of(context).colorScheme.grey, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Only drag handle is reorderable
                  ReorderableDragStartListener(
                    key: ValueKey<String>(widget.deviceId),
                    index: widget.index,
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.grey[600],
                    ),
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
                            FusionImage.asset(
                              widget.assetImagePath,
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FusionAppText(
                                text: widget.circuitDeviceName,
                                maxLine: 1,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        /// Device location
                        widget.location.isEmpty
                            ? const SizedBox.shrink()
                            : Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children:
                                  widget.location.map((ListeningArea location) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isHovered ? Colors.white.withOpacity(0.8) : (isSelected ? Colors.white.withOpacity(0.9) : Colors.white),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.grey,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FusionAppText(
                                        text: location.name,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9, color: const Color(0xFFBD7D23)),
                                      ),
                                    );
                                  }).toList(),
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  _buildAddOrRemoveButton(context: context),

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

  Widget _buildAddOrRemoveButton({required BuildContext context}) {
    /// If more than one location, show popup menu on add/remove
    if (widget.location.length > 1) {
      return Row(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _showSpeakerDetailsPopup(context, isAdd: false);
            },
            child: const Icon(Icons.remove, size: 10),
          ),
          const SizedBox(width: 2),
          Container(
            height: 20,
            width: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.grey, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FusionAppText(
              text: widget.circuitDeviceCount.toString(),
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              _showSpeakerDetailsPopup(context, isAdd: true);
            },
            child: const Icon(Icons.add, size: 10),
          ),
        ],
      );
    } else {
      /// logic for single/zero location
      return Row(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              widget.onDecrementHardwareInCircuit();
            },
            child: const Icon(Icons.remove, size: 10),
          ),
          const SizedBox(width: 2),
          Container(
            height: 20,
            width: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.grey, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FusionAppText(
              text: widget.circuitDeviceCount.toString(),
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              widget.onIncrementHardwareInCircuit();
            },
            child: const Icon(Icons.add, size: 10),
          ),
        ],
      );
    }
  }

  /// Show popup to manage speaker locations
  void _showSpeakerDetailsPopup(BuildContext context, {required bool isAdd}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final List<Speaker> speakerList = _projectViewModel.getHardwareForCircuit(circuitId: widget.deviceId).whereType<Speaker>().toList();
              final List<ListeningArea> locationList = _projectViewModel.getListeningAreasForCircuit(circuitId: widget.deviceId);

              return Container(
                width: 320,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FusionAppText(
                      text: "Manage Speakers",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Divider(
                      height: 12,
                      color: Theme.of(context).colorScheme.grey,
                    ),
                    const SizedBox(height: 4),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: FusionAppText(
                        text: "Circuit name : ${widget.circuitDeviceName}",
                        maxLine: 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    /// List of locations with add/remove buttons and per-location speaker count
                    ...locationList.map(
                      (ListeningArea location) {
                        /// Calculate speaker count for this location
                        final List<Speaker> locationSpeakers =
                            speakerList.where((Speaker speaker) => speaker.locationEntity.listeningAreaId == location.id).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              border: Border.all(color: Theme.of(context).colorScheme.grey, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FusionImage.asset(
                                  widget.speakers.first.assetImagePath,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: widget.speakers.first.hardwareName,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.grey,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: FusionAppText(
                                          text: location.name,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9, color: const Color(0xFFBD7D23)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                /// Add/Remove buttons with count
                                Row(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        // Remove speaker from this location
                                        if (locationSpeakers.isNotEmpty) {
                                          final Speaker speaker = locationSpeakers.last;
                                          serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speaker.id);
                                        }
                                      },
                                      child: const Icon(Icons.remove, size: 10),
                                    ),
                                    const SizedBox(width: 2),
                                    Container(
                                      height: 20,
                                      width: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.grey, width: 1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FusionAppText(
                                        text: locationSpeakers.length.toString(),
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    GestureDetector(
                                      onTap: () {
                                        if (locationSpeakers.isNotEmpty) {
                                          final Speaker speaker = locationSpeakers.first.getClone();
                                          serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                                          serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: widget.deviceId);
                                        }
                                      },
                                      child: const Icon(Icons.add, size: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
            /// --- Delete ---
            PopupMenuItem<ZoneMenuAction>(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onTap: () {
                widget.onDelete();
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
}
