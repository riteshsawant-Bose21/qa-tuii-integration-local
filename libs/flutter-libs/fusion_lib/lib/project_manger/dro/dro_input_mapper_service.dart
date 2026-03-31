import 'package:fusion_lib/fusion_lib.dart';

extension DroInputMapperService on ProjectService {
  DroInputModel getDroInputData() {
    DroInputModel droInputModel = DroInputModel(
      requestId: FusionUtils.shortStringUUID(),
      version: "1.0",
    );

    //Add Property Settings
    droInputModel = updateProjectSetting(droInputModel);

    //update input stream data
    droInputModel = updateInputStreamData(droInputModel);

    //update the Source data
    droInputModel = updateSourceData(droInputModel);

    //update the source sets data
    droInputModel = updateSourceSetsData(droInputModel);

    //update zone functions
    droInputModel = updateZoneFunctionsData(droInputModel);

    //Update Zone & subzones data
    droInputModel = updateSubZonesData(droInputModel);

    //Update Outputs data
    droInputModel = updateOutputsData(droInputModel);

    //Update Composite chains data
    droInputModel = updateCompositeChainsData(droInputModel);

    //update output stream data
    droInputModel = updateOutputStreamData(droInputModel);

    //Update userSettings data
    droInputModel = updateUserSettingsData(droInputModel);

    return droInputModel;
  }

  DroInputModel updateProjectSetting(DroInputModel droInputModel) {
    //Update Property Settings
    droInputModel = droInputModel.copyWith(
      propertySettings: [
        DroPropertySetting(
          name: "sample_rate",
          value: 48000,
        ),
        DroPropertySetting(
          name: "frame_size",
          value: 32,
        ),
      ],
    );
    return droInputModel;
  }

  DroInputModel updateInputStreamData(DroInputModel droInputModel) {
    //Update Input Stream Data
    droInputModel = droInputModel.copyWith(
      //input steam not implemented yet, so we will use empty list for now
      inputStreams: [],
    );
    return droInputModel;
  }

  DroInputModel updateSourceData(DroInputModel droInputModel) {
    List<DroSource> droSources = [];

    for (Source source in getAllHardware().whereType<Source>()) {
      //ignore this location for now
      String locationName = "";
      // String locationName = source.locationEntity.listeningAreaId != null ? getListeningAreaById(source.locationEntity.listeningAreaId!)?.name ?? "" : "";

      droSources.add(
        DroSource(
          id: source.id,
          name: source.name,
          serverLocation: locationName,
          ioType: source.connectionType.connectionType,
          ioProperties: IoProperties(
            channels: 1,
          ),
          processingBlocks: getProcessingBlocksData(source.id),
        ),
      );
    }

    //Update Source Data
    droInputModel = droInputModel.copyWith(
      sources: droSources,
    );
    return droInputModel;
  }

  List<DroProcessingBlock> getProcessingBlocksData(String parent, {bool isUserFacing = false}) {
    List<DroProcessingBlock> processingBlocks = [];

    List<ProcessingBlockModel> processingBlockModels = getProcessingBlockFor(parentId: parent, includeUserBlocks: isUserFacing);

    if (isUserFacing) {
      processingBlockModels = processingBlockModels.where((block) => block.isforUser).toList();
    }

    for (ProcessingBlockModel block in processingBlockModels) {
      Map<String, dynamic> algorithmProperties = {};
      // for (PropertySetting property in block.properties) {
      //   if (property.dimension == null) {
      //     algorithmProperties[property.name] = property.value;
      //   } else {
      //     algorithmProperties["${property.name}[${property.dimension}]"] = property.value;
      //   }
      // }

      if (block.properties.isNotEmpty) {
        int bands = 0;
        for (PropertySetting property in block.properties) {
          if (property.dimension != null) {
            if (property.dimension! > bands) {
              bands = property.dimension!;
            }
          }
        }
        if (bands > 0) {
          algorithmProperties["bands"] = bands + 1;
        }
      }

      processingBlocks.add(
        DroProcessingBlock(
          id: block.id,
          name: block.name,
          algorithm: block.algorithmId,
          algorithmProperties: algorithmProperties,
        ),
      );
    }
    return processingBlocks;
  }

  DroInputModel updateSourceSetsData(DroInputModel droInputModel) {
    List<DroSourceSet> droSourceSets = [];

    for (SourceSet sourceSet in sourceSets.getAll()) {
      List<String> sourceIds = getSourcesInSourceSet(sourceSet.id).map((Source source) => source.id).toList();
      droSourceSets.add(
        DroSourceSet(
          id: sourceSet.id,
          name: sourceSet.name,
          //No Algorithm added for sources sets yet, need to add Matrix mexer later
          algorithm: "",
          algorithmProperties: {},
          algorithmTerminals: null,
          sources: sourceIds,
          sourceConnections: [],
          processingBlocks: getProcessingBlocksData(sourceSet.id),
        ),
      );
    }
    //Update Source Sets Data
    droInputModel = droInputModel.copyWith(
      sourceSets: droSourceSets,
    );
    return droInputModel;
  }

  //Update Zone Functions Data
  DroInputModel updateZoneFunctionsData(DroInputModel droInputModel) {
    List<DroZoneFunction> droZoneFunctions = [];

    for (Zone zone in zones.getAll()) {
      ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: zone.id);
      if (zoneFunction == null) {
        continue;
      }

      List<Source> functionSources = getSourcesAndSourceSetSourcesInZone(zoneId: zone.id);

      List<DroSourceConnection> droSourceConnections = [];
      for (int i = 0; i < functionSources.length; i++) {
        Source source = functionSources[i];
        droSourceConnections.add(
          DroSourceConnection(
            sourceChainId: source.id,
            sourceTerminal: "out",
            sourceChannel: 1,
            destinationTerminal: "in",
            destinationChannel: i + 1,
          ),
        );
      }

      List<PrioritySourceData> prioritySources = getPrioritySourcesDataInZone(zone.id);

      if (prioritySources.isNotEmpty) {
        for (int i = 0; i < prioritySources.length; i++) {
          PrioritySourceData prioritySource = prioritySources[i];
          droSourceConnections.add(
            DroSourceConnection(
              sourceChainId: prioritySource.sourceId,
              sourceTerminal: "out",
              sourceChannel: 1,
              destinationTerminal: "paging_in",
              destinationChannel: i + 1,
            ),
          );
        }
      }

      Map<String, dynamic> algorithmProperties = prioritySources.isEmpty
          ? {
              "source_channels": 1,
            }
          : {
              "source_channels": 1,
              "total_channels": functionSources.length + 1,
              "priority_count": prioritySources.length,
            };

      droZoneFunctions.add(
        DroZoneFunction(
          id: zoneFunction.id,
          name: zoneFunction.name,
          algorithm: zoneFunction.algorithmName,
          algorithmProperties: algorithmProperties,
          algorithmTerminals: DroAlgorithmTerminals(
            inTerminal: functionSources.length,
            outTerminal: 1,
          ),
          sourceConnections: droSourceConnections,
        ),
      );
    }

    droInputModel = droInputModel.copyWith(
      zoneFunctions: droZoneFunctions,
    );
    return droInputModel;
  }

  //Update subzones data
  DroInputModel updateSubZonesData(DroInputModel droInputModel) {
    List<DroSubzone> droSubZones = [];

    final List<Zone> allZones = zones.getAll();
    for (int i = 0; i < allZones.length; i++) {
      Zone zone = allZones[i];
      final ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: zone.id);

      List<DroSourceConnection> droSourceConnections = [];

      droSourceConnections.add(
        DroSourceConnection(
          sourceChainId: zoneFunction?.id,
          sourceTerminal: "out",
          sourceChannel: 1,
          destinationTerminal: "in",
          destinationChannel: i + 1,
        ),
      );

      List<DroProcessingBlock> userFacingBlocks = getProcessingBlocksData(zone.id, isUserFacing: true);

      final DroSubzoneControl droZoneControl = DroSubzoneControl(
        id: zone.id,
        name: zone.name,
        sourceChannels: 1,
        algorithm: "source_selector",
        algorithmProperties: {
          "source_channels": 1,
        },
        algorithmTerminals: DroAlgorithmTerminals(
          inTerminal: droSourceConnections.length,
          outTerminal: 1,
        ),
        sourceConnections: droSourceConnections,
        processingBlocks: userFacingBlocks,
      );

      DroSubzoneProcessing? droZoneProcessing;
      //blocks which are added by tapping on the processing block icon
      List<DroProcessingBlock> integratorBlocks = getProcessingBlocksData(zone.id);

      if (integratorBlocks.isNotEmpty) {
        droZoneProcessing = DroSubzoneProcessing(
          id: getZoneProcessingId(zone.id),
          name: zone.name,
          algorithm: "",
          algorithmProperties: {},
          sourceChannels: 1,
          sourceConnections: [
            DroSourceConnection(
              sourceChainId: droZoneControl.id,
              sourceTerminal: "out",
              sourceChannel: 1,
              destinationTerminal: "in",
              destinationChannel: 1,
            ),
          ],
          processingBlocks: integratorBlocks,
        );
      }

      droSubZones.add(
        DroSubzone(
          subzoneControl: droZoneControl,
          subzoneProcessing: droZoneProcessing,
        ),
      );
    }

    for (SubZone subZone in subZones.getAll()) {
      Zone zone = getZoneForSubZone(subZoneId: subZone.id);

      List<DroSourceConnection> droSourceConnections = [];

      droSourceConnections.add(
        DroSourceConnection(
          sourceChainId: zone.id,
          sourceTerminal: "out",
          sourceChannel: 1,
          destinationTerminal: "in",
          destinationChannel: 1,
        ),
      );

      //get user facing processing blocks for subzone control
      List<DroProcessingBlock> userFacingBlocks = getProcessingBlocksData(subZone.id, isUserFacing: true);

      DroSubzoneControl droSubzoneControl = DroSubzoneControl(
        id: subZone.id,
        name: subZone.name,
        sourceChannels: 1,
        algorithm: "source_selector",
        algorithmProperties: {"source_channels": 1},
        algorithmTerminals: DroAlgorithmTerminals(
          inTerminal: droSourceConnections.length,
          outTerminal: 1,
        ),
        sourceConnections: droSourceConnections,
        processingBlocks: userFacingBlocks,
      );

      //integrator blocks for subzone processing
      List<DroProcessingBlock> integratorBlocks = getProcessingBlocksData(subZone.id);

      DroSubzoneProcessing? droSubzoneProcessing;

      if (integratorBlocks.isNotEmpty) {
        List<DroSourceConnection> droSourceControlConnections = [];

        droSourceControlConnections.add(
          DroSourceConnection(
            sourceChainId: droSubzoneControl.id,
            sourceTerminal: "out",
            sourceChannel: 1,
            destinationTerminal: "in",
            destinationChannel: 1,
          ),
        );

        droSubzoneProcessing = DroSubzoneProcessing(
          id: getZoneProcessingId(subZone.id),
          name: subZone.name,
          algorithmProperties: {},
          sourceChannels: 1,
          //need to update this when stereo is implemented
          algorithm: "",
          sourceConnections: droSourceControlConnections,
          processingBlocks: integratorBlocks,
        );
      }

      droSubZones.add(
        DroSubzone(
          subzoneControl: droSubzoneControl,
          subzoneProcessing: droSubzoneProcessing, //droSubzoneProcessing,
        ),
      );
    }

    droInputModel = droInputModel.copyWith(
      subzones: droSubZones,
    );
    return droInputModel;
  }

  //Update outputs data
  DroInputModel updateOutputsData(DroInputModel droInputModel) {
    List<DroOutput> droOutputs = [];

    List<CircuitModel> allCircuits = circuits.getAll();

    for (CircuitModel circuit in allCircuits) {
      final Zone? zone = getZoneForCircuit(circuit.id);

      final SubZone? subZone = getSubZoneForCircuit(circuit.id);

      // final List<Speaker> circuitSpeaker = getHardwareForCircuit(circuit.id).whereType<Speaker>().toList();

      // ignore this location for now
      // String locationName = circuitSpeaker.first.locationEntity.listeningAreaId != null
      //     ? getListeningAreaById(circuitSpeaker.first.locationEntity.listeningAreaId!)?.name ?? ""
      //     : "";

      String locationName = "";

      List<DroSourceConnection> droSourceConnections = [];

      if (zone != null) {
        //check if integrator blocks are there for zone, if yes then connect circuit to zone processing block instead of zone control

        List<DroProcessingBlock> integratorBlocks = getProcessingBlocksData(zone.id);

        String circuitChainId = integratorBlocks.isEmpty ? zone.id : getZoneProcessingId(zone.id);

        droSourceConnections.add(
          DroSourceConnection(
            sourceChainId: circuitChainId,
            sourceTerminal: "out",
            sourceChannel: 1,
            destinationTerminal: "in",
            destinationChannel: 1,
          ),
        );
      } else if (subZone != null) {
        //check if integrator blocks are there for subzone, if yes then connect circuit to subzone processing block instead of subzone control
        List<DroProcessingBlock> integratorBlocks = getProcessingBlocksData(subZone.id);
        String circuitChainId = integratorBlocks.isEmpty ? subZone.id : getZoneProcessingId(subZone.id);

        droSourceConnections.add(
          DroSourceConnection(
            sourceChainId: circuitChainId,
            sourceTerminal: "out",
            sourceChannel: 1,
            destinationTerminal: "in",
            destinationChannel: 1,
          ),
        );
      }

      droOutputs.add(
        DroOutput(
          id: circuit.id,
          name: circuit.name,
          ioType: "analog",
          //todo: need to add connection type for circuit
          serverLocation: locationName,
          ioProperties: IoProperties(
            channels: 1,
          ),
          sourceChannels: 1,
          algorithm: "source_selector",
          algorithmProperties: {
            "source_channels": 1,
          },
          algorithmTerminals: DroAlgorithmTerminals(
            inTerminal: droSourceConnections.length,
            outTerminal: 1,
          ),
          sourceConnections: droSourceConnections,
          processingBlocks: getProcessingBlocksData(circuit.id),
        ),
      );
    }

    droInputModel = droInputModel.copyWith(
      outputs: droOutputs,
    );
    return droInputModel;
  }

  //Update composite chains data
  DroInputModel updateCompositeChainsData(DroInputModel droInputModel) {
    List<DroCompositeChain> droCompositeChains = [];

    //No composite chains implemented yet, so we will use empty list for now

    droInputModel = droInputModel.copyWith(
      compositeChains: droCompositeChains,
    );
    return droInputModel;
  }

  //Update output stream data
  DroInputModel updateOutputStreamData(DroInputModel droInputModel) {
    List<DroOutputStream> droOutputStreams = [];

    //No output steam implemented yet, so we will use empty list for now

    droInputModel = droInputModel.copyWith(
      outputStreams: droOutputStreams,
    );
    return droInputModel;
  }

  //Update user settings data
  DroInputModel updateUserSettingsData(DroInputModel droInputModel) {
    List<DroIoPorts> droIoPorts = [];

    List<DroMaxDevice> droMaxDevices = [];
    for (FusionDsp dsp in getAllHardware().whereType<FusionDsp>()) {
      DroMaxDevice droMaxDevice = DroMaxDevice(
        deviceId: dsp.id,
        deviceType: "fusion_c1",
        deviceLocation: "", //Do not pass the location, DRO is currently does not handle equipment locations
        // deviceLocation: getEquipLocationForHardware(dsp.id)?.name,
      );
      droMaxDevices.add(droMaxDevice);

      List<WiringConnectionModel> wiringConnections = getConnectionForDevice(dsp.id) ?? [];
      for (WiringConnectionModel connection in wiringConnections) {
        List<PortData> inputPorts = dsp.inputPortsData;
        List<PortData> outPutPorts = dsp.outputPortsData;
        List<PortData> comPorts = dsp.communicationPorts;
        //check if the connection port id is in the input ports of the dsp
        bool isInputConnect = (inputPorts.any((port) => port.id == connection.portId || port.id == connection.targetPortId));
        if (isInputConnect) {
          PortData portData = inputPorts.firstWhere((port) => port.id == connection.portId || port.id == connection.targetPortId);
          droIoPorts.add(
            DroIoPorts(
              ioId: dsp.id == connection.deviceId ? connection.targetDeviceId : connection.deviceId,
              deviceId: dsp.id,
              portType: "io_in_analog",
              portNums: [
                portData.portNumber,
              ],
            ),
          );
        }

        bool isCommunicationConnect = (comPorts.any((port) => port.id == connection.portId));
        if (isCommunicationConnect) {
          PortData portData = comPorts.firstWhere((port) => port.id == connection.portId);
          droIoPorts.add(
            DroIoPorts(
              ioId: connection.targetDeviceId,
              deviceId: dsp.id,
              portType: portData.type.name,
              portNums: [
                portData.portNumber,
              ],
            ),
          );
        }
      }
    }

    // todo: confirm if we need to add amps or not
    // for (Amplifier amps in getAllHardware().whereType<Amplifier>()) {
    //   DroMaxDevice droMaxDevice = DroMaxDevice(
    //     deviceId: amps.id,
    //     deviceType: "amplifier",
    //     deviceLocation: getEquipLocationForHardware(amps.id)?.name,
    //   );
    //   droMaxDevices.add(droMaxDevice);
    // }

    DroUserSetting droUserSetting = DroUserSetting(
      maxDevices: droMaxDevices,
      ioPorts: droIoPorts,
      deviceCapacity: 90,
      maxSolveTime: 60,
      maxDeviceHopCount: 10,
      maxNetworkLatency: 50,
      costOption: 1,
    );
    droInputModel = droInputModel.copyWith(
      userSetting: droUserSetting,
    );
    return droInputModel;
  }

  // String getControlId(String parentId) {
  //   return "$parentId";
  // }

  String getZoneProcessingId(String parentId) {
    return "p$parentId";
  }
}
