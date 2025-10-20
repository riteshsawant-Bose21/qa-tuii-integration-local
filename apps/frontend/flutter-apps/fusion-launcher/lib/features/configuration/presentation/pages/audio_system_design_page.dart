import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/core/widgets/collapsible_side_panel.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/widgets/dsp_setup/dsp_column.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_utils/app_settings.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/constants.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/widgets/horizontal_resizable_container.dart';
import '../widgets/mixes/connection_painter.dart';
import '../widgets/mixes/mixes_column.dart';
import '../widgets/sources/sources_column.dart';
import '../widgets/zones/zones_column.dart';

class AudioSystemDesignPage extends StatefulWidget {
  const AudioSystemDesignPage({super.key});

  @override
  AudioSystemDesignPageState createState() => AudioSystemDesignPageState();
}

class AudioSystemDesignPageState extends State<AudioSystemDesignPage> {
  final ScrollController _horizontalController = ScrollController();
  Map<String, List<Offset>> _centersById = <String, List<Offset>>{};

  final TextEditingController _droAddressController = TextEditingController(text: serviceLocator<FusionPreferences>().droServerUrl);
  final TextEditingController _virtualIPController = TextEditingController();
  final TextEditingController _backendUrlController = TextEditingController(text: serviceLocator<FusionPreferences>().fusionCloudBackendUrl);
  final TextEditingController _cloudWebUrlController = TextEditingController(text: serviceLocator<FusionPreferences>().cloudWebUrl);

  // @override
  // void initState() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) => _captureCentersById());
  //   super.initState();
  // }
  //
  // @override
  // void didUpdateWidget(covariant AudioSystemDesignPage oldWidget) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) => _captureCentersById());
  //   super.didUpdateWidget(oldWidget);
  // }

  @override
  void dispose() {
    _droAddressController.dispose();
    _virtualIPController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: SafeArea(
        child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
          listener: (BuildContext context, ProjectViewModelState state) {
            // TODO: implement listener
          },
          builder: (BuildContext context, ProjectViewModelState state) {
            _virtualIPController.text = serviceLocator<ProjectViewModel>().virtualIP ?? '';

            return Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Scrollbar(
                        controller: _horizontalController,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SizedBox(width: 12.0),
                                  HorizontalResizableContainer(
                                    minWidth: AppLayout.sectionWidth,
                                    maxWidth: 1000,
                                    dragLeft: false,
                                    dragRight: true,
                                    child: SourcesColumn(
                                      sources: serviceLocator<ProjectViewModel>().sources,
                                      onSourceChanged: _updateSource,
                                      onSourceDeleted: _deleteSource,
                                      onSourceAdded: _addSource,
                                      isControlMode: serviceLocator<ProjectViewModel>().isInControlMode,
                                      onFloorUpdated: (FloorModel updatedFloor) {
                                        serviceLocator<ProjectViewModel>().updateFloor(floor: updatedFloor);
                                      },
                                      onFloorAdded: (FloorModel newFloor) {
                                        serviceLocator<ProjectViewModel>().addFloor(floor: newFloor);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  HorizontalResizableContainer(
                                    minWidth: AppLayout.sectionWidth,
                                    maxWidth: 1000,
                                    dragLeft: false,
                                    dragRight: true,
                                    child: MixColumn(
                                      mixes: serviceLocator<ProjectViewModel>().sourceSets,
                                      isControlMode: serviceLocator<ProjectViewModel>().isInControlMode,
                                      sources: serviceLocator<ProjectViewModel>().sources,
                                      onMixUpdated: _onMixUpdated,
                                      onMixAdded: _onMixAdded,
                                      onMixDeleted: _onMixDeleted,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  HorizontalResizableContainer(
                                    minWidth: AppLayout.sectionWidth,
                                    maxWidth: 1000,
                                    dragLeft: false,
                                    dragRight: true,
                                    child: ZonesColumn(
                                      zones: serviceLocator<ProjectViewModel>().zones,
                                      sourceSets: serviceLocator<ProjectViewModel>().sourceSets,
                                      isControlMode: serviceLocator<ProjectViewModel>().isInControlMode,
                                      allSpeakers: serviceLocator<ProjectViewModel>().speakers,
                                      sources: serviceLocator<ProjectViewModel>().sources,
                                      onZoneAdded: _addNewZone,
                                      onZoneUpdated: _updateZone,
                                      onZoneDeleted: _deleteZone,
                                      onSpeakerUpdated: (Speaker speakers) {
                                        print("Updating hardware: ${speakers.toJson()}");
                                        serviceLocator<ProjectViewModel>().updateHardware(hardware: speakers);
                                      },
                                      onSpeakerModelUpdated: (Speaker speaker, LocationModel locationModel) {
                                        // Update speaker model for position and rotation changes
                                        // serviceLocator<ProjectViewModel>().updateHardware(speaker);
                                        print("Updating hardware location: ${speaker.toJson()} with location: ${locationModel.toJson()}");
                                        //for location changes
                                        serviceLocator<ProjectViewModel>().updateHardwareLocation(hardwareId: speaker.id, newLocation: locationModel);
                                      },
                                      onSpeakerDeleted: (Speaker speaker) {
                                        serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speaker.id);
                                      },
                                      onSpeakerAdded: (Speaker speaker, String zoneId) {
                                        serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                                        serviceLocator<ProjectViewModel>().addSpeakerToZone(hardwareId: speaker.id, zoneId: zoneId);
                                      },
                                      onFloorUpdated: (FloorModel updatedFloor) {
                                        serviceLocator<ProjectViewModel>().updateFloor(floor: updatedFloor);
                                      },
                                      onFloorAdded: (FloorModel newFloor) {
                                        serviceLocator<ProjectViewModel>().addFloor(floor: newFloor);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),

                                  HorizontalResizableContainer(
                                    minWidth: AppLayout.sectionWidth,
                                    maxWidth: 1000,
                                    dragLeft: false,
                                    dragRight: true,
                                    child: DspColumn(
                                      vipAddress: serviceLocator<ProjectViewModel>().virtualIP,
                                      isControlMode: serviceLocator<ProjectViewModel>().isInControlMode,
                                      droAddress: serviceLocator<FusionPreferences>().droServerUrl,
                                      fusionDevices: serviceLocator<ProjectViewModel>().fusionDevices ?? <FusionDsp>[],
                                      onRequestFusionDeviceList: () {
                                        sendDataToDRO();
                                      },
                                      onSendToDsp: () {
                                        sendToDSP();
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 12.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ConnectionPainter(_centersById),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Properties Panel
                CollapsibleSidePanel(
                  title: 'Properties',
                  icon: Icons.tune,
                  initiallyExpanded: false,
                  expandedWidth: 280,
                  collapsedWidth: 60,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // DRO IP Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'DRO IP',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _droAddressController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter DRO IP address',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // validate ip address and update project
                                    final String ip = _droAddressController.text.trim();
                                    serviceLocator<FusionPreferences>().setDroServerUrl(ip);
                                    // serviceLocator<ProjectViewModel>().updateProject();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('DRO IP updated to $ip'),
                                        backgroundColor: Colors.green.shade600,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Update', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Virtual IP Address Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Virtual IP Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _virtualIPController,
                                readOnly: false,
                                decoration: InputDecoration(
                                  hintText: '192.168.1.100',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                                enabled: true,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    serviceLocator<ProjectViewModel>().setVirtualIP(ip: _virtualIPController.text);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Reconfigure', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Backend Address Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Backend Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _backendUrlController,
                                readOnly: false,
                                decoration: InputDecoration(
                                  hintText: '192.168.1.100',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                                enabled: true,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    serviceLocator<FusionPreferences>().setFusionCloudBackendUrl(_backendUrlController.text);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Configure', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Backend Address Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Cloud web url',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cloudWebUrlController,
                                readOnly: false,
                                decoration: InputDecoration(
                                  hintText: '192.168.1.100',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                                enabled: true,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () {
                                    serviceLocator<FusionPreferences>().setCloudWebUrl(_cloudWebUrlController.text);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Configure', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),
                        // Clear Value Button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    FusionUiUtils.showLoader(context);
                                    final ResponseCallback<dynamic> response = await serviceLocator<FusionNetworkClient>().delete(
                                      api: FusionApiEndpoint.fusionGetValue,
                                    );
                                    if (context.mounted) FusionUiUtils.hideLoader(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Clear value', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //TODO: Add paths between elements based on their IDs
  void _captureCentersById() {
    final Map<String, List<Offset>> newMap = <String, List<Offset>>{};
    void visitor(Element element) {
      final Key? key = element.widget.key;
      if (key is ValueKey<String>) {
        final String id = key.value;
        final RenderObject? renderObj = element.findRenderObject();
        if (renderObj is RenderBox) {
          final Offset center = renderObj.localToGlobal(renderObj.size.center(Offset.zero));
          newMap.putIfAbsent(id, () => <Offset>[]).add(center);
        }
      }
      element.visitChildElements(visitor);
    }

    // start the recursion at your top-level context
    context.visitChildElements(visitor);

    if (!mapEquals(newMap, _centersById)) {
      setState(() => _centersById = newMap);
    }
  }

  // show a dialog with the JSON representation of the audio system data with pretty formatting
  void sendDataToDRO() async {
    serviceLocator<ProjectViewModel>().saveProject();
    /*final Map<String, dynamic> outputJson = JsonFormatConverter.convertFormat(projectManager.value.toJson(), projectManager.value.fusionDevices);

    //show a loader dialog while processing
    FusionUtils.showLoader(context);
    final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().post(api: FusionApiEndpoint.process, data: outputJson);

    if (mounted) {
      FusionUtils.hideLoader(context);
    }

    if (responseCallback.success) {
      final Map<String, dynamic> data = responseCallback.data as Map<String, dynamic>;

      final Map<String, dynamic> result = Map<String, dynamic>.from(data["result"] ?? <dynamic, dynamic>{});

      result.remove("image_input");
      result.remove("image_output");

      data["result"] = result;

      projectManager.updateDroResponse(data);

      final List<dynamic> devices = data["result"]["devices"];

      final List<dynamic> ioPorts = data["result"]["io_ports"];

      // To just print each device_id (may include duplicates)
      for (int i = 0; i < ioPorts.length; i++) {
        final Map<String, dynamic> ioPort = ioPorts[i] as Map<String, dynamic>;
        final String deviceId = ioPort["io_id"];
        final String fusionDeviceId = ioPort["device_id"];
        final List<int> portNumbers = (ioPort["port_nums"] as List<dynamic>).whereType<int>().toList();

        //For AES stream id we are appending AES prefix so remove it while comparing
        HardwareComponent device = projectManager.value.hardwareComponents.firstWhere(
              (HardwareComponent value) => (deviceId.contains("FUSION_") ? value.id == deviceId.replaceAll("FUSION_", "") : value.id == deviceId),
        );

        if (device is Source) {
          device = device.copyWith(fusionDeviceId: fusionDeviceId, portNumbers: portNumbers);
        } else if (device is Speaker) {
          device = device.copyWith(fusionDeviceId: fusionDeviceId, portNumbers: portNumbers);
        }
        projectManager.updateHardwareComponent(device);
      }

      final List<FusionDevice> devicesList = <FusionDevice>[];
      for (Map<String, dynamic> device in devices) {
        FusionDevice fusionDevice = FusionDevice(
          id: device["id"],
          name: device["label"],
          location: device['location'],
          status: FusionDeviceSetupStatus.notStarted,
        );

        fusionDevice = projectManager.getFusionDeviceFromProject(fusionDevice);

        fusionDevice = fusionDevice.copyWith(
          name: device["label"],
          location: device['location'],
        );

        devicesList.add(fusionDevice);
      }

      projectManager.updateFusionDevices(devicesList);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _horizontalController.animateTo(
          _horizontalController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }*/
  }

  void sendToDSP() async {
    serviceLocator<ProjectViewModel>().saveProject();

    /*    //show a loader dialog while processing
    FusionUtils.showLoader(context);

    final Map<String, dynamic> data = projectManager.value.droResponse!;

    final Map<String, dynamic> result = Map<String, dynamic>.from(data["result"] ?? <dynamic, dynamic>{});

    result.remove("image_input");
    result.remove("image_output");

    data["result"] = result;

    // final Map<String, Map<String, dynamic>> updatedModel = <String, Map<String, dynamic>>{
    //   "dsp_static_config": data,
    // };

    final List<dynamic> devices = data["result"]["devices"];

    final Map<String, dynamic> dataForDsp = <String, dynamic>{"devices": devices};

    final Map<String, dynamic> audioStreamData = JsonFormatConverter.getAudioStreamsData(data);

    dataForDsp.addAll(audioStreamData);

    // Clear all dynamic values
    dataForDsp["settings"] = <String, dynamic>{
      "audio": <String, dynamic>{},
    };

    final ResponseCallback<dynamic> fusionServerResponse = await serviceLocator<FusionNetworkClient>().post(
      api: FusionApiEndpoint.fusionUpdateValue,
      data: dataForDsp,
    );

    if (fusionServerResponse.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration is Live!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${fusionServerResponse.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      FusionUtils.hideLoader(context);
    }*/
  }

  void _deleteSource(Source source) {
    serviceLocator<ProjectViewModel>().removeHardware(hardwareId: source.id);
  }

  void _updateSource(Source source) {
    serviceLocator<ProjectViewModel>().updateHardware(hardware: source);
  }

  void _addSource(Source source) {
    serviceLocator<ProjectViewModel>().addHardware(hardware: source);
  }

  void _onMixUpdated(SourceSet p1) {
    serviceLocator<ProjectViewModel>().updateSourceSet(sourceSet: p1);
  }

  void _onMixAdded(SourceSet p1) {
    serviceLocator<ProjectViewModel>().addSourceSet(sourceSet: p1);
  }

  void _onMixDeleted(SourceSet p1) {
    serviceLocator<ProjectViewModel>().removeSourceSet(sourceSetId: p1.id);
  }

  void _addNewZone(Zone p1) {
    serviceLocator<ProjectViewModel>().addZone(zone: p1);
  }

  void _updateZone(Zone updated) {
    serviceLocator<ProjectViewModel>().updateZone(zone: updated);
  }

  void _deleteZone(Zone zone) {
    serviceLocator<ProjectViewModel>().removeZone(zoneId: zone.id);
  }

  // saveProject() {
  //   serviceLocator<ProjectViewModel>().saveProject();
  // }
}
