import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';

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
      if (hardware is Source) {
        final SourceType spurceType = (hardware).type;
        final List<String> chain = switch (spurceType) {
          SourceType.mic => <String>['peq', 'gate', 'compressor', 'agc'],
          SourceType.media => <String>['peq', 'compressor', 'agc'],
          SourceType.generic => <String>['peq', 'compressor'],
          SourceType.paging => <String>['peq', 'compressor'],
        };
        for (final String algo in chain) {
          addProcessingBlockToSource(
            processingBlock:
                ProcessingBlockModel.sourceBlocks
                    .firstWhere(
                      (ProcessingBlockModel element) => element.algorithmId == algo,
                    )
                    .clone(),
            sourceId: hardware.id,
            autoSave: false,
          );
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

  void removeAllSpeakersFromCurrentListeningArea({bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      final List<HardwareComponent> all = <HardwareComponent>[...getPlacedSpeakersForCurrentListeningArea(), ...getNonPlacedSpeakersForCurrentListeningArea()];
      for (final HardwareComponent hw in all.whereType<Speaker>()) {
        projectManager.removeHardware(hw.id);
      }
      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to remove all speakers from listening area: $e",
      );
    }
  }

  void migrateAllSpeakersTo({required Speaker speaker, required String targetListeningAreaId, bool autoSave = true}) {
    try {
      if (autoSave) {
        recordSnapshot();
      }
      projectManager.migrateAllSpeakersTo(speaker: speaker, targetListeningAreaId: targetListeningAreaId);

      if (autoSave) {
        saveProject();
      }
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to migrate all speakers to: $e",
      );
      throwError("Failed to migrate all speakers to: $e");
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

  List<HardwareComponent> getHardwareInFloorWithPosition({
    required String floorId,
  }) {
    try {
      return projectManager.getAllHardwareInFloorWithPosition(floorId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get hardware with position for floor: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getHardwareInFloorWithoutPosition({
    required String floorId,
  }) {
    try {
      return projectManager.getAllHardwareInFloorWithoutPosition(floorId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get hardware without position for floor: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getAllPlacedHardwareInListeningArea({
    required String listeningAreaId,
  }) {
    try {
      return projectManager.getAllHardwareInListeningAreaWithPosition(listeningAreaId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get placed hardware for listening area: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<HardwareComponent> getAllNonPlacedHardwareInListeningArea({
    required String listeningAreaId,
  }) {
    try {
      return projectManager.getAllHardwareInListeningAreaWithoutPosition(listeningAreaId);
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get unplaced hardware for listening area: $e",
      );
      return <HardwareComponent>[];
    }
  }

  List<Speaker> getNonPlacedSpeakersForCurrentListeningArea() {
    try {
      final String? listeningAreaId = currentSelectedListeningAreaId;
      if (listeningAreaId == null) throw Exception("No listening area selected");
      final List<HardwareComponent> hardwares = projectManager.getAllHardwareInListeningAreaWithoutPosition(listeningAreaId);
      return hardwares.whereType<Speaker>().toList();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get unplaced hardware for listening area: $e",
      );
      return <Speaker>[];
    }
  }

  List<Speaker> getPlacedSpeakersForCurrentListeningArea() {
    try {
      final String? listeningAreaId = currentSelectedListeningAreaId;
      if (listeningAreaId == null) throw Exception("No listening area selected");
      final List<HardwareComponent> hardwares = projectManager.getAllHardwareInListeningAreaWithPosition(listeningAreaId);
      return hardwares.whereType<Speaker>().toList();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: "Failed to get placed hardware for listening area: $e",
      );
      return <Speaker>[];
    }
  }

  ResponseCallback<bool> runAutoPlacementForCurrentListeningArea({required AutoPlacementResult autoPlacementResult}) {
    try {
      final String? listeningAreaId = currentSelectedListeningAreaId;
      if (listeningAreaId == null) return ResponseCallback<bool>.failure('Select a listening area first.');

      final ListeningArea listeningArea = getListeningArea(areaId: listeningAreaId);
      if (!listeningArea.autoPlacement) return ResponseCallback<bool>.failure('Enable Auto-Placement and try again.');
      if (listeningArea.vertices.length < 3) return ResponseCallback<bool>.failure('Listening area shape is invalid. Redraw the area and try again.');

      final ProductQueryViewModel productQueryViewModel = serviceLocator<ProductQueryViewModel>();
      final List<SpeakerProduct> catalogSpeakers = productQueryViewModel.speakers;

      final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakersForCurrentListeningArea();
      final List<Speaker> placedSpeakers = getPlacedSpeakersForCurrentListeningArea();
      final List<Speaker> allSpeakers = <Speaker>[...placedSpeakers, ...nonPlacedSpeakers];

      final List<Speaker> targetSpeakers =
          allSpeakers.where((Speaker speaker) {
            final int? productId = speaker.productId;
            if (productId == null) return true;
            final SpeakerProduct? product = catalogSpeakers.where((SpeakerProduct p) => p.productId == productId).firstOrNull;
            return !(product?.isSubwoofer ?? false);
          }).toList();

      if (targetSpeakers.isEmpty) return ResponseCallback<bool>.failure('Add at least one non-subwoofer speaker to auto-place.');

      final ({List<Offset> positions, SurfacePlacementResult? surfacePlacementResult, PlacementResult? placementResult}) autoPlacedDetails =
          _calculateAutoPlacedPositions(
            listeningArea: listeningArea,
            catalogSpeakers: catalogSpeakers,
            targetSpeakers: targetSpeakers,
            autoPlacementResult: autoPlacementResult,
          );

      final List<Offset> candidatePoints = autoPlacedDetails.positions;
      final SurfacePlacementResult? surfacePlacementResult = autoPlacedDetails.surfacePlacementResult;
      final PlacementResult? placementResult = autoPlacedDetails.placementResult;

      if (candidatePoints.isEmpty) {
        FusionLogger.log(tag: LogTag.project, message: 'Auto-placement candidate points: $candidatePoints');
        return ResponseCallback<bool>.failure('No valid placement positions found. Adjust your listening area shape or auto-placement settings and try again.');
      }

      final Offset center = listeningArea.getCenterPositionOfVertices() ?? candidatePoints.first;
      final List<Offset> sortedPoints = List<Offset>.from(candidatePoints)
        ..sort((Offset a, Offset b) => (a - center).distance.compareTo((b - center).distance));

      final int algorithmCount = sortedPoints.length;

      recordSnapshot();

      // Save auto-placement result to listening area for future reference and to display in UI if needed.
      final ListeningArea updatedListeningArea = listeningArea.copyWith(
        autoPlacementResult: autoPlacementResult.copyWith(
          ceilingPendantPlacementResult: placementResult,
          surfacePlacementResult: surfacePlacementResult,
        ),
      );
      updateListeningArea(area: updatedListeningArea, autoSave: false);

      final Speaker templateSpeaker = targetSpeakers.first;

      // Hard reset speaker inventory in current LA: remove all existing placed + unplaced speakers.
      removeAllSpeakersFromCurrentListeningArea(autoSave: false);

      // Add a fresh set of algorithm-placed speakers only.
      final int placeCount = algorithmCount;
      for (int i = 0; i < placeCount; i++) {
        final Speaker clonedSpeaker = templateSpeaker.getClone().copyWith(
          pitch: listeningArea.mountingType == MountingType.pendant || listeningArea.mountingType == MountingType.ceiling ? 90.0 : 0.0,
        );
        clonedSpeaker.pos = sortedPoints[i];
        addHardware(hardware: clonedSpeaker, autoSave: false);
      }

      saveProject();
      updateProject();

      return ResponseCallback<bool>.success(true, message: 'Auto-placement successful. Placed $placeCount speakers.');
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Auto-placement failed: $e');
      return ResponseCallback<bool>.failure(e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  ({List<Offset> positions, SurfacePlacementResult? surfacePlacementResult, PlacementResult? placementResult}) _calculateAutoPlacedPositions({
    required ListeningArea listeningArea,
    required List<SpeakerProduct> catalogSpeakers,
    required List<Speaker> targetSpeakers,
    required AutoPlacementResult autoPlacementResult,
  }) {
    // take mounting type from listening area if set, else from first speaker (they should all be the same since we filter by productId before)
    final MountingType mountingType = listeningArea.mountingType;

    final Speaker referenceSpeaker = targetSpeakers.first;

    final SpeakerProduct? speakerProduct = catalogSpeakers.where((SpeakerProduct p) => p.productId == referenceSpeaker.productId).firstOrNull;
    final double coverageAngle = _resolveCoverageAngle(speakerProduct);

    final ListeningAreaRoomBounds bounds = listeningArea.getBoundsForVertices();
    final double roomLength = bounds.roomLengthInMeters;
    final double roomWidth = bounds.roomWidthInMeters;

    if (roomLength <= 0 || roomWidth <= 0) {
      throw ArgumentError('Invalid room dimensions calculated from listening area vertices. Length and width must be greater than 0.');
    }
    final double listenerHeight = listeningArea.listeningHeight;

    if (listenerHeight <= 0) throw ArgumentError('Listener height must be greater than 0.');

    final double? parsedCeilingHeight = double.tryParse(listeningArea.ceilingHeight);
    if (parsedCeilingHeight == null) throw ArgumentError('Ceiling height is required and must be a valid number.');
    if (parsedCeilingHeight <= listenerHeight) throw ArgumentError('Ceiling height must be greater than listener height.');

    final double ceilingHeight = parsedCeilingHeight;

    // final double boundaryThreshold = autoPlacementResult.autoPlaceBoundaryThreshold;
    // if (boundaryThreshold < 0.3 || boundaryThreshold >= 1) throw ArgumentError('Boundary threshold must be between 0.3 and 1.');

    if (mountingType == MountingType.ceiling || mountingType == MountingType.pendant) {
      final List<Point2D> geometry = <Point2D>[
        ...listeningArea.vertices.map(
          (FusionCanvasPoint point) {
            return Point2D(
              (point.position.dx - bounds.minX) / 100,
              (point.position.dy - bounds.minY) / 100,
            );
          },
        ),
      ];

      final Room room = Room.asymmetrical(geometry: geometry, ceilingHeight: ceilingHeight, listenerHeight: listenerHeight);

      final SpeakerType speakerType = mountingType == MountingType.pendant ? SpeakerType.pendant : SpeakerType.ceiling;

      final PlacementResult result = AutoSpeakerPlacement.calculatePlacement(
        room: room,
        speakerSpec: SpeakerSpec(
          coverageAngle: coverageAngle,
          type: speakerType,
          // TODO: SHARATH - need to verify if zAxis is the right dimension to use for pendant height in the algorithm, and if the algorithm expects it to be in mm or meters (we may need to convert from our internal cm representation)
          pendantHeight: 2.1,
        ),
        coveragePreference: autoPlacementResult.autoPlaceCoveragePreference,
        layoutPattern: autoPlacementResult.autoPlaceLayoutPattern,
        // customOriginOffset: Point2D(autoPlacementResult.autoPlaceGridOffsetX, autoPlacementResult.autoPlaceGridOffsetY),
        // boundaryOverlapThreshold: boundaryThreshold,
      );

      log("Total speakers placed by algorithm: ${result.speakerPositions.length}");
      final List<Offset> positions = result.speakerPositions.map((Point2D p) => Offset((p.x * 100) + bounds.minX, (p.y * 100) + bounds.minY)).toList();

      return (positions: positions, surfacePlacementResult: null, placementResult: result);
    } else {
      final SurfacePlacementResult result = SurfaceSpeakerPlacer.calculatePlacement(
        room: SurfaceRoom(
          length: roomLength,
          width: roomWidth,
          ceilingHeight: ceilingHeight,
          listenerHeight: listenerHeight,
        ),
        speaker: Loudspeaker(horizontalCoverageAngle: coverageAngle, type: referenceSpeaker.speakerSKU),
        config: PlacementConfig(
          coveragePreference: autoPlacementResult.autoPlaceCoveragePreference,
        ),
      );

      final List<Offset> positions = <Offset>[
        ...result.positions.map(
          (SpeakerPosition p) {
            return Offset(
              (p.x * 100) + bounds.minX,
              (p.y * 100) + bounds.minY,
            );
          },
        ),
      ];
      return (positions: positions, surfacePlacementResult: result, placementResult: null);
    }
  }

  double _resolveCoverageAngle(SpeakerProduct? product) {
    if (product == null || product.coverage.isEmpty) return 90.0;
    final int angle = product.coverage.firstOrNull?.horizontalDeg ?? 90;
    return angle <= 0 ? 90.0 : angle.toDouble();
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

  void placeSelectedSpeaker({required Offset position, bool autoSave = true, required bool isFromBuildingPage}) {
    try {
      if (autoSave) recordSnapshot();

      final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakersForCurrentListeningArea();
      if (nonPlacedSpeakers.isEmpty) return;
      final Speaker updatedSpeaker = nonPlacedSpeakers.first.copyWith(pos: position);
      updateHardware(hardware: updatedSpeaker);

      if (nonPlacedSpeakers.length == 1) {
        // Last speaker placed
        // setShouldPlaceNonPlacedSpeakers(false);
        updateProject();
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add selected product as hardware: $e");
      // setShouldPlaceNonPlacedSpeakers(false);
    }
  }

  void addSelectedProduct({
    required Offset position,
    String? listeningAreaId,
    bool autoSave = true,
    required bool isFromBuildingPage,
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
        isFromBuildingPage: isFromBuildingPage,
      );
      addHardware(hardware: newHardware, autoSave: false);

      // if (newHardware is Speaker) {
      //   final CircuitModel circuitModel = CircuitModel(name: newHardware.name, speakerSKU: (newHardware).speakerSKU);
      //   addCircuit(circuit: circuitModel, autoSave: false);
      //   addHardwareToCircuit(hwId: newHardware.id, circuitId: circuitModel.id);
      //
      //   if (listeningAreaId != null) {
      //     final SubZone? subZone = getSubZoneForListeningArea(areaId: listeningAreaId);
      //     if (subZone != null) {
      //       addCircuitToSubZone(subZoneId: subZone.id, circuitId: circuitModel.id);
      //     }
      //
      //     final Zone? zone = getZonesForListeningArea(areaId: listeningAreaId);
      //     if (zone != null) {
      //       addCircuitToZone(zoneId: zone.id, circuitId: circuitModel.id);
      //     }
      //   }
      // }

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

  Speaker fromSpeakerProductModel(String assetImagePath, SpeakerProduct product, LocationModel locationEntity, bool isFromBuildingPage) {
    final MountingType? mountingType = MountingType.fromJson(product.mountType);
    return Speaker(
      locationEntity: locationEntity,
      name: product.modelName,
      productId: product.productId,
      pos: null,
      zAxis: 300.0,
      speakerSKU: product.modelName,
      gain: 0.0,
      addedFromBuildingPage: isFromBuildingPage,
      assetImagePath: assetImagePath,
      type: OutputType.analogOutput,
      price: 0,
      mountingType: mountingType,
      pitch: mountingType == MountingType.pendant || mountingType == MountingType.ceiling ? 90.0 : 0.0,
      inputPortsData: <PortData>[
        PortData(
          name: "In",
          position: PortPosition.bottomRight,
          portNumber: 1,
          compatibleTypes: <PortType>[PortType.amplifierOutput],
          type: PortType.speakerInput,
          description: PortType.speakerInput.description,
        ),
      ],
      outputPortsData: <PortData>[],
    );
  }

  HardwareComponent fromProductQueryModel(ProductQueryModel product, {Offset? pos, required LocationModel locationEntity, required bool isFromBuildingPage}) {
    final ListeningArea? listeningArea = (locationEntity.listeningAreaId != null) ? getListeningArea(areaId: locationEntity.listeningAreaId!) : null;
    switch (product.type) {
      case ProductType.speaker:
        return Speaker(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          zAxis: 300.0,
          speakerSKU: product.sku,
          gain: 0.0,
          addedFromBuildingPage: isFromBuildingPage,
          assetImagePath: product.image,
          type: OutputType.analogOutput,
          price: product.price,
          pitch: product.mountingType == "pendant" || product.mountingType == "ceiling" ? 90.0 : 0.0,
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
          SourceConnectionType.audioJack => PortType.audioJackOutput,
          SourceConnectionType.xlr => PortType.xlrOutput,
          SourceConnectionType.hdmi => PortType.hdmiOut,
        };
        return Source(
          locationEntity: locationEntity,
          name: product.name,
          pos: pos,
          assetImagePath: product.image,
          sku: product.sku,
          price: product.price,
          addedFromBuildingPage: isFromBuildingPage,
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
                SourceConnectionType.audioJack => <PortType>[PortType.audioJackInput],
                SourceConnectionType.xlr => <PortType>[PortType.xlrInput],
                SourceConnectionType.hdmi => <PortType>[PortType.hdmiIn],
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
          addedFromBuildingPage: isFromBuildingPage,
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
          pos: listeningArea?.getCenterPositionOfVertices(),
          assetImagePath: product.image,
          sku: product.sku,
          addedFromBuildingPage: isFromBuildingPage,
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
          addedFromBuildingPage: isFromBuildingPage,
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
          addedFromBuildingPage: isFromBuildingPage,
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
          addedFromBuildingPage: isFromBuildingPage,
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

  //todo: patch work, refine later
  String? getHardwareImage({required int productId, required String currentImagePath}) {
    try {
      if (File(currentImagePath).existsSync()) {
        return currentImagePath;
      }
      final List<SpeakerProduct> speaker = serviceLocator<ProductQueryViewModel>().speakers;
      final SpeakerProduct hardware = speaker.firstWhere((SpeakerProduct element) => element.productId == productId);
      return serviceLocator<ProductQueryViewModel>().getImagePath(hardware.assets.assets.values.first.first);
    } catch (e) {
      return null;
    }
  }
}
