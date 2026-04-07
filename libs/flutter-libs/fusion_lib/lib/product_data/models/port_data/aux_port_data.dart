part of '../product_port_data.dart';

class AuxPortData {
  final int? ioPorts;
  final List<PortInfo>? ports;
  AuxPortData({
    this.ioPorts,
    this.ports,
  });

  AuxPortData copyWith({
    int? ioPorts,
    List<PortInfo>? ports,
  }) {
    return AuxPortData(
      ioPorts: ioPorts ?? this.ioPorts,
      ports: ports ?? this.ports,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'io_ports': ioPorts,
      'ports': ports?.map((x) => x.toMap()).toList(),
    };
  }

  factory AuxPortData.fromMap(Map<String, dynamic> map) {
    return AuxPortData(
      ioPorts: DeserializationUtil.intDeserializer.deserialize(map['io_ports']),
      ports: PortInfo.fromList(map['ports']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AuxPortData.fromJson(String source) => AuxPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AuxPortData(ioPorts: $ioPorts, ports: $ports)';

  @override
  bool operator ==(covariant AuxPortData other) {
    if (identical(this, other)) return true;

    return other.ioPorts == ioPorts && listEquals(other.ports, ports);
  }

  @override
  int get hashCode => ioPorts.hashCode ^ ports.hashCode;
}
