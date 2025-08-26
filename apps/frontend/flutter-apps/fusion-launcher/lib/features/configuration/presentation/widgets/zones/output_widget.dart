import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/services/project_manager.dart';
import '../common/location_configuration_widget.dart';
import '../common/processing_block_view.dart';

class OutputWidget extends StatefulWidget {
  final Speaker speaker;
  final void Function(Speaker) onOutputChanged;
  final VoidCallback onDelete;
  final Function(FloorModel) onFloorUpdated;
  final Function(FloorModel) onFloorAdded;
  final bool isControlMode;

  const OutputWidget({
    super.key,
    required this.speaker,
    required this.onOutputChanged,
    required this.onDelete,
    required this.onFloorUpdated,
    required this.onFloorAdded,
    required this.isControlMode,
  });

  @override
  OutputWidgetState createState() => OutputWidgetState();
}

class OutputWidgetState extends State<OutputWidget> {
  final TextEditingController _ipaddressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.speaker.ipAddress != null) {
      _ipaddressController.text = widget.speaker.ipAddress!;
    }
  }

  @override
  void dispose() {
    _ipaddressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.cardSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey<String>(widget.speaker.id),
          title: _buildHeader(),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: <Widget>[
            InkWell(
              onTap: () async {
                if (widget.isControlMode) {
                  return;
                }

                final LocationModel? location = await showConfigureDeviceDialog(
                  context,
                  widget.speaker.locationEntity,
                  (FloorModel newFloor) {
                    widget.onFloorAdded(newFloor);
                  },
                  (FloorModel updatedFloor) {
                    widget.onFloorUpdated(updatedFloor);
                  },
                );

                if (location != null) {
                  Offset? center;

                  if (location.listeningAreaId != null) {
                    final ListeningArea area = serviceLocator<ProjectManager>().value.floors
                        .firstWhere((FloorModel floor) => floor.id == location.floorId)
                        .listeningAreas
                        .firstWhere((ListeningArea area) => area.id == location.listeningAreaId);

                    //find the center of area.vertices
                    center = Offset(
                      area.vertices.map((Offset v) => v.dx).reduce((double a, double b) => a + b) / area.vertices.length,
                      area.vertices.map((Offset v) => v.dy).reduce((double a, double b) => a + b) / area.vertices.length,
                    );
                  }

                  widget.onOutputChanged(widget.speaker.copyWith(locationEntity: location, pos: center));
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
                          (widget.speaker.locationEntity.floorId != null || widget.speaker.locationEntity.listeningAreaId != null)
                              ? getLocation(widget.speaker.locationEntity)
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

            Builder(
              builder: (BuildContext context) {
                final ProjectData pm = serviceLocator<ProjectManager>().value;
                final List<FusionDevice> devices = pm.fusionDevices;
                FusionDevice? device;
                try {
                  device =
                      widget.speaker.fusionDeviceId != null
                          ? devices.firstWhere((FusionDevice d) {
                            return d.id == widget.speaker.fusionDeviceId;
                          })
                          : null;
                } catch (e) {
                  return const SizedBox.shrink();
                }

                if (device == null && widget.speaker.portNumbers.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
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
                      const Icon(Icons.memory, size: 14, color: Colors.white),
                      const SizedBox(width: 8),

                      // only show the name if we actually found the device
                      if (device != null) ...<Widget>[
                        Flexible(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        if (widget.speaker.portNumbers.isNotEmpty) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ],

                      // port numbers (if any)
                      if (widget.speaker.portNumbers.isNotEmpty) ...<Widget>[
                        const Icon(Icons.electrical_services, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Port ${widget.speaker.portNumbers.join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            if (widget.speaker.type == OutputType.aes67output) ...<Widget>[
              const SizedBox(height: 8),
              //add a underlined TextField for the IP address
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10.0),
                      child: TextFormField(
                        controller: _ipaddressController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          labelStyle: TextStyle(fontSize: 14),
                        ),

                        validator: (String? val) {
                          if (val == null || val.isEmpty) {
                            return 'IP Address cannot be empty';
                          }
                          // Validate IPv4 address format
                          final RegExp ipRegex = RegExp(
                            r'^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
                          );
                          if (!ipRegex.hasMatch(val)) {
                            return 'Invalid IP Address format';
                          }
                          return null;
                        },

                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        onFieldSubmitted: (String val) {
                          print("IP Address changed to: $val");
                          final Speaker updatedSpeaker = widget.speaker.copyWith(ipAddress: val);
                          print("Updated Speaker: ${updatedSpeaker.ipAddress}");
                          widget.onOutputChanged(updatedSpeaker);
                        },
                      ),
                    ),
                  ),
                  //Save button
                  IconButton(
                    icon: const Icon(Icons.save, color: AppColors.primarySoft, size: 20),
                    onPressed: () {
                      final Speaker updatedSpeaker = widget.speaker.copyWith(ipAddress: _ipaddressController.text);
                      widget.onOutputChanged(updatedSpeaker);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],

            ProcessingBlockView(
              processingType: ProcessingType.output,
              isControlMode: widget.isControlMode,
              selectedBlocks: widget.speaker.blocks ?? <ProcessingBlockModel>[],
              onBlocksUpdated: (List<ProcessingBlockModel> chain) {
                widget.onOutputChanged(
                  widget.speaker.copyWith(
                    blocks: chain,
                  ),
                );
              },
              onBlockRemoved: (int index) {
                final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(
                  widget.speaker.blocks ?? <ProcessingBlockModel>[],
                );
                updatedBlocks.removeAt(index);
                widget.onOutputChanged(widget.speaker.copyWith(blocks: updatedBlocks));
              },
              onBlockSelected: (ProcessingBlockModel block) {
                final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(
                  widget.speaker.blocks ?? <ProcessingBlockModel>[],
                );
                updatedBlocks.add(block);
                widget.onOutputChanged(widget.speaker.copyWith(blocks: updatedBlocks));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    _nameController.text = widget.speaker.name;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Image.asset(
            widget.speaker.assetImagePath,
            height: 24,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              controller: _nameController,
              enabled: widget.isControlMode ? false : true,
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
              onFieldSubmitted: (String val) {
                widget.onOutputChanged(
                  widget.speaker.copyWith(name: val),
                );
              },
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
              onPressed: () {
                widget.onDelete();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  String getLocation(LocationModel location) {
    if (location.floorId != null && location.listeningAreaId != null) {
      final FloorModel floor = serviceLocator<ProjectManager>().value.floors.firstWhere((FloorModel floor) => floor.id == location.floorId);

      final ListeningArea area = floor.listeningAreas.firstWhere((ListeningArea area) => area.id == location.listeningAreaId);

      return "${floor.name}/${area.name}"; // Display floor and listening area names
    } else if (location.floorId != null) {
      final FloorModel floor = serviceLocator<ProjectManager>().value.floors.firstWhere((FloorModel floor) => floor.id == location.floorId);
      return floor.name; // Display floor number
    } else if (location.listeningAreaId != null) {
      return "Listening Area ${location.listeningAreaId}"; // Display listening area number
    }
    return "No Location";
  }
}
