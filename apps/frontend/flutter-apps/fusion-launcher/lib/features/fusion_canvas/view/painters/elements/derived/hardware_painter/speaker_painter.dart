import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_element_painter.dart';

class SpeakerPainter extends FusionCanvasElementPainter {
  final Speaker hardware;

  SpeakerPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);
      final String? listeningAreaId = hardware.locationEntity.listeningAreaId;
      if (listeningAreaId != null) {
        final ListeningArea listeningArea = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);
        final ListeningAreaRoomBounds bounds = listeningArea.getBoundsForVertices();

        if (hardware.mountingType == MountingType.surface && listeningArea.autoPlacementResult?.surfacePlacementResult != null) {
          dev.log('Drawing directional coverage for speaker: ${hardware.id}');
          _drawSurfaceDirectionalCoverage(
            canvas,
            painter: painter,
            speakerScreenCenter: rect.center,
            speakerModelPos: position,
            bounds: bounds,
            listeningAreaId: listeningArea.id,
            distanceToListenerPlane: listeningArea.autoPlacementResult!.surfacePlacementResult!.distanceToListenerPlane,
            horizontalCoverageAngle: listeningArea.autoPlacementResult!.surfacePlacementResult!.horizontalCoverageAngle,
          );
        } else if ((hardware.mountingType == MountingType.ceiling || hardware.mountingType == MountingType.pendant) &&
            listeningArea.autoPlacementResult?.ceilingPendantPlacementResult != null) {
          dev.log('Drawing ceiling/pendant coverage for speaker: ${hardware.id}');
          _drawCeilingCoverageCircle(
            canvas,
            painter: painter,
            speakerCenter: rect.center,
            gridSpacing: listeningArea.autoPlacementResult!.ceilingPendantPlacementResult!.gridSpacing,
          );
        }
      }

      _drawSpeaker(rect, canvas, painter, hardware);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! SpeakerPainter) return true;
    return oldDelegate.hardware != hardware;
  }

  void _drawCeilingCoverageCircle(
    Canvas canvas, {
    required FusionCanvasPainter painter,
    required Offset speakerCenter,
    required double gridSpacing, // algorithm metres
  }) {
    const Color dottedOutlineColor = Color(0x80000000); // 50% black
    // gridSpacing is the centre-to-centre speaker spacing in metres.
    // The coverage radius per speaker is half that, converted to canvas model px (×100).
    final double radius = (gridSpacing / 2) * 100.0;
    if (radius <= 0 || !radius.isFinite) return;

    final Path circlePath = Path()..addOval(Rect.fromCircle(center: speakerCenter, radius: radius));
    final Paint outlinePaint =
        Paint()
          ..color = dottedOutlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = nonScaling(1.2, painter);

    _drawDashedPath(
      canvas: canvas,
      path: circlePath,
      paint: outlinePaint,
      dashLength: nonScaling(6.0, painter),
      gapLength: nonScaling(4.0, painter),
    );
  }

  void _drawSurfaceDirectionalCoverage(
    Canvas canvas, {
    required FusionCanvasPainter painter,
    required Offset speakerScreenCenter,
    required Offset speakerModelPos, // hardware.pos in canvas model px
    required ListeningAreaRoomBounds bounds, // canvas model px
    required String listeningAreaId,
    required double distanceToListenerPlane,
    required double horizontalCoverageAngle,
  }) {
    const Color dottedOutlineColor = Color(0x80000000); // 50% black
    final Paint coverageOutlinePaint = Paint();
    coverageOutlinePaint.color = dottedOutlineColor;
    coverageOutlinePaint.style = PaintingStyle.stroke;
    coverageOutlinePaint.strokeWidth = nonScaling(1.2, painter);

    // Transform room corners to screen/draw coordinates using the canvas painter's
    // actual zoom + pan — same transform used by getTransformedRect / _drawSpeaker.
    final Offset topLeft = transformOffsetForLayer(Offset(bounds.minX, bounds.minY), painter, listeningAreaId);
    final Offset bottomRight = transformOffsetForLayer(Offset(bounds.maxX, bounds.maxY), painter, listeningAreaId);
    final Rect roomBounds = Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);

    // Save canvas state and apply clipping
    canvas.save();
    canvas.clipRect(roomBounds);

    // Wall detection in canvas model px (position and bounds are in the same space).
    const double wallTolerancePx = 5.0; // ~5 cm
    final bool onLeftWall = (speakerModelPos.dx - bounds.minX).abs() < wallTolerancePx;
    final bool onRightWall = (speakerModelPos.dx - bounds.maxX).abs() < wallTolerancePx;
    final bool onFrontWall = (speakerModelPos.dy - bounds.minY).abs() < wallTolerancePx;
    final bool onBackWall = (speakerModelPos.dy - bounds.maxY).abs() < wallTolerancePx;

    dev.log("Wall detection — left:$onLeftWall right:$onRightWall front:$onFrontWall back:$onBackWall");

    // Coverage distance: algorithm metres → canvas model px (×100).
    // The canvas painter pre-applies translate+scale, so drawing in model px is correct.
    final double coverageDistance = distanceToListenerPlane * 100.0;

    final Path coveragePath = Path();

    if (onFrontWall) {
      _drawSectorCoverage(
        canvas,
        coveragePath,
        speakerScreenCenter.dx,
        speakerScreenCenter.dy,
        coverageDistance,
        90,
        coverageOutlinePaint,
        nonScaling(6.0, painter),
        nonScaling(4.0, painter),
        horizontalCoverageAngle,
      );
      dev.log("onFrontWall");
    } else if (onBackWall) {
      _drawSectorCoverage(
        canvas,
        coveragePath,
        speakerScreenCenter.dx,
        speakerScreenCenter.dy,
        coverageDistance,
        270,
        coverageOutlinePaint,
        nonScaling(6.0, painter),
        nonScaling(4.0, painter),
        horizontalCoverageAngle,
      );
      dev.log("onBackWall");
    } else if (onLeftWall) {
      _drawSectorCoverage(
        canvas,
        coveragePath,
        speakerScreenCenter.dx,
        speakerScreenCenter.dy,
        coverageDistance,
        0,
        coverageOutlinePaint,
        nonScaling(6.0, painter),
        nonScaling(4.0, painter),
        horizontalCoverageAngle,
      );
      dev.log("onLeftWall");
    } else if (onRightWall) {
      _drawSectorCoverage(
        canvas,
        coveragePath,
        speakerScreenCenter.dx,
        speakerScreenCenter.dy,
        coverageDistance,
        180,
        coverageOutlinePaint,
        nonScaling(6.0, painter),
        nonScaling(4.0, painter),
        horizontalCoverageAngle,
      );
      dev.log("onRightWall");
    } else {
      dev.log("Nothing here to draw");
    }

    // Restore canvas state (remove clipping)
    canvas.restore();
  }

  void _drawSectorCoverage(
    Canvas canvas,
    Path path,
    double centerX,
    double centerY,
    double distance,
    double directionDegrees,
    Paint strokePaint,
    double dashLength,
    double gapLength,
    double horizontalCoverageAngle,
  ) {
    // Convert direction to radians
    final double directionRadians = directionDegrees * 3.14159 / 180;

    // Use actual horizontal coverage angle from speaker specification
    final double halfAngleRadians = (horizontalCoverageAngle * 3.14159 / 180) / 2;

    // Calculate the sector endpoints
    final double leftAngle = directionRadians - halfAngleRadians;
    final double rightAngle = directionRadians + halfAngleRadians;

    // Calculate the end points of the sector
    final double leftEndX = centerX + distance * cos(leftAngle);
    final double leftEndY = centerY + distance * sin(leftAngle);

    // Create directional sector path (pie slice)
    path.reset();
    path.moveTo(centerX, centerY); // Start at speaker position
    path.lineTo(leftEndX, leftEndY); // Line to left edge of coverage

    // Add arc between the endpoints
    path.arcTo(
      Rect.fromCenter(center: Offset(centerX, centerY), width: distance * 2, height: distance * 2),
      leftAngle,
      rightAngle - leftAngle,
      false,
    );

    path.lineTo(centerX, centerY); // Line back to speaker position
    path.close();

    // Draw dashed sector outline only.
    _drawDashedPath(
      canvas: canvas,
      path: path,
      paint: strokePaint,
      dashLength: dashLength,
      gapLength: gapLength,
    );
  }

  void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  void _drawSpeaker(Rect rect, Canvas canvas, FusionCanvasPainter painter, Speaker speaker) {
    final Paint paint = Paint()..color = painter.context.colorScheme.black;

    final MountingType? mountingType = speaker.mountingType;
    switch (mountingType) {
      case MountingType.surface:
        return canvas.drawRect(rect, paint);
      case MountingType.pendant:
        return canvas.drawPath(
          Path()
            ..moveTo(rect.topCenter.dx, rect.topCenter.dy)
            ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
            ..lineTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
            ..close(),
          paint,
        );
      case MountingType.ceiling:
      case null:
        return canvas.drawCircle(rect.center, rect.width / 2, paint);
    }
  }

  @override
  Offset getOffset() => hardware.pos ?? Offset.zero;

  @override
  Size getSize() => const Size.square(30);
}
