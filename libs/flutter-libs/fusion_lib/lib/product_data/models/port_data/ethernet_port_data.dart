part of '../product_port_data.dart';


class EthernetPortData {
  final int? inputs;
  final int? outputs;
  final EthernetPorts? ports;
  EthernetPortData({
    this.inputs,
    this.outputs,
    this.ports,
  });

  EthernetPortData copyWith({
    int? inputs,
    int? outputs,
    EthernetPorts? ports,
  }) {
    return EthernetPortData(
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      ports: ports ?? this.ports,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
      'outputs': outputs,
      'ports': ports?.toMap(),
    };
  }

  factory EthernetPortData.fromMap(Map<String, dynamic> map) {
    return EthernetPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      ports: DeserializationUtil.classDeserializer(EthernetPorts.fromMap).deserialize(map['ports']),
    );
  }

  String toJson() => json.encode(toMap());

  factory EthernetPortData.fromJson(String source) => EthernetPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'EthernetPortData(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant EthernetPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}

class EthernetPorts {
  final List<PortInfo>? inputs;
  final List<PortInfo>? outputs;
  EthernetPorts({
    this.inputs,
    this.outputs,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs?.map((x) => x.toMap()).toList(),
      'outputs': outputs?.map((x) => x.toMap()).toList(),
    };
  }

  factory EthernetPorts.fromMap(Map<String, dynamic> map) {
    return EthernetPorts(
      inputs: map['inputs'] != null ? List<PortInfo>.from(map['inputs']?.map((x) => PortInfo.fromMap(x))) : null,
      outputs: map['outputs'] != null ? List<PortInfo>.from(map['outputs']?.map((x) => PortInfo.fromMap(x))) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EthernetPorts.fromJson(String source) => EthernetPorts.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'EthernetPorts(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant EthernetPorts other) {
    if (identical(this, other)) return true;

    return listEquals(other.inputs, inputs) && listEquals(other.outputs, outputs);
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}
