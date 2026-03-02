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

    //update zone Controls
    droInputModel = updateZoneControlsData(droInputModel);

    //Update subzones data
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
      String locationName = source.locationEntity.listeningAreaId != null ? getListeningAreaById(source.locationEntity.listeningAreaId!)?.name ?? "" : "";

      droSources.add(
        DroSource(
          id: source.id,
          name: source.name,
          serverLocation: locationName,
          ioType: source.connectionType != SourceConnectionType.aes67input ? "analog" : "aes67",
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

  List<DroProcessingBlock> getProcessingBlocksData(String parent) {
    List<DroProcessingBlock> processingBlocks = [];

    List<ProcessingBlockModel> processingBlockModels = getProcessingBlockFor(parent);
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

      droZoneFunctions.add(
        DroZoneFunction(
          id: zone.id,
          name: zoneFunction.name,
          algorithm: zoneFunction.algorithmName,
          algorithmProperties: {"source_channels": 1},
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

  //Update the zone controls data
  DroInputModel updateZoneControlsData(DroInputModel droInputModel) {
    List<DroZoneControl> droZoneControls = [];

    for (Zone zone in zones.getAll()) {
      final ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: zone.id);

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

      List<DroProcessingBlock> processingBlocks = getProcessingBlocksData(zone.id);

      final DroZoneControl droZoneControl = DroZoneControl(
        id: getControlId(zone.id),
        name: zone.name,
        algorithm: zoneFunction?.algorithmName ?? "",
        algorithmProperties: {"source_channels": 1},
        algorithmTerminals: DroAlgorithmTerminals(
          inTerminal: 1,
          outTerminal: 1,
        ),
        sourceConnections: droSourceConnections,
        processingBlocks: processingBlocks,
      );

      droZoneControls.add(
        droZoneControl,
      );
    }

    droInputModel = droInputModel.copyWith(
      zoneControls: droZoneControls,
    );
    return droInputModel;
  }

  //Update subzones data
  DroInputModel updateSubZonesData(DroInputModel droInputModel) {
    List<DroSubzone> droSubZones = [];

    //todo: confirm if its required... remove if zones need not have subzones in dro input when there is no subzone in the user interface
    final List<Zone> zones = getZonesWithoutSubzones();
    for (Zone zone in zones) {
      //if the zone does not have subzone, we will create a subzone with the same name as the zone and connect it to the zone control, this is because the integrator needs to have a subzone to connect the circuit to even if there is no subzone in the user interface
      droSubZones.add(
        DroSubzone(
          id: zone.id,
          subzoneControl: DroSubzoneControl(
            id: getControlId(zone.id),
            name: zone.name,
            algorithm: "",
            algorithmProperties: {"source_channels": 1},
            algorithmTerminals: DroAlgorithmTerminals(
              inTerminal: 1,
              outTerminal: 1,
            ),
            sourceConnections: [
              DroSourceConnection(
                sourceChainId: getControlId(zone.id), //get parent zone control id to connect to
                sourceTerminal: "out",
                sourceChannel: 1,
                destinationTerminal: "in",
                destinationChannel: 1,
              ),
            ],
            processingBlocks: getProcessingBlocksData(zone.id), //User facing processing blocks, eg: gain
          ),
          subzoneProcessing: DroSubzoneProcessing(
            id: getZoneProcessingId(zone.id),
            name: zone.name,
            algorithmProperties: {},
            sourceChannels: 1, //need to update this when stereo is implemented
            algorithm: "",
            sourceConnections: [
              DroSourceConnection(
                sourceChainId: getControlId(zone.id), //get parent zone control id to connect to
                sourceTerminal: "out",
                sourceChannel: 1,
                destinationTerminal: "in",
                destinationChannel: 1,
              ),
            ],
            processingBlocks: [], //Need to add processing block used by only integrator ex PEQ  //getProcessingBlocksData(zone.id),
          ),
        ),
      );
    }

    for (SubZone subZone in subZones.getAll()) {
      Zone zone = getZoneForSubZone(subZoneId: subZone.id);

      ZoneFunctions? zoneFunction = getZoneFunction(zoneOrSubZoneId: zone.id);

      List<DroSourceConnection> droSourceConnections = [];

      droSourceConnections.add(
        DroSourceConnection(
          sourceChainId: getControlId(zone.id), //get parent zone control id to connect to
          sourceTerminal: "out",
          sourceChannel: 1,
          destinationTerminal: "in",
          destinationChannel: 1,
        ),
      );

      DroSubzoneControl droSubzoneControl = DroSubzoneControl(
        id: getControlId(subZone.id),
        name: subZone.name,
        algorithm: zoneFunction?.algorithmName ?? "",
        algorithmProperties: {"source_channels": 1},
        algorithmTerminals: DroAlgorithmTerminals(
          inTerminal: 1,
          outTerminal: 1,
        ),
        sourceConnections: droSourceConnections,
        processingBlocks: getProcessingBlocksData(subZone.id), //User facing processing blocks, eg: gain
      );

      List<DroSourceConnection> droSourceControlConnections = [];

      droSourceControlConnections.add(
        DroSourceConnection(
          sourceChainId: getControlId(subZone.id), //get parent zone control id to connect to
          sourceTerminal: "out",
          sourceChannel: 1,
          destinationTerminal: "in",
          destinationChannel: 1,
        ),
      );

      DroSubzoneProcessing droSubzoneProcessing = DroSubzoneProcessing(
        id: getZoneProcessingId(subZone.id),
        name: subZone.name,
        algorithmProperties: {},
        sourceChannels: 1, //need to update this when stereo is implemented
        algorithm: "",
        sourceConnections: droSourceControlConnections,
        processingBlocks: [], //Need to add processing block used by only integrator ex PEQ  //getProcessingBlocksData(subZone.id),
      );

      droSubZones.add(
        DroSubzone(
          id: subZone.id,
          subzoneControl: droSubzoneControl,
          subzoneProcessing: droSubzoneProcessing,
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

      ZoneFunctions? circuitZoneFunction;
      if (zone != null || subZone != null) {
        String parentId = zone != null ? zone.id : subZone!.id;
        circuitZoneFunction = getZoneFunction(zoneOrSubZoneId: parentId);
      }

      List<DroSourceConnection> droSourceConnections = [];

      if (zone != null) {
        droSourceConnections.add(
          DroSourceConnection(
            sourceChainId: getZoneProcessingId(zone.id),
            sourceTerminal: "out",
            sourceChannel: 1,
            destinationTerminal: "in",
            destinationChannel: 1,
          ),
        );
      } else if (subZone != null) {
        droSourceConnections.add(
          DroSourceConnection(
            sourceChainId: getZoneProcessingId(subZone.id), //get parent subzone control id to connect to
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
          ioProperties: IoProperties(
            channels: 1,
          ),
          sourceChannels: 1,
          algorithm: circuitZoneFunction != null ? circuitZoneFunction.algorithmName : "",
          algorithmProperties: {
            "source_channels": 1,
          },
          algorithmTerminals: DroAlgorithmTerminals(
            inTerminal: 1,
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
        deviceLocation: getEquipLocationForHardware(dsp.id)?.name,
      );
      droMaxDevices.add(droMaxDevice);

      List<WiringConnectionModel> wiringConnections = getConnectionForDevice(dsp.id) ?? [];
      for (WiringConnectionModel connection in wiringConnections) {
        List<PortData> inputPorts = dsp.inputPortsData;
        List<PortData> outPutPorts = dsp.outputPortsData;
        List<PortData> comPorts = dsp.communicationPorts;
        //check if the connection port id is in the input ports of the dsp
        bool isInputConnect = (inputPorts.any((port) => port.id == connection.portId));
        if (isInputConnect) {
          PortData portData = inputPorts.firstWhere((port) => port.id == connection.portId);
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

  String getControlId(String parentId) {
    return "control_$parentId";
  }

  String getZoneProcessingId(String parentId) {
    return "processing_$parentId";
  }
}
