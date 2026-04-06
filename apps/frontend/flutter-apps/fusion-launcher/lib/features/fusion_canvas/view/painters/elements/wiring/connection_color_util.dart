import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConnectionColorUtil {
  static final Map<ConnectionType, Color> _connectionColors = <ConnectionType, Color>{
    ConnectionType.analog: const Color(0xFFF17270),
    ConnectionType.aes67: const Color(0xFFF17270),
    ConnectionType.ethernet: const Color(0xFF3E996E),
    ConnectionType.usb: const Color(0xFF3AB8F5),
    ConnectionType.wifi: const Color(0xFF3AB8F5),
    ConnectionType.bluetooth: const Color(0xFF3AB8F5),
    ConnectionType.hdmi: const Color(0xFF3AB8F5),
    ConnectionType.audioJack: const Color(0xFF3AB8F5),
    ConnectionType.rca: const Color(0xFF3AB8F5),
    ConnectionType.amplifier: const Color(0xFFF17270),
    ConnectionType.dspAnalog: const Color(0xFFF17270),
    ConnectionType.endpoint: const Color(0xFF3AB8F5),
    ConnectionType.xlr: const Color(0xFF3AB8F5),
    ConnectionType.circuit: const Color(0xFFF19C40),
    ConnectionType.gpio: const Color(0xFFE3DFD7),
    ConnectionType.speaker: const Color(0xFFF19C40),
    ConnectionType.dsp: const Color(0xFFF19C40),
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
