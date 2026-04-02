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
  // serial('Serial'),
  // ble('Ble'),
  // wifi('Wifi'),
  // hdmi('Hdmi'),
  bleIn('Ble'),
  bleOut('Ble'),
  wifiIn('Wifi'),
  wifiOut('Wifi'),
  hdmiIn('Hdmi'),
  hdmiOut('Hdmi'),

  audioJackInput('RCA/Jack'),
  audioJackOutput('RCA/Jack'),

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
