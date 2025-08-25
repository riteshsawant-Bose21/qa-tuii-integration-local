import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/floor_entity.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';
import '../common/location_configuration_widget.dart';
import '../common/processing_block_view.dart';
import 'aes_input_field.dart';

class SourceWidget extends StatefulWidget {
  final Source source;
  final void Function(Source) onSourceChanged;
  final VoidCallback onDelete;
  final Function(Floor) onFloorUpdated;
  final Function(Floor) onFloorAdded;
  final bool isControlMode;

  const SourceWidget({
    super.key,
    required this.source,
    required this.onSourceChanged,
    required this.onDelete,
    required this.onFloorUpdated,
    required this.onFloorAdded,
    required this.isControlMode,
  });

  @override
  State<SourceWidget> createState() => _SourceWidgetState();
}

class _SourceWidgetState extends State<SourceWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>(widget.source.id),
      elevation: 0,
      color: AppColors.cardSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: _buildHeader(),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: <Widget>[
            InkWell(
              onTap: () async {
                if (widget.isControlMode) {
                  debugPrint("Cannot configure source in control mode");
                  return;
                }
                final LocationEntity? location = await showConfigureDeviceDialog(
                  context,
                  widget.source.locationEntity,
                  (Floor newFloor) {
                    widget.onFloorAdded(newFloor);
                  },
                  (Floor updatedFloor) {
                    widget.onFloorUpdated(updatedFloor);
                  },
                );

                if (location != null) {
                  Offset? center;

                  if (location.listeningAreaId != null) {
                    final ListeningArea area = serviceLocator<ProjectManager>().value.floors
                        .firstWhere((Floor floor) => floor.id == location.floorId)
                        .listeningAreas
                        .firstWhere((ListeningArea area) => area.id == location.listeningAreaId);

                    //find the center of area.vertices
                    center = Offset(
                      area.vertices.map((Offset v) => v.dx).reduce((double a, double b) => a + b) / area.vertices.length,
                      area.vertices.map((Offset v) => v.dy).reduce((double a, double b) => a + b) / area.vertices.length,
                    );
                  }

                  widget.onSourceChanged(widget.source.copyWith(locationEntity: location, pos: center));
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const Icon(
                      Icons.add_location_alt_outlined,
                      size: 14,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (widget.source.locationEntity.floorId != null || widget.source.locationEntity.listeningAreaId != null)
                              ? getLocation(widget.source.locationEntity)
                              : widget.isControlMode
                              ? "No Location"
                              : "Add Location",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            if (widget.source.fusionDeviceId != null || widget.source.portNumbers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Device Icon
                    const Icon(
                      Icons.memory,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),

                    // Device Name
                    if (widget.source.fusionDeviceId != null) ...<Widget>[
                      Flexible(
                        child: Text(
                          serviceLocator<ProjectManager>().value.fusionDevices.firstWhere((FusionDevice val) => val.id == widget.source.fusionDeviceId).name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Separator
                      if (widget.source.portNumbers.isNotEmpty) ...<Widget>[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 1,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ],

                    // Port Information
                    if (widget.source.portNumbers.isNotEmpty) ...<Widget>[
                      const Icon(
                        Icons.electrical_services,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Port ${widget.source.portNumbers.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (widget.source.type == SourceType.aes67input) ...<Widget>[
              const SizedBox(height: 12),
              IPAddressField(
                initialValue: widget.source.ipAddress,
                isControlMode: widget.isControlMode,
                onChanged:
                    (String val) => widget.onSourceChanged(
                      widget.source.copyWith(ipAddress: val),
                    ),
              ),
              //add a underlined TextField for the IP address
              // Padding(
              //   padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10.0),
              //   child: TextFormField(
              //     initialValue: source.ipAddress,
              //     decoration: const InputDecoration(
              //       labelText: 'IP Address',
              //       border: UnderlineInputBorder(),
              //       isDense: true,
              //       labelStyle: TextStyle(fontSize: 14),
              //     ),
              //
              //     validator: (String? val) {
              //       if (val == null || val.isEmpty) {
              //         return 'IP Address cannot be empty';
              //       }
              //       // Validate IPv4 address format
              //       final RegExp ipRegex = RegExp(
              //         r'^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
              //       );
              //       if (!ipRegex.hasMatch(val)) {
              //         return 'Invalid IP Address format';
              //       }
              //       return null;
              //     },
              //
              //     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              //     onChanged:
              //         (String val) => onSourceChanged(
              //           source.copyWith(ipAddress: val),
              //         ),
              //   ),
              // ),
            ],

            ProcessingBlockView(
              processingType: ProcessingType.input,
              isControlMode: widget.isControlMode,
              selectedBlocks: widget.source.blocks ?? <ProcessingBlockEntity>[],
              onBlocksUpdated:
                  (List<ProcessingBlockEntity> chain) => widget.onSourceChanged(
                    widget.source.copyWith(
                      blocks: chain,
                    ),
                  ),
              onBlockRemoved: (int index) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.source.blocks ?? <ProcessingBlockEntity>[],
                );
                updatedBlocks.removeAt(index);
                widget.onSourceChanged(widget.source.copyWith(blocks: updatedBlocks));
              },
              onBlockSelected: (ProcessingBlockEntity block) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.source.blocks ?? <ProcessingBlockEntity>[],
                );
                updatedBlocks.add(block);
                widget.onSourceChanged(widget.source.copyWith(blocks: updatedBlocks));
              },
            ),
          ],
        ),
      ),
    );
  }

  final TextEditingController _sourceNameController = TextEditingController();

  Widget _buildHeader() {
    _sourceNameController.text = widget.source.name;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Image.asset(
            widget.source.assetImagePath,
            height: 24,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              controller: _sourceNameController,
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),

              enabled: widget.isControlMode ? false : true,

              onFieldSubmitted:
                  (String val) => widget.onSourceChanged(
                    widget.source.copyWith(name: val),
                  ),
            ),
          ),

          // IconButton(
          //   icon: const Icon(Icons.settings, color: AppColors.primarySoft, size: 16),
          //   onPressed: (){
          //     openDeviceConfig(
          //       context,
          //       widget.source,
          //           (Source s) => widget.onSourceChanged(s),
          //     );
          //   },
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          // ),
          if (!widget.isControlMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorSoft, size: 16),
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  String getLocation(LocationEntity location) {
    if (location.floorId != null && location.listeningAreaId != null) {
      final Floor floor = serviceLocator<ProjectManager>().value.floors.firstWhere((Floor floor) => floor.id == location.floorId);

      final ListeningArea area = floor.listeningAreas.firstWhere((ListeningArea area) => area.id == location.listeningAreaId);

      return "${floor.name}/${area.name}"; // Display floor and listening area names
    } else if (location.floorId != null) {
      final Floor floor = serviceLocator<ProjectManager>().value.floors.firstWhere((Floor floor) => floor.id == location.floorId);
      return floor.name; // Display floor number
    } else if (location.listeningAreaId != null) {
      return "Listening Area ${location.listeningAreaId}"; // Display listening area number
    }
    return "No Location";
  }
}
