import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/view_model/product_query_view_model.dart';
import 'package:fusion_lib/fusion_algorithms/ceiling_pendant_speakers_autolayout/ceiling_pendant_speakers_autolayout.dart' as ceiling_algo;
import 'package:fusion_lib/fusion_algorithms/surface_speakers_autolayout/surface_speakers_autolayout.dart' as surface_algo;
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
            processingBlock: ProcessingBlockModel.sourceBlocks.firstWhere(
              (ProcessingBlockModel element) => element.algorithmId == algo,
            ),
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
        message: "Failed to get unplaced hardware for listening area: $e",
      );
      return <Speaker>[];
    }
  }

  ResponseCallback<bool> runAutoPlacementForCurrentListeningArea({required AutoPlacementResult autoPlacementResult}) {
    try {
      final String? listeningAreaId = currentSelectedListeningAreaId;
      if (listeningAreaId == null) {
        return ResponseCallback<bool>.failure('Select a listening area first.');
      }

      final ListeningArea listeningArea = getListeningArea(areaId: listeningAreaId);
      if (!listeningArea.autoPlacement) {
        return ResponseCallback<bool>.failure('Enable Auto-Placement and try again.');
      }

      if (listeningArea.vertices.length < 3) {
        return ResponseCallback<bool>.failure('Listening area shape is invalid. Redraw the area and try again.');
      }

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

      final List<Offset> candidatePoints = _calculateAutoPlacedPositions(
        listeningArea: listeningArea,
        catalogSpeakers: catalogSpeakers,
        targetSpeakers: targetSpeakers,
        autoPlacementResult: autoPlacementResult,
      );

      if (candidatePoints.isEmpty) {
        return ResponseCallback<bool>.failure(
          'No valid speaker positions found. Check ceiling/listener heights and try reducing spacing or boundary threshold.',
        );
      }

      final Offset center = listeningArea.getCenterPositionOfVertices() ?? candidatePoints.first;
      final List<Offset> sortedPoints = List<Offset>.from(candidatePoints)
        ..sort((Offset a, Offset b) => (a - center).distance.compareTo((b - center).distance));

      final int algorithmCount = sortedPoints.length;

      recordSnapshot();

      final ListeningArea updatedListeningArea = listeningArea.copyWith(autoPlacementResult: autoPlacementResult);
      updateListeningArea(area: updatedListeningArea, autoSave: false);

      // Expand speaker list to match algorithm quantity so placed count reflects algorithm output.
      if (targetSpeakers.length < algorithmCount) {
        final Speaker templateSpeaker = targetSpeakers.first;
        for (int i = targetSpeakers.length; i < algorithmCount; i++) {
          final Speaker clonedSpeaker = templateSpeaker.getClone();
          clonedSpeaker.pos = null;
          addHardware(hardware: clonedSpeaker, autoSave: false);
          targetSpeakers.add(clonedSpeaker);
        }
      }

      final int placeCount = algorithmCount;

      for (int i = 0; i < targetSpeakers.length; i++) {
        final Offset? nextPos = i < placeCount ? sortedPoints[i] : null;
        updateHardware(hardware: targetSpeakers[i].copyWith(pos: nextPos), autoSave: false);
      }

      saveProject();
      updateProject();

      if (placeCount < targetSpeakers.length) {
        return ResponseCallback<bool>.success(
          true,
          message: 'Placed $placeCount speakers from algorithm output. ${targetSpeakers.length - placeCount} speakers were left unplaced.',
        );
      }

      return ResponseCallback<bool>.success(true);
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Auto-placement failed: $e');
      return ResponseCallback<bool>.failure('Auto-placement failed. Check ceiling/listener values and try again.');
    }
  }

  List<Offset> _calculateAutoPlacedPositions({
    required ListeningArea listeningArea,
    required List<SpeakerProduct> catalogSpeakers,
    required List<Speaker> targetSpeakers,
    required AutoPlacementResult autoPlacementResult,
  }) {
    final MountingType mountingType = listeningArea.mountingType ?? targetSpeakers.first.mountingType ?? MountingType.surface;

    final Speaker referenceSpeaker = targetSpeakers.first;
    final SpeakerProduct? speakerProduct = catalogSpeakers.where((SpeakerProduct p) => p.productId == referenceSpeaker.productId).firstOrNull;

    final double coverageAngle = _resolveCoverageAngle(speakerProduct);

    double minX = listeningArea.vertices.first.position.dx;
    double maxX = minX;
    double minY = listeningArea.vertices.first.position.dy;
    double maxY = minY;
    for (final FusionCanvasPoint vertex in listeningArea.vertices) {
      if (vertex.position.dx < minX) minX = vertex.position.dx;
      if (vertex.position.dx > maxX) maxX = vertex.position.dx;
      if (vertex.position.dy < minY) minY = vertex.position.dy;
      if (vertex.position.dy > maxY) maxY = vertex.position.dy;
    }

    final double roomLength = (maxX - minX).abs();
    final double roomWidth = (maxY - minY).abs();
    if (roomLength <= 0 || roomWidth <= 0) return <Offset>[];

    final double listenerHeight = listeningArea.listeningHeight > 0 ? listeningArea.listeningHeight : 1.2;
    final double? parsedCeilingHeight = double.tryParse(listeningArea.ceilingHeight);
    if (parsedCeilingHeight == null || parsedCeilingHeight <= listenerHeight) {
      return <Offset>[];
    }
    final double ceilingHeight = parsedCeilingHeight;

    if (mountingType == MountingType.ceiling || mountingType == MountingType.pendant) {
      final List<ceiling_algo.Point2D> geometry =
          listeningArea.vertices.map((FusionCanvasPoint point) => ceiling_algo.Point2D(point.position.dx - minX, point.position.dy - minY)).toList();

      final ceiling_algo.Room room = ceiling_algo.Room.asymmetrical(
        geometry: geometry,
        ceilingHeight: ceilingHeight,
        listenerHeight: listenerHeight,
      );

      final ceiling_algo.SpeakerType speakerType = mountingType == MountingType.pendant ? ceiling_algo.SpeakerType.pendant : ceiling_algo.SpeakerType.ceiling;
      final double pendantHeight = (ceilingHeight - 0.15).clamp(listenerHeight + 0.05, ceilingHeight - 0.01);

      final ceiling_algo.PlacementResult result = ceiling_algo.AutoSpeakerPlacement.calculatePlacement(
        room: room,
        speakerSpec: ceiling_algo.SpeakerSpec(
          coverageAngle: coverageAngle,
          type: speakerType,
          pendantHeight: speakerType == ceiling_algo.SpeakerType.pendant ? pendantHeight : null,
        ),
        coveragePreference: _mapCeilingCoveragePreference(autoPlacementResult.autoPlaceSpacingPreset),
        layoutPattern:
            autoPlacementResult.autoPlaceLayoutPreset == AutoPlaceLayoutPreset.hexagonal
                ? ceiling_algo.LayoutPattern.hexagonal
                : ceiling_algo.LayoutPattern.square,
        customOriginOffset: ceiling_algo.Point2D(autoPlacementResult.autoPlaceGridX, autoPlacementResult.autoPlaceOffsetY),
        boundaryOverlapThreshold: autoPlacementResult.autoPlaceBoundaryThreshold.clamp(0.01, 0.9),
      );

      return result.speakerPositions.map((ceiling_algo.Point2D p) => Offset(p.x + minX, p.y + minY)).toList();
    }

    final surface_algo.SurfacePlacementResult result = surface_algo.SurfaceSpeakerPlacer.calculatePlacement(
      room: surface_algo.SurfaceRoom(
        length: roomLength,
        width: roomWidth,
        ceilingHeight: ceilingHeight,
        listenerHeight: listenerHeight,
      ),
      speaker: surface_algo.Loudspeaker(
        horizontalCoverageAngle: coverageAngle,
        type: referenceSpeaker.speakerSKU,
      ),
      config: surface_algo.PlacementConfig(
        coveragePreference: _mapSurfaceCoveragePreference(autoPlacementResult.autoPlaceSpacingPreset),
        enableDebugOutput: false,
      ),
    );

    return result.positions
        .map(
          (surface_algo.SpeakerPosition p) => Offset(
            minX + p.x + autoPlacementResult.autoPlaceGridX,
            minY + p.y + autoPlacementResult.autoPlaceOffsetY,
          ),
        )
        .toList();
  }

  double _resolveCoverageAngle(SpeakerProduct? product) {
    if (product == null || product.coverage.isEmpty) return 90.0;
    final int angle = product.coverage.first.horizontalDeg;
    return angle <= 0 ? 90.0 : angle.toDouble();
  }

  ceiling_algo.CoveragePreference _mapCeilingCoveragePreference(AutoPlaceSpacingPreset spacingPreset) {
    switch (spacingPreset) {
      case AutoPlaceSpacingPreset.edgeToEdge:
        return ceiling_algo.CoveragePreference.edgeToEdge;
      case AutoPlaceSpacingPreset.centerToCenter:
        return ceiling_algo.CoveragePreference.centerToCenter;
      case AutoPlaceSpacingPreset.minimumOverlap:
      case AutoPlaceSpacingPreset.customize:
        return ceiling_algo.CoveragePreference.minimumOverlap;
    }
  }

  surface_algo.CoveragePreference _mapSurfaceCoveragePreference(AutoPlaceSpacingPreset spacingPreset) {
    switch (spacingPreset) {
      case AutoPlaceSpacingPreset.edgeToEdge:
        return surface_algo.CoveragePreference.edgeToEdge;
      case AutoPlaceSpacingPreset.centerToCenter:
        return surface_algo.CoveragePreference.centerToCenter;
      case AutoPlaceSpacingPreset.minimumOverlap:
      case AutoPlaceSpacingPreset.customize:
        return surface_algo.CoveragePreference.minimumOverlap;
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

  void placeSelectedSpeaker({required Offset position, bool autoSave = true, required bool isFromBuildingPage}) {
    try {
      if (autoSave) recordSnapshot();

      final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakersForCurrentListeningArea();
      if (nonPlacedSpeakers.isEmpty) return;
      final Speaker updatedSpeaker = nonPlacedSpeakers.first.copyWith(pos: position);
      updateHardware(hardware: updatedSpeaker);

      if (nonPlacedSpeakers.length == 1) {
        // Last speaker placed
        setShouldPlaceNonPlacedSpeakers(false);
        updateProject();
      }
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: "Failed to add selected product as hardware: $e");
      setShouldPlaceNonPlacedSpeakers(false);
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
