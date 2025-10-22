import 'dart:ui';

import 'package:flutter/material.dart';
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

  void updateHardware({required HardwareComponent hardware, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final HardwareComponent oldHw = projectManager.getHardwareById(hardware.id);
      if (oldHw != hardware) {
        projectManager.updateHardware(hardware);
        if (autoSave) {
          saveProject();
        }
        updateProject();
      } else {
        FusionLogger.log(tag: LogTag.project, message: "No changes detected for hardware: ${hardware.id}, skipping update.");
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to update hardware: $e");
      throwError("Failed to update hardware: $e");
    }
  }

  void addHardware({required HardwareComponent hardware, int count = 1, bool autoSave = true}) {
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
      FusionLogger.log(tag: LogTag.project, message: "Failed to add hardware: $e");
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
      FusionLogger.log(tag: LogTag.project, message: "Failed to remove hardware: $e");
    }
  }

  List<HardwareComponent> getAllHardware() {
    try {
      return projectManager.getAllHardwareComponents();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get all hardware: $e");
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForListeningArea({required String listeningAreaId}) {
    try {
      return projectManager.getHardwareForListeningArea(listeningAreaId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for listening area: $e");
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareForFloor({required String floorId}) {
    try {
      return projectManager.getHardwareForFloor(floorId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get hardware for floor: $e");
      return <HardwareComponent>[];
    }
  }

  ResponseCallback<bool> moveHardware({required String hardwareId, String? listeningAreaId, String? floorId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final ResponseCallback<bool> responseCallback = projectManager.moveHardware(hardwareId, listeningAreaId: listeningAreaId, floorId: floorId);
      if (autoSave) {
        saveProject();
      }
      updateProject();
      return responseCallback;
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to move hardware: $e");
      return ResponseCallback<bool>.failure("Failed to move hardware: $e");
    }
  }

  List<HardwareComponent> getSpeakersInZone({required String zoneId}) {
    try {
      return projectManager.getHardwareInZone(zoneId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get speakers for zone: $e");
      return <HardwareComponent>[];
    }
  }

  // get zone for hardware
  Zone? getZoneForHardware({required String hardwareId}) {
    try {
      return projectManager.getZoneForHardware(hardwareId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get zone for hardware: $e");
      return null;
    }
  }

  // get CircuitModel for hardware
  CircuitModel? getCircuitForHardware({required String hardwareId}) {
    try {
      return projectManager.getCircuitForHardware(hardwareId);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to get circuit for hardware: $e");
      return null;
    }
  }

  //add hardware and create circuit
  void addHardwareAndCreateCircuit({required HardwareComponent hw, required String circuitId, bool autoSave = true}) {
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
      FusionLogger.log(tag: LogTag.project, message: "Failed to add hardware and create circuit: $e");
    }
  }

  // Update hardware location
  void updateHardwareLocation({required String hardwareId, required LocationModel newLocation, bool autoSave = true}) {
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
      FusionLogger.log(tag: LogTag.project, message: "Failed to update hardware location: $e");
      throwError("Failed to update hardware location: $e");
    }
  }

  void reOrderHardware({required String hardwareIdToMove, required String hardwareAtNewIndex, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.reOrderHardware(hardwareIdToMove: hardwareIdToMove, hardwareAtNewIndex: hardwareAtNewIndex);
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to reorder hardware: $e");
      throwError("Failed to reorder hardware: $e");
    }
  }

  void addSelectedProduct({required Offset position, String? listeningAreaId, bool autoSave = true}) {
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
      addHardware(hardware: newHardware, autoSave: autoSave);

      // Clear selected product after adding
      clearSelectedProduct();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add selected product as hardware: $e");
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
            ),
          ],
          outputPortsData: <PortData>[],
        );
      case ProductType.sources:
        return Source(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          hardwareName: product.name,
          type: SourceType.analogInput,
          inputPortsData: <PortData>[],
          outputPortsData: <PortData>[
            PortData(
              name: "Out",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.dspAnalogInput],
              type: PortType.analogOutput,
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
            inputPortType: PortType.analogInput,
            outputPortType: PortType.analogOutput,
            compatibleInputTypes: <PortType>[PortType.analogInput, PortType.digitalInput],
            compatibleOutputTypes: <PortType>[PortType.analogOutput, PortType.digitalOutput],
            portPosition: PortPosition.topLeft,
          ),
          communicationPorts: <PortData>[],
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
            PortData(
              name: "In",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.analogInput, PortType.ble],
              type: PortType.analogInput,
            ),
            PortData(
              name: "In",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.analogInput, PortType.ble],
              type: PortType.analogInput,
            ),
          ],
          outputPortsData: <PortData>[
            PortData(
              name: "Out",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.dspAnalogInput],
              type: PortType.analogOutput,
            ),
            PortData(
              name: "Out",
              position: PortPosition.bottomRight,
              portNumber: 1,
              compatibleTypes: <PortType>[PortType.dspAnalogInput],
              type: PortType.analogOutput,
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
            inputPortType: PortType.analogInput,
            outputPortType: PortType.analogOutput,
            compatibleInputTypes: <PortType>[PortType.analogInput, PortType.digitalInput],
            compatibleOutputTypes: <PortType>[PortType.analogOutput, PortType.digitalOutput],
            portPosition: PortPosition.topLeft,
          ),
          communicationPorts: <PortData>[
            PortData(name: 'Wifi', position: PortPosition.footerRight, portNumber: 1, type: PortType.wifi, compatibleTypes: <PortType>[PortType.wifi]),
            PortData(name: 'USB', position: PortPosition.footerRight, portNumber: 2, type: PortType.usb, compatibleTypes: <PortType>[PortType.usb]),
            PortData(name: 'ble', position: PortPosition.footerRight, portNumber: 3, type: PortType.ble, compatibleTypes: <PortType>[PortType.ble]),
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
