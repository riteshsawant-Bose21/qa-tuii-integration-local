import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../speaker_selection_popup/views/speaker_selection_popup].dart';
import 'circuit_device_widget.dart';

/// Separate widget for subzones with its own expansion state and full features
class ExpandableSubZoneWidget extends StatefulWidget {
  final String name;
  final String subZoneId;
  final String zoneId;
  final int index;
  final List<CircuitModel> subZoneCircuit;
  final Function(String)? onDelete;
  final Function(String)? onEdit;

  const ExpandableSubZoneWidget({
    super.key,
    required this.name,
    required this.subZoneId,
    required this.zoneId,
    required this.subZoneCircuit,
    required this.index,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<ExpandableSubZoneWidget> createState() => _ExpandableSubZoneWidgetState();
}

class _ExpandableSubZoneWidgetState extends State<ExpandableSubZoneWidget> {
  late ValueNotifier<bool> _isSubZoneExpanded;

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isSubZoneExpanded = ValueNotifier<bool>(true);
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
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

            final bool isSelected = selectedDevice?.id == widget.subZoneId && selectedDevice?.type == SelectedItemType.subzone;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
                border: isSelected ? Border.all(color: context.colorScheme.strokeLight) : null,
              ),
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.container,
                  "sub_zone_${widget.index}",
                ),
                child: Column(
                  children: <Widget>[
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: SizedBox(
                        height: 36,
                        width: double.infinity,
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
                                  _projectViewModel.setSelectedDevice(
                                    widget.subZoneId!,
                                    SelectedItemType.subzone,
                                  );
                                },
                                // onTap: () => _isZoneExpanded.value = !_isZoneExpanded.value,
                                child: _buildZoneName(context, widget.name),
                              ),
                            ),

                            // /// Add device button
                            // AddSpeakersMenu(
                            //   zoneId: widget.zoneId ?? "",
                            //   subZoneId: widget.subZoneId,
                            //   onSpeakerAdded: onSpeakerAdded,
                            // ),
                            FusionArrowPopup(
                              semanticId: "add_speakers_menu",
                              content: SpeakerQueryPopup(
                                isFromBuildingPage: false,
                                zoneId: widget.zoneId,
                                subZoneId: widget.subZoneId,
                              ),
                              backgroundColor: context.colorScheme.elevation1,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.add,
                                    size: 10,
                                    color: context.colorScheme.iconWhite,
                                  ),
                                  const SizedBox(width: 4),
                                  FusionAppText(
                                    text: "Speaker",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w400,
                                      color: context.colorScheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildKebabMenu(context),
                          ],
                        ),
                      ),
                    ),
                    if (subZoneExpanded) _buildSubZoneContent(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Called when a new speaker is added to the subzone
  void onSpeakerAdded() {
    _isSubZoneExpanded.value = true;
  }

  /// SubZone content - properl    _isSubZoneExpanded.value = true; // <-- Corrected to use the correct variableReorderableListView
  Widget _buildSubZoneContent() {
    if (widget.subZoneCircuit.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No devices added yet',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // color: context.colorScheme.primaryBlack.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.subZoneCircuit.length,
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              _projectViewModel.reOrderCircuitInZone(
                parentId: widget.subZoneId,
                oldIndex: oldIndex,
                newIndex: newIndex,
              );
              _projectViewModel.setSelectedDevice(
                widget.subZoneCircuit[oldIndex].id,
                SelectedItemType.circuit,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final CircuitModel circuitData = widget.subZoneCircuit[index];
              final String deviceId = circuitData.id;
              final List<Speaker> speakers = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
              final List<ListeningArea> location = _projectViewModel.getListeningAreasForCircuit(circuitId: circuitData.id);
              return DragTarget<CircuitModel>(
                key: ValueKey<String>(deviceId),
                onWillAcceptWithDetails: (
                  DragTargetDetails<CircuitModel>? param,
                ) {
                  final CircuitModel? incoming = param?.data;

                  /// Only accept if the incoming circuit has the same name but different ID
                  ///
                  if (incoming == null) return false;

                  if (circuitData.addedInBuildingPage || incoming.addedInBuildingPage) {
                    return false;
                  }

                  // return incoming != null && incoming.name == circuitData.name && incoming.id != circuitData.id;
                  final List<Speaker> incomingSpeakers = _projectViewModel.getHardwareForCircuit(circuitId: incoming.id).whereType<Speaker>().toList();
                  final List<Speaker> currentData = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
                  final SubZone? circuitSubZone = _projectViewModel.getSubZoneForCircuit(circuitId: incoming.id);

                  return incomingSpeakers.first.speakerSKU == currentData.first.speakerSKU &&
                      incoming.id != circuitData.id &&
                      (circuitSubZone != null && circuitSubZone.id == widget.subZoneId);
                },
                onAcceptWithDetails: (DragTargetDetails<CircuitModel> param) {
                  final CircuitModel incoming = param.data;

                  /// Add speaker to target circuit
                  final List<Speaker> incomingSpeakers = _projectViewModel.getHardwareForCircuit(circuitId: incoming.id).whereType<Speaker>().toList();

                  if (incomingSpeakers.isNotEmpty) {
                    for (final Speaker speaker in incomingSpeakers) {
                      // serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                      serviceLocator<ProjectViewModel>().addHardwareToCircuit(
                        hwId: speaker.id,
                        circuitId: circuitData.id,
                      );
                    }
                  }

                  /// Remove the dragged circuit from the zone
                  _projectViewModel.removeCircuitFromSubZone(
                    circuitId: incoming.id,
                    subZoneId: widget.subZoneId,
                  );
                  setState(() {});
                },
                builder: (
                  BuildContext context,
                  List<CircuitModel?> candidateData,
                  List<dynamic> rejectedData,
                ) {
                  return Draggable<CircuitModel>(
                    data: circuitData,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.8,
                        child: SizedBox(
                          width: 220,
                          child: CircuitDeviceWidget(
                            caller: 'sub_zone',
                            prefix: "drag_",
                            index: index,
                            deviceId: deviceId,
                            circuitModel: circuitData,
                            location: location,
                            speakers: speakers,
                            circuitDeviceName: circuitData.name,
                            assetImagePath:
                                serviceLocator<ProjectViewModel>().getHardwareImage(
                                  productId: speakers.first.productId ?? 0,
                                  currentImagePath: speakers.first.assetImagePath,
                                ) ??
                                "",
                            circuitDeviceCount: speakers.length,
                            onDecrementHardwareInCircuit: () {
                              final Speaker speaker = speakers.last;
                              serviceLocator<ProjectViewModel>().removeHardware(
                                hardwareId: speaker.id,
                              );
                            },
                            onIncrementHardwareInCircuit: () {
                              final Speaker speaker = speakers.first.getClone();
                              serviceLocator<ProjectViewModel>().addHardware(
                                hardware: speaker,
                                autoSave: false,
                              );
                              serviceLocator<ProjectViewModel>().addHardwareToCircuit(
                                hwId: speaker.id,
                                circuitId: circuitData.id,
                              );
                            },

                            projectViewModel: _projectViewModel,
                            onRename: () {},
                            onDuplicate: () {},
                            onDelete: () {
                              _projectViewModel.removeCircuitFromSubZone(
                                subZoneId: widget.subZoneId,
                                circuitId: deviceId,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.8,
                        child: SizedBox(
                          width: 220,
                          child: CircuitDeviceWidget(
                            caller: 'sub_zone',
                            prefix: "child_",
                            index: index,
                            circuitModel: circuitData,
                            deviceId: deviceId,
                            location: location,
                            speakers: speakers,
                            circuitDeviceName: circuitData.name,
                            assetImagePath:
                                serviceLocator<ProjectViewModel>().getHardwareImage(
                                  productId: speakers.isNotEmpty ? speakers.first.productId ?? 0 : 0,
                                  currentImagePath: speakers.isNotEmpty ? speakers.first.assetImagePath : '',
                                ) ??
                                "",
                            circuitDeviceCount: speakers.length,
                            onDecrementHardwareInCircuit: () {},
                            onIncrementHardwareInCircuit: () {},
                            projectViewModel: _projectViewModel,
                            onRename: () {},
                            onDuplicate: () {},
                            onDelete: () {},
                          ),
                        ),
                      ),
                    ),
                    child: CircuitDeviceWidget(
                      caller: 'sub_zone',
                      prefix: "child_",
                      index: index,
                      deviceId: deviceId,
                      location: location,
                      speakers: speakers,
                      circuitModel: circuitData,
                      circuitDeviceName: circuitData.name,
                      assetImagePath:
                          serviceLocator<ProjectViewModel>().getHardwareImage(
                            productId: speakers.isNotEmpty ? speakers.first.productId ?? 0 : 0,
                            currentImagePath: speakers.isNotEmpty ? speakers.first.assetImagePath : '',
                          ) ??
                          "",
                      circuitDeviceCount: speakers.length,
                      onDecrementHardwareInCircuit: () {
                        final Speaker speaker = speakers.last;
                        serviceLocator<ProjectViewModel>().removeHardware(
                          hardwareId: speaker.id,
                        );
                      },
                      onIncrementHardwareInCircuit: () {
                        final Speaker speaker = speakers.first.getClone();
                        serviceLocator<ProjectViewModel>().addHardware(
                          hardware: speaker,
                          autoSave: false,
                        );
                        serviceLocator<ProjectViewModel>().addHardwareToCircuit(
                          hwId: speaker.id,
                          circuitId: circuitData.id,
                        );
                      },

                      projectViewModel: _projectViewModel,
                      onRename: () {},
                      onDuplicate: () {},
                      onDelete: () {
                        _projectViewModel.removeCircuitFromSubZone(
                          subZoneId: widget.subZoneId,
                          circuitId: deviceId,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// drag handle icon
  Widget _buildDragHandle() {
    return Icon(
      Icons.drag_indicator,
      size: 16,
      color: Colors.grey[600],
    );
  }

  Widget _buildExpandIcon(BuildContext context, bool expanded) {
    return RotatedBox(
      quarterTurns: expanded ? 0 : 2,
      child: FusionIcon.svg(
        AssetSvg.expandUp,
        size: FusionSizes.iconSize12,
        color: context.colorScheme.iconWhite,
      ),
    );
  }

  Widget _buildZoneName(BuildContext context, String name) {
    return FusionAppText(
      semanticId: "sub_zone_name_${widget.index}",
      text: name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Kebab menu for subzone actions
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
      shadowColor: Colors.transparent,
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<ZoneMenuAction>>[
            /// --- Delete ---
            PopupMenuItem<ZoneMenuAction>(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onTap: () {
                widget.onDelete?.call(widget.subZoneId);
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
        testId: SemanticHelper.createTestId(
          SemanticTypes.button,
          "subzone_item_kebab_menu",
        ),
        child: Icon(
          Icons.more_vert,
          size: 14,
          color: context.colorScheme.textPrimary,
        ),
      ),
    );
  }
}
