import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../../../speaker_selection_popup/viewmodel/product_query_view_model.dart';

class AutoPlacementResult {
  final List<Speaker> speakers;
  final SurfacePlacementResult? surfacePlacementResult;
  final PlacementResult? placementResult;
  final CeilingPlacementParams? ceilingPlacementParams;

  AutoPlacementResult({required this.speakers, required this.surfacePlacementResult, required this.placementResult, required this.ceilingPlacementParams});
}

class AutoPlacementUsecase {
  ResponseCallback<AutoPlacementResult> runAutoPlacementForCurrentListeningArea({
    required AutoPlacementParam autoPlacementResult,
    required ListeningArea listeningArea,
  }) {
    try {
      if (!listeningArea.autoPlacement) return ResponseCallback<AutoPlacementResult>.failure('Enable Auto-Placement and try again.');

      if (listeningArea.vertices.length < 3) {
        return ResponseCallback<AutoPlacementResult>.failure('Listening area shape is invalid. Redraw the area and try again.');
      }

      final ProductQueryViewModel productQueryViewModel = serviceLocator<ProductQueryViewModel>();
      final List<SpeakerProduct> catalogSpeakers = productQueryViewModel.speakers;

      final Speaker referenceSpeaker = _getAutoPlacementTargetSpeaker(listeningArea.id);

      final ({
        List<_SpeakerPos> positions,
        SurfacePlacementResult? surfacePlacementResult,
        PlacementResult? placementResult,
        CeilingPlacementParams? ceilingPlacementParams,
      })
      autoPlacedDetails = _calculateAutoPlacedPositions(
        listeningArea: listeningArea,
        catalogSpeakers: catalogSpeakers,
        referenceSpeaker: referenceSpeaker,
        autoPlacementResult: autoPlacementResult,
      );

      final List<_SpeakerPos> candidatePoints = autoPlacedDetails.positions;

      final SpeakerProduct? speakerProduct = catalogSpeakers.where((SpeakerProduct p) => p.productId == referenceSpeaker.productId).firstOrNull;

      // if (candidatePoints.isEmpty) {
      //   FusionLogger.log(tag: LogTag.project, message: 'Auto-placement candidate points: $candidatePoints');
      //   return ResponseCallback<AutoPlacementResult>.failure(
      //     'No valid placement positions found. Adjust your listening area shape or auto-placement settings and try again.',
      //   );
      // }

      final List<_SpeakerPos> sortedPoints = _sortPlacementPoints(listeningArea: listeningArea, points: candidatePoints);
      final int placeCount = sortedPoints.length;
      final ListeningAreaRoomBounds roomBounds = listeningArea.getBoundsForVertices();
      final List<Speaker> resultedSpeakers = <Speaker>[];
      // Add a fresh set of algorithm-placed speakers only.
      for (final _SpeakerPos point in sortedPoints) {
        final ({double pitch, double yaw}) orientation = _resolveOrientationForPlacement(
          mountingType: listeningArea.mountingType,
          position: point,
          bounds: roomBounds,
        );
        final Speaker clonedSpeaker = referenceSpeaker.getClone().copyWith(
          pitch: orientation.pitch,
          yaw: orientation.yaw,
        );
        clonedSpeaker.pos = point.position;
        resultedSpeakers.add(clonedSpeaker);
      }

      return ResponseCallback<AutoPlacementResult>.success(
        AutoPlacementResult(
          speakers: resultedSpeakers,
          surfacePlacementResult: autoPlacedDetails.surfacePlacementResult,
          placementResult: autoPlacedDetails.placementResult,
          ceilingPlacementParams: autoPlacedDetails.ceilingPlacementParams,
        ),
        message: 'Auto-placement successful. Placed $placeCount speakers.',
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'Auto-placement failed: $e');
      return ResponseCallback<AutoPlacementResult>.failure(e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  // Helper methods for auto-placement
  Speaker _getAutoPlacementTargetSpeaker(String listeningAreaId) {
    final List<Speaker> nonPlacedSpeakers = serviceLocator<ProjectViewModel>().getNonPlacedSpeakersForListeningArea(areaId: listeningAreaId);
    final List<Speaker> placedSpeakers = serviceLocator<ProjectViewModel>().getPlacedSpeakersForListeningArea(areaId: listeningAreaId);
    final List<Speaker> allSpeakers = <Speaker>[...placedSpeakers, ...nonPlacedSpeakers].where((Speaker element) => !element.isSubwoofer).toList();

    final Iterable<Speaker> filteredSpeakers = allSpeakers.where(
      (Speaker speaker) {
        return speaker.productId != null && !speaker.isSubwoofer && speaker.mountingType != null;
      },
    );

    if (filteredSpeakers.isEmpty) {
      throw Exception(
        'No valid speakers found for auto-placement. Add at least one non-subwoofer speaker with a defined product and mounting type to the listening area and try again.',
      );
    }

    return filteredSpeakers.first;
  }

  // Sort candidate points based on distance from center of listening area, closest first.
  // This is a heuristic to try to place speakers in a more balanced way in irregularly shaped rooms
  // where the algorithm may return clusters of points in certain areas.
  List<_SpeakerPos> _sortPlacementPoints({required ListeningArea listeningArea, required List<_SpeakerPos> points}) {
    final Offset center = listeningArea.getCenterPositionOfVertices() ?? points.first.position;
    return List<_SpeakerPos>.from(points)..sort((_SpeakerPos a, _SpeakerPos b) => (a.position - center).distance.compareTo((b.position - center).distance));
  }

  ({
    List<_SpeakerPos> positions,
    SurfacePlacementResult? surfacePlacementResult,
    PlacementResult? placementResult,
    CeilingPlacementParams? ceilingPlacementParams,
  })
  _calculateAutoPlacedPositions({
    required ListeningArea listeningArea,
    required List<SpeakerProduct> catalogSpeakers,
    required Speaker referenceSpeaker,
    required AutoPlacementParam autoPlacementResult,
  }) {
    final MountingType mountingType = listeningArea.mountingType;

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

    final double parsedCeilingHeight = listeningArea.ceilingHeight;
    if (parsedCeilingHeight <= listenerHeight) throw ArgumentError('Ceiling height must be greater than listener height.');

    final double ceilingHeight = parsedCeilingHeight;

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
          pendantHeight: listeningArea.ceilingHeight - listeningArea.listeningHeight,
        ),
        coveragePreference: autoPlacementResult.autoPlaceCoveragePreference,
        layoutPattern: autoPlacementResult.autoPlaceLayoutPattern,
      );

      final List<_SpeakerPos> positions =
          result.speakerPositions
              .map(
                (Point2D p) => _SpeakerPos(
                  position: Offset((p.x * 100) + bounds.minX, (p.y * 100) + bounds.minY),
                ),
              )
              .toList();

      return (
        positions: positions,
        surfacePlacementResult: null,
        placementResult: result,
        ceilingPlacementParams: CeilingPlacementParams(
          room: room,
          coverageAngle: coverageAngle,
          selectedLayoutPattern: autoPlacementResult.autoPlaceLayoutPattern,
          boundaryOverlapThreshold: 0.2,
          selectedCoveragePreference: autoPlacementResult.autoPlaceCoveragePreference,
          selectedSpeakerType: speakerType,
          selectedRoomType: room.roomType,
        ),
      );
    } else {
      final List<Offset> geometry = <Offset>[
        ...listeningArea.vertices.map(
          (FusionCanvasPoint point) => Offset(
            (point.position.dx - bounds.minX) / 100,
            (point.position.dy - bounds.minY) / 100,
          ),
        ),
      ];

      final SurfacePlacementResult result = SurfaceSpeakerPlacer.calculatePlacement(
        room: SurfaceRoom(
          corners: geometry,
          ceilingHeight: ceilingHeight,
          listenerHeight: listenerHeight,
        ),
        speaker: Loudspeaker(horizontalCoverageAngle: coverageAngle, type: referenceSpeaker.speakerSKU),
        config: PlacementConfig(
          coveragePreference: autoPlacementResult.autoPlaceCoveragePreference,
        ),
      );

      final List<_SpeakerPos> positions = <_SpeakerPos>[
        ...result.positions.map(
          (SpeakerPosition p) {
            return _SpeakerPos(
              position: Offset(
                (p.x * 100) + bounds.minX,
                (p.y * 100) + bounds.minY,
              ),
              yaw: p.rotation,
            );
          },
        ),
      ];
      return (positions: positions, surfacePlacementResult: result, placementResult: null, ceilingPlacementParams: null);
    }
  }

  double _resolveCoverageAngle(SpeakerProduct? product) {
    if (product == null || product.coverage.isEmpty) return 90.0;
    final int angle = product.coverage.firstOrNull?.horizontalDeg ?? 90;
    return angle <= 0 ? 90.0 : angle.toDouble();
  }

  ({double pitch, double yaw}) _resolveOrientationForPlacement({
    required MountingType mountingType,
    required _SpeakerPos position,
    required ListeningAreaRoomBounds bounds,
  }) {
    if (mountingType == MountingType.pendant || mountingType == MountingType.ceiling) return (pitch: 90.0, yaw: 0.0);
    if (mountingType != MountingType.surface) return (pitch: 0.0, yaw: 0.0);

    // final double dLeft = (position.dx - bounds.minX).abs();
    // final double dTop = (position.dy - bounds.minY).abs();
    // final double dRight = (bounds.maxX - position.dx).abs();
    // final double dBottom = (bounds.maxY - position.dy).abs();

    // if (dLeft <= dTop && dLeft <= dRight && dLeft <= dBottom) return (pitch: 0.0, yaw: 0.0); // Left wall
    // if (dTop <= dRight && dTop <= dBottom) return (pitch: 0.0, yaw: 90.0); // Top wall
    // if (dRight <= dBottom) return (pitch: 0.0, yaw: 180.0); // Right wall
    return (pitch: 0.0, yaw: position.yaw ?? 0.0); // Bottom wall
  }
}

class _SpeakerPos {
  final Offset position;
  final double? pitch;
  final double? yaw;
  final double? roll;

  _SpeakerPos({required this.position, this.pitch, this.yaw, this.roll});
}
