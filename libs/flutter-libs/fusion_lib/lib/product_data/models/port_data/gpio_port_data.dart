part of '../product_port_data.dart';

class GPIOPortData {
  final int? totalGpio;
  final int? assignableInputs;
  final int? assignableOutputs;
  final List<PortInfo>? ports;
  GPIOPortData({
    this.totalGpio,
    this.assignableInputs,
    this.assignableOutputs,
    this.ports,
  });
  GPIOPortData copyWith({
    int? totalGpio,
    int? assignableInputs,
    int? assignableOutputs,
    List<PortInfo>? ports,
  }) {
    return GPIOPortData(
      totalGpio: totalGpio ?? this.totalGpio,
      assignableInputs: assignableInputs ?? this.assignableInputs,
      assignableOutputs: assignableOutputs ?? this.assignableOutputs,
      ports: ports ?? this.ports,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total_gpio': totalGpio,
      'assignable_inputs': assignableInputs,
      'assignable_outputs': assignableOutputs,

      'ports': ports?.map((x) => x.toMap()).toList(),
    };
  }

  factory GPIOPortData.fromMap(Map<String, dynamic> map) {
    return GPIOPortData(
      totalGpio: DeserializationUtil.intDeserializer.deserialize(map['total_gpio']),
      assignableInputs: DeserializationUtil.intDeserializer.deserialize(map['assignable_inputs']),
      assignableOutputs: DeserializationUtil.intDeserializer.deserialize(map['assignable_outputs']),
      ports: PortInfo.fromList(map['ports']),
    );
  }
  String toJson() => json.encode(toMap());
  factory GPIOPortData.fromJson(String source) => GPIOPortData.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() => 'GPIOPortData(totalGpio: $totalGpio, assignableInputs: $assignableInputs, assignableOutputs: $assignableOutputs, ports: $ports)';
  @override
  bool operator ==(covariant GPIOPortData other) {
    if (identical(this, other)) return true;
    return other.totalGpio == totalGpio &&
        other.assignableInputs == assignableInputs &&
        other.assignableOutputs == assignableOutputs &&
        listEquals(other.ports, ports);
  }

  @override
  int get hashCode => totalGpio.hashCode ^ assignableInputs.hashCode ^ assignableOutputs.hashCode ^ ports.hashCode;
}
