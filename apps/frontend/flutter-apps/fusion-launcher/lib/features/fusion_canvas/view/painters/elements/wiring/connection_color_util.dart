import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConnectionColorUtil {
  static const Color green = Color(0xFF3E996E);
  static const Color blue = Color(0xFF3AB8F5);
  static const Color orange = Color(0xFFF19C40);
  static const Color red = Color(0xFFF17270);
  static const Color gray = Color(0xFFE3DFD7);

  static final Map<ConnectionType, Color> _connectionColors = <ConnectionType, Color>{
    ConnectionType.analog: red,
    ConnectionType.aes67: red,
    ConnectionType.ethernet: green,
    ConnectionType.usb: blue,
    ConnectionType.wifi: blue,
    ConnectionType.bluetooth: blue,
    ConnectionType.hdmi: blue,
    ConnectionType.audioJack: blue,
    ConnectionType.rca: blue,
    ConnectionType.amplifier: red,
    ConnectionType.dspAnalog: red,
    ConnectionType.endpoint: blue,
    ConnectionType.xlr: blue,
    ConnectionType.circuit: orange,
    ConnectionType.gpio: gray,
    ConnectionType.speaker: orange,
    ConnectionType.dsp: orange,
  };

  static Color getColorForConnectionType(ConnectionType type) {
    return _connectionColors[type] ?? const Color(0xFF000000);
  }

  static Color getColorForPortType(PortType portType) {
    final PossibleConnection? possibleConnection = PossibleConnection.getPossibleConnections().firstWhereOrNull(
      (PossibleConnection connection) => connection.fromPortType == portType || connection.toPortType == portType,
    );
    return getColorForConnectionType(possibleConnection?.connectionType ?? ConnectionType.dsp);
  }
}
