import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';

import '../fusion_tool_state.dart';
import 'select_tool_state.dart';

/// Base state for the connection tool.
///
/// Extends [SelectToolState] so that a [FusionCanvasTool] keyed to
/// [SelectToolState] can intercept tap-down events on [WiringPortData]
/// elements and transition into [ConnectingToolState].
abstract class ConnectionToolState extends SelectToolState {}

/// Idle – waiting for the user to start dragging a port.
class IdleConnectionToolState extends ConnectionToolState {
  @override
  Set<String> get selectedLayerIds => const <String>{};

  @override
  Set<String> get selectedElementIds => const <String>{};

  @override
  bool operator ==(covariant FusionToolState other) => other is IdleConnectionToolState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Active – the user is currently dragging from [sourcePort].
class ConnectingToolState extends ConnectionToolState {
  /// The port the user started dragging from.
  final WiringPortData sourcePort;

  /// The port's absolute canvas-model position (origin of the drawn path).
  final Offset sourcePosition;

  /// Current mouse position in canvas-model space (end of the drawn path).
  final Offset currentPosition;

  /// Orthogonal path computed by [OrthogonalRouter].
  final List<Offset> path;

  ConnectingToolState({
    required this.sourcePort,
    required this.sourcePosition,
    required this.currentPosition,
    this.path = const <Offset>[],
  });

  ConnectingToolState copyWith({
    WiringPortData? sourcePort,
    Offset? sourcePosition,
    Offset? currentPosition,
    List<Offset>? path,
  }) {
    return ConnectingToolState(
      sourcePort: sourcePort ?? this.sourcePort,
      sourcePosition: sourcePosition ?? this.sourcePosition,
      currentPosition: currentPosition ?? this.currentPosition,
      path: path ?? this.path,
    );
  }

  @override
  Set<String> get selectedLayerIds => const <String>{};

  @override
  Set<String> get selectedElementIds => <String>{sourcePort.id};

  @override
  bool operator ==(covariant FusionToolState other) {
    if (identical(this, other)) return true;
    return other is ConnectingToolState && other.sourcePort == sourcePort && other.sourcePosition == sourcePosition && other.currentPosition == currentPosition;
  }

  @override
  int get hashCode => sourcePort.hashCode ^ sourcePosition.hashCode ^ currentPosition.hashCode;

  @override
  String toString() =>
      'ConnectingToolState(sourcePort: ${sourcePort.id}, '
      'sourcePosition: $sourcePosition, currentPosition: $currentPosition)';
}
