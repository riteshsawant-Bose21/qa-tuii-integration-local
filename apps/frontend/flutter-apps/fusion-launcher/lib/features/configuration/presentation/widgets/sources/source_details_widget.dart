import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../common/processing_block_view.dart';

void openDeviceConfig(
  BuildContext context,
  Source device,
  Function(Source device) onDeviceUpdated,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Source localDevice = device;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DevicePropertiesWidget(
                    device: localDevice,
                    onDeviceUpdated: (Source updatedDevice) {
                      setState(() {
                        localDevice = updatedDevice;
                      });
                      onDeviceUpdated(updatedDevice);
                    },
                  ),
                  // ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class DevicePropertiesWidget extends StatefulWidget {
  const DevicePropertiesWidget({
    super.key,
    required this.device,
    required this.onDeviceUpdated,
  });

  final Source device;
  final Function(Source deletedRoom) onDeviceUpdated;

  @override
  State<DevicePropertiesWidget> createState() => _DevicePropertiesWidgetState();
}

class _DevicePropertiesWidgetState extends State<DevicePropertiesWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 600,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            spacing: 12.0,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Image.asset(
                    widget.device.assetImagePath,
                    color: Colors.black,
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 150,
                        height: 35,
                        child: TextFormField(
                          initialValue: widget.device.name,
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                            hintText: 'Device Name',
                            filled: false,
                            isDense: false,
                          ),

                          onChanged: (String value) {
                            final Source device = widget.device.copyWith(name: value);
                            widget.onDeviceUpdated(device);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  // final Source? updated = await showConfigureDeviceDialog(context, widget.device, (Source device) {
                  //   setState(() {
                  //     widget.onDeviceUpdated(device);
                  //   });
                  // });
                  // if (updated != null) {
                  //   setState(() {
                  //     widget.onDeviceUpdated(updated);
                  //   });
                  // }
                },
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.add_location_alt_outlined,
                      size: 30,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (widget.device.locationEntity.floorId != null || widget.device.locationEntity.listeningAreaId != null)
                              ? "Fetch room name"
                              : "Add Location",
                          style: const TextStyle(fontSize: 14),
                        ),
                        // Text(
                        //   'Port: ${widget.device.portNumbers != null && widget.device.portNumbers!.isNotEmpty ? widget.device.portNumbers?.join(',') : "--"}',
                        //   style: const TextStyle(
                        //     fontSize: 12,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12.0,
          ),
          // const Padding(
          //   padding: EdgeInsets.symmetric(vertical: 12.0),
          //   child: Icon(
          //     Icons.arrow_downward_rounded,
          //     size: 24,
          //   ),
          // ),
          ProcessingBlockView(
            processingType: ProcessingType.input,
            selectedBlocks: widget.device.blocks,
            isControlMode: false,
            onBlockSelected: (ProcessingBlockModel selected) {
              final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(widget.device.blocks);
              updatedBlocks.add(selected);
              final Source updatedDevice = widget.device.copyWith(blocks: updatedBlocks);
              widget.onDeviceUpdated(updatedDevice);
            },
            onBlockRemoved: (int index) {
              final List<ProcessingBlockModel> updatedBlocks = List<ProcessingBlockModel>.from(widget.device.blocks);
              updatedBlocks.removeAt(index);
              final Source updatedDevice = widget.device.copyWith(blocks: updatedBlocks);
              widget.onDeviceUpdated(updatedDevice);
            },
            onBlocksUpdated: (List<ProcessingBlockModel> updatedBlocksList) {
              final Source updatedDevice = widget.device.copyWith(blocks: updatedBlocksList);
              widget.onDeviceUpdated(updatedDevice);
            },
          ),
          const SizedBox(
            height: 12.0,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
