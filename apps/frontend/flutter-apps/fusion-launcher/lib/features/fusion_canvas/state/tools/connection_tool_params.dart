import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Callback invoked when the user completes (drops) a connection drag.
///
/// - [sourcePort]  : the [WiringPortData] the user started dragging from.
/// - [dropPosition]: where the pointer was released (canvas-model space).
/// - [destinationPort]: the [WiringPortData] under the pointer at release,
///   or `null` if the drop was on empty canvas.
typedef OnConnectionDropCallback =
    void Function(
      WiringPortData sourcePort,
      Offset dropPosition,
      WiringPortData destinationPort,
    );

class ConnectionToolParams {
  final OnConnectionDropCallback onConnectionCreate;

  final List<WiringConnectionModel> Function(String deviceId, String portId) getExistingConnectionsForPort;
  final void Function(WiringConnectionModel connection) onConnectionDrop;

  const ConnectionToolParams({required this.onConnectionCreate, required this.getExistingConnectionsForPort, required this.onConnectionDrop});
}
