import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/selection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/path_finder_algorithm.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../fusion_canvas_tool_viewmodel.dart';
import '../tool_helper/selection_tool_helper.dart';
import '../tools/fusion_canvas_tool.dart';

/// Handles [SelectToolState] events, intercepting port drags to initiate
/// wiring connections.  For all non-port interactions the request is
/// forwarded to an inner [SelectionToolHelper] so that regular selection
/// behaviour is preserved.
class ConnectionToolHelper extends FusionCanvasToolTransformer<ConnectingToolState> {
  final ConnectionToolParams connectionParams;
  final SelectionToolParams selectionParams;

  const ConnectionToolHelper({
    required this.connectionParams,
    required this.selectionParams,
  });

  @override
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required SelectToolState currentState,
  }) {
    // ── Active connection: user is currently dragging from a port ──────────
    if (currentState is ConnectingToolState) {
      return _handleConnection(inputState, context, currentState);
    }

    // ── Idle / selection state: watch for port tap-down ────────────────────
    if (inputState is FusionCanvasInputTapDownState && inputState.button == FusionMouseButton.left) {
      final FusionCanvasElement? hovered = context.hoverState.hoveredElement;
      if (hovered is WiringPortData) {
        final List<WiringConnectionModel> existinnConnections = connectionParams.getExistingConnectionsForPort(hovered.deviceId, hovered.port.id);
        if (existinnConnections.isNotEmpty) {
          print("Has existing connections: ${existinnConnections.length}");
          final WiringConnectionModel connection = existinnConnections.first;
          final String otherDeviceId = connection.deviceId == hovered.deviceId ? connection.targetDeviceId : connection.deviceId;
          final String otherPortId = otherDeviceId == connection.deviceId ? connection.portId : connection.targetPortId;

          final FusionBasePainter? otherDevicePainter =
              context.fusionCanvasPainter.getLayerById(otherDeviceId) ??
              context.fusionCanvasPainter.layers.whereType<PortPainter>().firstWhereOrNull(
                (PortPainter painter) => painter.getPorts(Rect.zero, context.fusionCanvasPainter).any((WiringPortData port) => port.port.id == otherPortId),
              );
          print(
            "Other device painter for  $otherDeviceId: ${otherDevicePainter != null ? "found" : "not found"}.   Hovered Device ID: ${hovered.deviceId}, Hovered Port ID: ${hovered.port.id}, Connection device ID: ${connection.deviceId}, Connection port ID: ${connection.portId}",
          );

          if (otherDevicePainter is PortPainter) {
            final WiringPortData otherPort = otherDevicePainter
                .getPorts(Rect.zero, context.fusionCanvasPainter)
                .firstWhere((WiringPortData port) => port.port.id == otherPortId, orElse: () => hovered);
            print("Other port for $otherPortId: ${otherPort.id}");
            return _beginConnection(connection, otherPort, context);
          }

          return _beginConnection(connection, hovered, context);
        } else {
          return _beginConnection(null, hovered, context);
        }
      }
    }

    // ── Fall through: normal selection behaviour ────────────────────────────
    return SelectionToolHelper(selectionToolParams: selectionParams).transform(
      inputState: inputState,
      context: context,
      currentState: currentState,
    );
  }

  // ── Connection lifecycle ─────────────────────────────────────────────────

  FusionToolState _beginConnection(
    WiringConnectionModel? existingConnection,
    WiringPortData sourcePort,
    FusionCanvasInputContext context,
  ) {
    final Offset sourcePosition = _absolutePortPosition(
      sourcePort,
      context,
    );

    return ConnectingToolState(
      originalConnection: existingConnection,
      sourcePort: sourcePort,
      sourcePosition: sourcePosition,
      currentPosition: sourcePosition,
      path: <Offset>[sourcePosition, sourcePosition],
    );
  }

  FusionToolState _handleConnection(
    FusionCanvasInputState inputState,
    FusionCanvasInputContext context,
    ConnectingToolState current,
  ) {
    // Update path during drag
    if (inputState is FusionCanvasInputDraggingState && inputState.button == FusionMouseButton.left) {
      final Offset target = inputState.currentPosition;
      final List<Offset> path = _computePath(current.sourcePosition, target, context);
      return current.copyWith(
        currentPosition: target,
        path: path,
      );
    }

    // Commit or cancel on pointer release
    if (inputState is FusionCanvasInputTapUpState) {
      if (inputState.gestureOrigin == FusionGestureOrigin.drag) {
        final FusionCanvasElement? hovered = context.hoverState.hoveredElement;
        final WiringPortData? destination = (hovered is WiringPortData && hovered.id != current.sourcePort.id) ? hovered : null;
        if (destination != null) {
          final WiringConnectionModel? existing = current.originalConnection;
          if ((existing != null && existing.deviceId == current.sourcePort.deviceId && existing.portId == current.sourcePort.port.id) ||
              (existing != null && existing.targetDeviceId == current.sourcePort.deviceId && existing.targetPortId == current.sourcePort.port.id)) {
            // This is a reconnection, remove the old connection first
            connectionParams.onConnectionDrop(existing);
          }
          connectionParams.onConnectionCreate(
            current.sourcePort,
            inputState.tapPosition,
            destination,
          );
        } else {
          final WiringConnectionModel? existing = current.originalConnection;
          if (existing != null) {
            connectionParams.onConnectionDrop(existing);
          }
        }
      }
      // Both drag-drop and click-away return to idle selection
      return IdleSelectToolState();
    }

    // Right-click / secondary tap cancels
    if (inputState is FusionCanvasInputSecondaryTapState) {
      return IdleSelectToolState();
    }

    return current;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Resolves the canvas-model position of [port] by looking up its
  /// owning painter via [context].
  Offset _absolutePortPosition(
    WiringPortData port,
    FusionCanvasInputContext context,
  ) {
    final String painterId = port.deviceId;
    final FusionBasePainter? painter =
        context.fusionCanvasPainter.getLayerById(painterId) ??
        context.fusionCanvasPainter.layers.whereType<PortPainter>().firstWhereOrNull(
          (PortPainter painter) => painter.getPorts(Rect.zero, context.fusionCanvasPainter).any((WiringPortData p) => p.port.id == port.id),
        );

    if (painter is FusionCanvasElementPainter && painter is PortPainter) {
      return (painter).getPortPosition(port.id, context.fusionCanvasPainter)?.$1.center ?? context.inputState.mousePosition ?? Offset.zero;
      // return port.position + rect.topLeft;
    }

    // Fallback: use current mouse position
    return context.inputState.mousePosition ?? Offset.zero;
  }

  /// Uses [OrthogonalRouter] to compute an obstacle-avoiding orthogonal
  /// path from [start] to [end].  Obstacle rects are the canvas-model
  /// bounds of every element painter.
  List<Offset> _computePath(
    Offset start,
    Offset end,
    FusionCanvasInputContext context,
  ) {
    final List<Rect> obstacles =
        context.fusionCanvasPainter.layers
            .whereType<FusionCanvasElementPainter>()
            .map((FusionCanvasElementPainter p) => p.getBounds(context.fusionCanvasPainter))
            .toList();

    final OrthogonalRouter router = OrthogonalRouter(obstacles);
    final List<Offset> path = router.findPath(start, end);
    return path.isNotEmpty ? path : <Offset>[start, end];
  }
}
