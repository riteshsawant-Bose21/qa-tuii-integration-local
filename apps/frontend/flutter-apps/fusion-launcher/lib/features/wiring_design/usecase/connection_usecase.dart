import 'package:fusion_lib/fusion_lib.dart';

/// A use case class responsible for creating wiring connections between devices.
///
/// This use case encapsulates the logic for establishing a connection from one device's port
/// to another device's port, determining the appropriate connection type based on the port types.
/// It is used to ensure that connections are created consistently and according to the wiring rules
/// defined by the application.
///
/// Example usage:
/// ```dart
/// final connection = ConnectionUseCase().createConnection(
///   fromDeviceId: 'deviceA',
///   fromPort: portA,
///   toDeviceId: 'deviceB',
///   toPort: portB,
/// );
/// ```
///
/// This use case is essential for managing the wiring design feature, as it abstracts the
/// connection creation logic and enforces type safety and connection rules.

class ConnectionUseCase {
  WiringConnectionModel createConnection({
    required String fromDeviceId,
    required PortData fromPort,
    required String toDeviceId,
    required PortData toPort,
  }) {
    final PossibleConnection? possibleConnection = PossibleConnection.findConnection(fromPort.type, toPort.type);
    return WiringConnectionModel(
      deviceId: fromDeviceId,
      portId: fromPort.id,
      targetDeviceId: toDeviceId,
      targetPortId: toPort.id,
      type: possibleConnection?.connectionType ?? ConnectionType.analog,
    );
  }

  bool isCompatible(PortType fromPort, PortType toPort) {
    final PossibleConnection? possibleConnection = PossibleConnection.findConnection(fromPort, toPort);
    return possibleConnection != null;
  }
}

class PossibleConnection {
  final PortType fromPortType;
  final PortType toPortType;
  final ConnectionType connectionType;
  PossibleConnection({
    required this.fromPortType,
    required this.toPortType,
    required this.connectionType,
  });

  static List<PossibleConnection> getPossibleConnections() {
    return <PossibleConnection>[
      PossibleConnection(fromPortType: PortType.analogInput, toPortType: PortType.analogOutput, connectionType: ConnectionType.analog),
      PossibleConnection(fromPortType: PortType.dspAnalogInput, toPortType: PortType.analogOutput, connectionType: ConnectionType.dsp),
      PossibleConnection(fromPortType: PortType.endpointInput, toPortType: PortType.analogOutput, connectionType: ConnectionType.endpoint),

      PossibleConnection(fromPortType: PortType.amplifierInput, toPortType: PortType.dspAnalogOutput, connectionType: ConnectionType.amplifier),

      PossibleConnection(fromPortType: PortType.circuitInput, toPortType: PortType.speakerOutput, connectionType: ConnectionType.circuit),
      PossibleConnection(fromPortType: PortType.circuitInput, toPortType: PortType.amplifierOutput, connectionType: ConnectionType.circuit),

      PossibleConnection(fromPortType: PortType.audioJackInput, toPortType: PortType.audioJackOutput, connectionType: ConnectionType.audioJack),

      PossibleConnection(fromPortType: PortType.xlrInput, toPortType: PortType.xlrOutput, connectionType: ConnectionType.xlr),
      PossibleConnection(fromPortType: PortType.usbIn, toPortType: PortType.usbOut, connectionType: ConnectionType.usb),
      PossibleConnection(fromPortType: PortType.hdmiIn, toPortType: PortType.hdmiOut, connectionType: ConnectionType.hdmi),

      PossibleConnection(fromPortType: PortType.bleIn, toPortType: PortType.bleOut, connectionType: ConnectionType.bluetooth),
      PossibleConnection(fromPortType: PortType.gpioInput, toPortType: PortType.gpioOutput, connectionType: ConnectionType.gpio),

      PossibleConnection(fromPortType: PortType.aes67Input, toPortType: PortType.aes67Output, connectionType: ConnectionType.aes67),
    ];
  }

  static PossibleConnection? findConnection(PortType from, PortType to) {
    return getPossibleConnections().firstWhereOrNull(
      (PossibleConnection connection) =>
          (connection.fromPortType == from && connection.toPortType == to) || (connection.fromPortType == to && connection.toPortType == from),
    );
  }
}
