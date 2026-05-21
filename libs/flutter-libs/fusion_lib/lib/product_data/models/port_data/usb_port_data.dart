part of '../product_port_data.dart';

class USBPortData {
  final int? ioPorts;
  final int? channels;
  final List<PortInfo>? ports;
  USBPortData({
    this.ioPorts,
    this.channels,
    this.ports,
  });

  USBPortData copyWith({
    int? ioPorts,
    int? channels,
    List<PortInfo>? ports,
  }) {
    return USBPortData(
      ioPorts: ioPorts ?? this.ioPorts,
      channels: channels ?? this.channels,
      ports: ports ?? this.ports,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'io_ports': ioPorts,
      'channels': channels,
      'ports': ports?.map((x) => x.toMap()).toList(),
    };
  }

  factory USBPortData.fromMap(Map<String, dynamic> map) {
    final channels = DeserializationUtil.intDeserializer.deserialize(map['channels']);
    final ioPorts = DeserializationUtil.intDeserializer.deserialize(map['io_ports']);

    return USBPortData(
      ioPorts: ioPorts ?? DeserializationUtil.intDeserializer.deserialize(map['inputs']) ?? DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      channels: channels ?? DeserializationUtil.intDeserializer.deserialize(map['number_of_channels_per_port']),
      ports: PortInfo.fromList(map['ports']),
    );
  }

  String toJson() => json.encode(toMap());

  factory USBPortData.fromJson(String source) => USBPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'USBPortData(ioPorts: $ioPorts, channels: $channels, ports: $ports)';

  @override
  bool operator ==(covariant USBPortData other) {
    if (identical(this, other)) return true;

    return other.ioPorts == ioPorts && other.channels == channels && listEquals(other.ports, ports);
  }

  @override
  int get hashCode => ioPorts.hashCode ^ channels.hashCode ^ ports.hashCode;
}
