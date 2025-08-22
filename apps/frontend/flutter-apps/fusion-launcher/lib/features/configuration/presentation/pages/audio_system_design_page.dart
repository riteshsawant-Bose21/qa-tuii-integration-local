import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_launcher/core/models/hardware_component_entity.dart';
import 'package:fusion_launcher/core/models/mix_entity.dart';
import 'package:fusion_launcher/core/models/source_entity.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/core/widgets/collapsible_side_panel.dart';
import 'package:fusion_launcher/features/configuration/presentation/widgets/dsp_setup/dsp_column.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/fusion_utils/app_settings.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/constants.dart';
import '../../../../core/models/floor_entity.dart';
import '../../../../core/models/project_entity.dart';
import '../../../../core/models/speaker_entity.dart';
import '../../../../core/models/zone_entity.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/project_manager.dart';
import '../../../../core/utils/dro_json_mapper.dart';
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
  final ProjectManager projectManager = serviceLocator<ProjectManager>();
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
        child: ValueListenableBuilder<ProjectEntity>(
          valueListenable: projectManager,
          builder: (BuildContext context, ProjectEntity data, _) {
            _virtualIPController.text = data.virtualIP ?? '';

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
                                      sources: data.hardwareComponents.whereType<Source>().toList(),
                                      onSourceChanged: _updateSource,
                                      onSourceDeleted: _deleteSource,
                                      onSourceAdded: _addSource,
                                      isControlMode: data.isInControlMode,
                                      onFloorUpdated: (Floor updatedFloor) {
                                        projectManager.updateFloor(updatedFloor);
                                      },
                                      onFloorAdded: (Floor newFloor) {
                                        projectManager.addFloor(newFloor);
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
                                      mixes: data.mixes,
                                      isControlMode: data.isInControlMode,
                                      sources: data.hardwareComponents.whereType<Source>().cast<Source>().toList(),
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
                                      zones: data.zones,
                                      sourceSets: data.mixes,
                                      isControlMode: data.isInControlMode,
                                      allSpeakers: data.hardwareComponents.whereType<Speaker>().cast<Speaker>().toList(),
                                      sources: data.hardwareComponents.whereType<Source>().cast<Source>().toList(),
                                      onZoneAdded: _addNewZone,
                                      onZoneUpdated: _updateZone,
                                      onZoneDeleted: _deleteZone,
                                      onSpeakerUpdated: (Speaker speakers) {
                                        projectManager.updateHardwareComponent(speakers);
                                      },
                                      onSpeakerDeleted: (Speaker speaker) {
                                        projectManager.removeHardwareComponent(speaker.id);
                                      },
                                      onSpeakerAdded: (Speaker speaker) {
                                        projectManager.addHardwareComponent(speaker);
                                      },
                                      onFloorUpdated: (Floor updatedFloor) {
                                        projectManager.updateFloor(updatedFloor);
                                      },
                                      onFloorAdded: (Floor newFloor) {
                                        projectManager.addFloor(newFloor);
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
                                      vipAddress: data.virtualIP,
                                      isControlMode: data.isInControlMode,
                                      droAddress: serviceLocator<FusionPreferences>().droServerUrl,
                                      fusionDevices: data.fusionDevices ?? <FusionDevice>[],
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
                                    projectManager.notifyDataChange();
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
                                    projectManager.updateVip(_virtualIPController.text);
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
                                    FusionUtils.showLoader(context);
                                    final ResponseCallback<dynamic> response = await serviceLocator<FusionNetworkClient>().delete(
                                      api: FusionApiEndpoint.fusionGetValue,
                                    );
                                    if (context.mounted) FusionUtils.hideLoader(context);
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
    projectManager.saveProject();
    final Map<String, dynamic> outputJson = JsonFormatConverter.convertFormat(projectManager.value.toJson(), projectManager.value.fusionDevices);

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
    }
  }

  void sendToDSP() async {
    projectManager.saveProject();

    //show a loader dialog while processing
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
    }
  }

  void _deleteSource(Source source) {
    projectManager.removeHardwareComponent(source.id);
    projectManager.saveProject();
  }

  void _updateSource(Source source) {
    projectManager.updateHardwareComponent(source);
    projectManager.saveProject();
  }

  void _addSource(Source source) {
    projectManager.addHardwareComponent(source);
    projectManager.saveProject();
  }

  void _onMixUpdated(Mix p1) {
    projectManager.updateMix(p1);
    projectManager.saveProject();
  }

  void _onMixAdded(Mix p1) {
    projectManager.addMix(p1);
    projectManager.saveProject();
  }

  void _onMixDeleted(Mix p1) {
    projectManager.removeMix(p1.id);
    projectManager.saveProject();
  }

  void _addNewZone(Zone p1) {
    projectManager.addZone(p1);
    projectManager.saveProject();
  }

  void _updateZone(Zone updated) {
    projectManager.updateZone(updated);
    projectManager.saveProject();
  }

  void _deleteZone(Zone zone) {
    projectManager.removeZone(zone.id);
    projectManager.saveProject();
  }
}
