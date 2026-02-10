import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final CircuitModel circuitModel;
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
    required this.circuitModel,
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
              padding: const EdgeInsets.all(6).copyWith(left: 0),
              decoration: BoxDecoration(
                color:
                    _isHovered
                        ? context.colorScheme.elevation2
                        : isSelected
                        ? context.colorScheme.elevation3
                        : context.colorScheme.elevation1,
                border: Border.all(
                  color: isSelected ? context.colorScheme.elevation5 : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "circuit_${widget.index}"),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Only drag handle is reorderable
                    ReorderableDragStartListener(
                      key: ValueKey<String>(widget.deviceId),
                      index: widget.index,
                      child: Icon(
                        Icons.drag_indicator,
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
                                      return Row(
                                        spacing: 4,
                                        children: <Widget>[
                                          Icon(
                                            LucideIcons.mapPin200,
                                            size: FusionSizes.iconSize10,
                                            color: context.colorScheme.elevation5,
                                          ),
                                          Flexible(
                                            child: FusionAppText(
                                              text: location.name,
                                              style: context.textTheme.bodySmall?.copyWith(
                                                fontSize: 9,
                                                color: const Color(0xFFBD7D23),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                        ],
                      ),
                    ),
                
                    const SizedBox(width: 4),
                    if (!widget.circuitModel.addedInBuildingPage) ...<Widget>[
                      _buildAddOrRemoveButton(context: context),
                
                      /// Kebab menu
                      const SizedBox(width: 8),
                      _buildKebabMenu(context),
                    ] else ...<Widget>[
                      const SizedBox(width: 2),
                      Container(
                        height: 20,
                        width: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colorScheme.elevation4, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FusionAppText(
                          text: widget.circuitDeviceCount.toString(),
                          maxLine: 1,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
                        ),
                      ),
                    ],
                  ],
                ),
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
            child: Icon(
              Icons.remove,
              size: 10,
              color: context.colorScheme.iconDefault,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            height: 20,
            width: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colorScheme.elevation2,
                width: 1,
              ),
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
            child: Icon(
              Icons.add,
              size: 10,
              color: context.colorScheme.iconDefault,
            ),
          ),
        ],
      );
    } else {
      /// logic for single/zero location
      return Row(
        children: <Widget>[
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "decrement_speaker_count"),
            child: GestureDetector(
              onTap: () {
                widget.onDecrementHardwareInCircuit();
              },
              child: Icon(
                Icons.remove,
                size: 10,
                color: context.colorScheme.iconDefault,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Container(
            height: 20,
            width: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: context.colorScheme.elevation5, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FusionAppText(
              text: widget.circuitDeviceCount.toString(),
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
            ),
          ),
          const SizedBox(width: 2),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.button, "increment_speaker_count"),
            child: GestureDetector(
              onTap: () {
                widget.onIncrementHardwareInCircuit();
              },
              child: Icon(
                Icons.add,
                size: 10,
                color: context.colorScheme.iconDefault,
              ),
            ),
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
          backgroundColor: context.colorScheme.primaryWhite,
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
                    /// Header with close button
                    Row(
                      children: <Widget>[
                        FusionAppText(
                          text: widget.circuitDeviceName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        /// close icon
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Divider(
                      height: 12,
                      color: context.colorScheme.primaryBlack,
                    ),
                    const SizedBox(height: 6),

                    // Align(
                    //   alignment: Alignment.centerLeft,
                    //   child: FusionAppText(
                    //     text: "Circuit name : ${widget.circuitDeviceName}",
                    //     maxLine: 1,
                    //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w400,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 8),

                    /// List of locations with add/remove buttons and per-location speaker count
                    ...locationList.map(
                      (ListeningArea location) {
                        /// Calculate speaker count for this location
                        final List<Speaker> locationSpeakers =
                            speakerList.where((Speaker speaker) => speaker.locationEntity.listeningAreaId == location.id).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FusionAppText(
                                text: "Location name : ${location.name}",
                                maxLine: 1,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primaryWhite,
                                  border: Border.all(color: context.colorScheme.primaryBlack, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    FusionImage.asset(
                                      widget.speakers.first.assetImagePath,
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: FusionAppText(
                                        text: widget.speakers.first.hardwareName,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
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
                                            border: Border.all(color: context.colorScheme.primaryBlack, width: 1),
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
                            ],
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
                  color: Theme.of(context).colorScheme.textPrimary,
                ),
              ),
            ),
          ],
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "location_item_kebab_menu"),
        child: Icon(
          Icons.more_vert,
          size: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
