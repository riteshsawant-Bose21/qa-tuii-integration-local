import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';

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
      WiringPortData? destinationPort,
    );

class ConnectionToolParams {
  final OnConnectionDropCallback onConnectionDrop;

  const ConnectionToolParams({required this.onConnectionDrop});
}
