import 'package:fusion_lib/fusion_lib.dart';

/// Enum for port placement
enum PortPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  footerLeft,
  footerRight,
  footerCenter,
}

enum PortType {
  analogInput('Input'),
  analogOutput('Output'),
  aes67Input('Input'),
  aes67Output('Output'),
  ethernet('Ethernet'),
  networkSwitchIn('Ethernet'),
  networkSwitchOut('Ethernet'),
  usb('Usb'),
  usbIn('Usb'),
  usbOut('Usb'),
  // serial('Serial')v,
  // ble('Ble'),
  // wifi('Wifi'),
  // hdmi('Hdmi'),
  bleIn('Ble'),
  bleOut('Ble'),
  wifiIn('Wifi'),
  wifiOut('Wifi'),
  hdmiIn('Hdmi'),
  hdmiOut('Hdmi'),

  audioJackInput('3.5mm Jack'),
  audioJackOutput('3.5mm Jack'),

  rcaInput('RCA'),
  rcaOutput('RCA'),

  amplifierInput('Input'),
  amplifierOutput('Output'),
  dspAnalogInput('Input'),
  endpointInput('Input'),
  endpointOutput('Output'),
  dspAnalogOutput('Output'),
  controllerInput('Input'),
  controllerOutput('Output'),
  sourceData('Source Data'),
  speakerData('Speaker Data'),
  speakerInput('Input'),
  speakerOutput('Output'),
  digitalInput('Input'),
  digitalOutput('Output'),
  circuitInput('Input'),

  gpioInput('Input'),
  gpioOutput('Output'),

  fusionConnectInput('Input'),
  fusionConnectOutput('Output'),

  xlrInput('Input'),
  xlrOutput('Output');

  const PortType(this.description);

  final String description;
}

extension PortTypeExtension on PortType {
  String get droOutputType {
    switch (this) {
      case PortType.analogInput:
        return "io_in_analog";
      case PortType.aes67Input:
        return "io_in_aes67";
      case PortType.aes67Output:
        return "io_out_aes67";
      case PortType.usbIn:
        return "io_in_usb";
      case PortType.usbOut:
        return "io_out_usb";
      case PortType.bleIn:
        return "io_in_bluetooth";
      case PortType.wifiIn:
        return PortType.wifiOut.name;
      case PortType.hdmiIn:
        return "io_in_hdmi";
      case PortType.rcaInput:
        return "io_in_analog";
      case PortType.audioJackInput:
        return "io_in_playback";

      case PortType.amplifierInput:
        return PortType.amplifierOutput.name;
      case PortType.dspAnalogInput:
        return "io_in_analog";
      case PortType.dspAnalogOutput:
        return "io_out_analog";
      case PortType.controllerInput:
        return PortType.controllerOutput.name;
      case PortType.speakerInput:
        return PortType.speakerOutput.name;
      case PortType.digitalInput:
        return PortType.digitalOutput.name;
      case PortType.circuitInput:
        return ''; // No direct output type
      case PortType.gpioInput:
        return PortType.gpioOutput.name;
      case PortType.fusionConnectInput:
        return PortType.fusionConnectOutput.name;
      case PortType.xlrInput:
        return "io_out_analog";
      default:
        return ''; // For output types or types without a defined output
    }
  }
}

//DSP input port supported device port types
//analogInput,

/// Communication Port Model
class PortData {
  final String id;
  final String name; // "Ethernet", "USB"
  final String? description;
  final PortType type;
  // final List<PortType> compatibleTypes;

  /// Layout info
  final PortPosition position;
  final int portNumber; // render order in that position group

  PortData({
    String? id,
    required this.name,
    required this.description,
    required this.position,
    required this.portNumber,
    required this.type,
    // required this.compatibleTypes,
  }) : id = id ?? FusionUtils.shortStringUUID();

  //from json
  factory PortData.fromJson(Map<String, dynamic> json) {
    return PortData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      position: PortPosition.values.firstWhere(
        (e) => e.name == json['position'],
      ),
      portNumber: json['portNumber'] as int,
      type: PortType.values.firstWhere((e) => e.name == json['type']),
      // compatibleTypes: (json['compatibleTypes'] as List<dynamic>).map((e) => PortType.values.firstWhere((pt) => pt.name == e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'position': position.name,
      'portNumber': portNumber,
      'type': type.name,
      // 'compatibleTypes': compatibleTypes.map((e) => e.name).toList(),
    };
  }
}
