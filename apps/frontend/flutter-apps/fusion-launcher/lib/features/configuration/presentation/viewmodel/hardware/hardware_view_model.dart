import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

extension HardwareViewModel on ProjectViewModel {
  //get Hardware by id
  HardwareComponent? getHardware({required String hardwareId}) {
    try {
      return projectManager.getHardwareById(hardwareId);
    } catch (e) {
      return null;
    }
  }

  void updateHardware({
    required HardwareComponent hardware,
    bool autoSave = true,
  }) {
    print(
      "Updating hardware: ${hardware.id}, pos: ${hardware.pos}, location: ${hardware.locationEntity.listeningAreaId}",
    );
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final HardwareComponent oldHw = projectManager.getHardwareById(
        hardware.id,
      );
      if (oldHw != hardware) {
        projectManager.updateHardware(hardware);
        if (autoSave) {
          saveProject();
        }
        updateProject();
      } else {
        FusionLogger.log(
          tag: LogTag.project,
          message: "No changes detected for hardware: ${hardware.id}, skipping update.",
        );
      }
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to update hardware: $e",
      );
      throwError("Failed to update hardware: $e");
    }
  }

  void addHardware({
    required HardwareComponent hardware,
    int count = 1,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addHardware(hardware);
      if (hardware is Speaker) {
        for (int i = 1; i < count; i++) {
          projectManager.addHardware(hardware.getClone());
        }
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to add hardware: $e",
      );
    }
  }

  void removeHardware({required String hardwareId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.removeHardware(hardwareId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to remove hardware: $e",
      );
    }
  }

  List<HardwareComponent> getAllHardware() {
    try {
      return projectManager.getAllHardwareComponents();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get all hardware: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForListeningArea({
    required String listeningAreaId,
  }) {
    try {
      return projectManager.getHardwareForListeningArea(listeningAreaId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get hardware for listening area: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForFloor({required String floorId}) {
    try {
      return projectManager.getHardwareForFloor(floorId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get hardware for floor: $e",
      );
      return <HardwareComponent>[];
    }
  }

  ResponseCallback<bool> moveHardware({
    required String hardwareId,
    String? listeningAreaId,
    String? floorId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final ResponseCallback<bool> responseCallback = projectManager.moveHardware(
        hardwareId,
        listeningAreaId: listeningAreaId,
        floorId: floorId,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
      return responseCallback;
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to move hardware: $e",
      );
      return ResponseCallback<bool>.failure("Failed to move hardware: $e");
    }
  }

  // get zone for hardware
  Zone? getZoneForHardware({required String hardwareId}) {
    try {
      return projectManager.getZoneForHardware(hardwareId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get zone for hardware: $e",
      );
      return null;
    }
  }

  // get zone for hardware
  SubZone? getSubZoneForHardware({required String hardwareId}) {
    try {
      return projectManager.getSubZoneForHardware(hardwareId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get subzone for hardware: $e",
      );
      return null;
    }
  }

  // get CircuitModel for hardware
  CircuitModel? getCircuitForHardware({required String hardwareId}) {
    try {
      return projectManager.getCircuitForHardware(hardwareId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get circuit for hardware: $e",
      );
      return null;
    }
  }

  //add hardware and create circuit
  void addHardwareAndCreateCircuit({
    required HardwareComponent hw,
    required String circuitId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.addHardwareAndCreateCircuit(hw, circuitId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to add hardware and create circuit: $e",
      );
    }
  }

  // Update hardware location
  void updateHardwareLocation({
    required String hardwareId,
    required LocationModel newLocation,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.updateHardwareLocation(hardwareId, newLocation);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to update hardware location: $e",
      );
      throwError("Failed to update hardware location: $e");
    }
  }

  void reOrderHardware({
    required String hardwareIdToMove,
    required String hardwareAtNewIndex,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderHardware(
        hardwareIdToMove: hardwareIdToMove,
        hardwareAtNewIndex: hardwareAtNewIndex,
      );
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to reorder hardware: $e",
      );
      throwError("Failed to reorder hardware: $e");
    }
  }

  void addSelectedProduct({
    required Offset position,
    String? listeningAreaId,
    bool autoSave = true,
  }) {
    if (selectedProductToAdd == null) return;
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final HardwareComponent newHardware = fromProductQueryModel(
        selectedProductToAdd!,
        pos: position,
        locationEntity: LocationModel(
          floorId: currentFloor.id,
          listeningAreaId: listeningAreaId,
        ),
      );
      addHardware(hardware: newHardware, autoSave: false);

      if (newHardware is Speaker) {
        final CircuitModel circuitModel = CircuitModel(name: newHardware.name, speakerSKU: (newHardware).speakerSKU);
        addCircuit(circuit: circuitModel, autoSave: false);
        addHardwareToCircuit(hwId: newHardware.id, circuitId: circuitModel.id);

        if (listeningAreaId != null) {
          final SubZone? subZone = getSubZoneForListeningArea(areaId: listeningAreaId);
          if (subZone != null) {
            addCircuitToSubZone(subZoneId: subZone.id, circuitId: circuitModel.id);
          }

          final Zone? zone = getZonesForListeningArea(areaId: listeningAreaId);
          if (zone != null) {
            addCircuitToZone(zoneId: zone.id, circuitId: circuitModel.id);
          }
        }
      }

      // final SubZone? subZone = getZonesForListeningArea(hardwareId: newHardware.id);
      // if(subZone == null){
      //   final Zone? zone = getZoneForHardware(hardwareId: newHardware.id);
      //   if(zone != null){
      //     addCircuitToZone(zoneId: zone.id, circuitId: circuitModel.id);
      //   }
      // }else{
      //   addCircuitToSubZone(subZoneId: subZone.id, circuitId: circuitModel.id);
      // }

      // Clear selected product after adding
      clearSelectedProduct();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to add selected product as hardware: $e",
      );
      clearSelectedProduct();
    }
  }

  HardwareComponent fromProductQueryModel(
    ProductQueryModel product, {
    required Offset pos,
    required LocationModel locationEntity,
  }) {
    switch (product.type) {
      case ProductType.speaker:
        return Speaker(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          zAxis: 300.0,
          // 200 cm default height
          speakerSKU: product.sku,
          gain: 20.0,
          assetImagePath: product.image,
          type: OutputType.analogOutput,
          price: product.price,
          pitch: product.mountingType == "pendant" ? 90.0 : 0.0,
          inputPortsData: <PortData>[
            PortData(
              name: "In",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.amplifierOutput],
              type: PortType.analogInput,
              description: PortType.analogInput.description,
            ),
          ],
          outputPortsData: <PortData>[],
        );
      case ProductType.sources:
        final SourceConnectionType connectionType = SourceData.getSourceConnectionType(product.sku);
        final SourceType type = SourceData.getSourceType(product.sku);
        final PortType portType = switch (connectionType) {
          SourceConnectionType.analogInput || SourceConnectionType.aes67input => PortType.analogOutput,
          SourceConnectionType.bluetooth => PortType.bleOut,
          SourceConnectionType.usb => PortType.usbOut,
        };
        return Source(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          connectionType: connectionType,
          type: type,
          inputPortsData: <PortData>[],
          outputPortsData: <PortData>[
            PortData(
              name: "1",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: switch (connectionType) {
                SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
                  PortType.dspAnalogInput,
                  PortType.endpointInput,
                ],
                SourceConnectionType.bluetooth => <PortType>[
                  PortType.bleIn,
                ],
                SourceConnectionType.usb => <PortType>[PortType.usbIn],
              },
              type: portType,
              description: portType.description,
            ),
          ],
        );
      case ProductType.amplifier:
        return Amplifier(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          portData: HardwarePortData(
            inputPorts: 5,
            outputPorts: 5,
            inputPortType: PortType.amplifierInput,
            outputPortType: PortType.amplifierOutput,
            compatibleInputTypes: <PortType>[
              PortType.dspAnalogOutput,
            ],
            compatibleOutputTypes: <PortType>[
              PortType.circuitInput,
            ],
            portPosition: PortPosition.topLeft,
          ),
          communicationPorts: <PortData>[
            PortData(
              name: 'ethernet',
              position: PortPosition.footerRight,
              portNumber: 3,
              type: PortType.networkSwitchOut,
              description: PortType.ethernet.description,
              compatibleTypes: <PortType>[PortType.networkSwitchIn],
            ),
          ],
          powerPerChannel: 100.0,
          color: Colors.blue,
          channels: 5,
        );
      case ProductType.controllers:
        return FusionController(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          inputPortsData: <PortData>[
            // PortData(
            //   name: "In",
            //   position: PortPosition.bottomRight,
            //   portNumber: 1,
            //   compatibleTypes: <PortType>[PortType.analogInput, PortType.ble],
            //   type: PortType.analogInput,
            //   description: PortType.analogInput.description,
            // ),
            // PortData(
            //   name: "In",
            //   position: PortPosition.bottomRight,
            //   portNumber: 1,
            //   compatibleTypes: <PortType>[PortType.analogInput, PortType.ble],
            //   type: PortType.analogInput,
            //   description: PortType.analogInput.description,
            // ),
          ],
          outputPortsData: <PortData>[
            // PortData(
            //   name: "Out",
            //   position: PortPosition.bottomRight,
            //   portNumber: 1,
            //   compatibleTypes: <PortType>[PortType.dspAnalogInput],
            //   type: PortType.analogOutput,
            //   description: PortType.analogOutput.description,
            // ),
            // PortData(
            //   name: "Out",
            //   position: PortPosition.bottomRight,
            //   portNumber: 1,
            //   compatibleTypes: <PortType>[PortType.dspAnalogInput],
            //   type: PortType.analogOutput,
            //   description: PortType.analogOutput.description,
            // ),
          ],
          communicationPorts: <PortData>[
            PortData(
              name: 'ethernet',
              position: PortPosition.footerCenter,
              portNumber: 3,
              type: PortType.networkSwitchOut,
              description: PortType.networkSwitchOut.description,
              compatibleTypes: <PortType>[PortType.networkSwitchIn],
            ),
          ],
        );
      case ProductType.dsps:
        return FusionDsp(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          portData: HardwarePortData(
            inputPorts: 5,
            outputPorts: 5,
            inputPortType: PortType.dspAnalogInput,
            outputPortType: PortType.dspAnalogOutput,
            compatibleInputTypes: <PortType>[
              PortType.analogOutput,
            ],
            compatibleOutputTypes: <PortType>[
              PortType.amplifierInput,
            ],
            portPosition: PortPosition.topLeft,
          ),
          communicationPorts: <PortData>[
            PortData(
              name: 'Wifi',
              position: PortPosition.footerRight,
              portNumber: 1,
              type: PortType.wifiIn,
              description: PortType.wifiIn.description,
              compatibleTypes: <PortType>[PortType.wifiOut],
            ),
            PortData(
              name: 'USB',
              position: PortPosition.footerRight,
              portNumber: 2,
              type: PortType.usbIn,
              description: PortType.usbIn.description,
              compatibleTypes: <PortType>[PortType.usbOut],
            ),
            PortData(
              name: 'ble',
              position: PortPosition.footerRight,
              portNumber: 3,
              type: PortType.bleIn,
              description: PortType.bleIn.description,
              compatibleTypes: <PortType>[PortType.bleOut],
            ),
          ],
          location: '',
          status: FusionDeviceSetupStatus.notStarted,
        );

      case ProductType.endpoints:
        return FusionEndpoints(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          ipAddress: '',
          inputPortsData: <PortData>[
            PortData(
              name: "In",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.analogOutput],
              type: PortType.endpointInput,
              description: PortType.endpointInput.description,
            ),
          ],
          communicationPorts: <PortData>[
            PortData(
              name: 'ethernet',
              position: PortPosition.footerRight,
              portNumber: 3,
              type: PortType.networkSwitchOut,
              description: PortType.ethernet.description,
              compatibleTypes: <PortType>[PortType.networkSwitchIn],
            ),
          ],
        );
      case ProductType.racks:
        return HardwareRack(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          price: product.price,
          hardwareName: product.name,
        );
      // Add network switch to product type and uncomment this
      // case ProductType.networkSwitches:
      //   return NetworkSwitch(
      //     locationEntity: locationEntity,
      //     name: product.name,
      //     pos: pos,
      //     assetImagePath: product.image,
      //     price: product.price,
      //     hardwareName: product.name,
      //   );
    }
  }
}
