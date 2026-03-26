part of 'component_data.dart';

class ComponentPort {
  final String? image;
  final String? label;
  final PortType type;
  // final List<PortType> compatibleTypes;
  final String id;
  final PortPosition? position;
  final int index;
  final String? description;

  ComponentPort({
    required this.id,
    this.image,
    this.label,
    required this.type,
    // required this.compatibleTypes,
    this.position,
    this.index = 0,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'image': image,
      'label': label,
      'type': type.name,
      // 'compatibleTypes': compatibleTypes.map((PortType e) => e.name).toList(),
      'id': id,
    };
  }

  factory ComponentPort.fromPortData(PortData portData) {
    return ComponentPort(
      description: portData.description ?? '',
      image: switch (portData.type) {
        PortType.ethernet || PortType.networkSwitchIn || PortType.networkSwitchOut => 'assets/icons/wiring_ports/ethernet.png',
        PortType.wifiIn || PortType.wifiOut => 'assets/icons/wiring_ports/wifi.png',
        PortType.bleIn || PortType.bleOut => 'assets/icons/wiring_ports/bluetooth.png',
        PortType.hdmiIn || PortType.hdmiOut => 'assets/icons/wiring_ports/hdmi.png',
        PortType.usbIn || PortType.usbOut || PortType.usb => 'assets/icons/wiring_ports/usb.png',
        PortType.audioJackInput || PortType.audioJackOutput => 'assets/icons/wiring_ports/audio_jack.png',
        PortType.rcaInput || PortType.rcaOutput => 'assets/icons/wiring_ports/audio_jack.png',
        _ => null,
      },
      position: portData.position,
      index: portData.portNumber,
      label: portData.name,
      type: portData.type,
      // compatibleTypes: portData.compatibleTypes,
      id: portData.id,
    );
  }

  factory ComponentPort.fromMap(Map<String, dynamic> map) {
    return ComponentPort(
      description: map['description'] != null ? map['description'] as String : '',
      image: map['image'] != null ? map['image'] as String : null,
      label: map['label'] != null ? map['label'] as String : null,
      type: PortType.values.firstWhere(
        (PortType e) => e.name == map['type'],
      ),
      // compatibleTypes: List<PortType>.from(
      //   (map['compatibleTypes'] as List<dynamic>).map<PortType>(
      //     (dynamic e) => PortType.values.firstWhere(
      //       (PortType pt) => pt.name == e,
      //     ),
      //   ),
      // ),
      id: map['id'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ComponentPort.fromJson(String source) => ComponentPort.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ComponentPort other) {
    if (identical(this, other)) return true;

    return other.image == image && other.label == label && other.type == type && other.id == id;
  }

  @override
  int get hashCode {
    return image.hashCode ^ label.hashCode ^ type.hashCode ^ id.hashCode;
  }
}
