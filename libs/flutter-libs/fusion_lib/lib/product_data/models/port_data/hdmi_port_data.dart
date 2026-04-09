part of '../product_port_data.dart';

class HdmiPortData {
  final int? inputs;
  final int? outputs;
  final HdmiPorts? ports;
  HdmiPortData({
    this.inputs,
    this.outputs,
    this.ports,
  });

  HdmiPortData copyWith({
    int? inputs,
    int? outputs,
    HdmiPorts? ports,
  }) {
    return HdmiPortData(
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

  factory HdmiPortData.fromMap(Map<String, dynamic> map) {
    return HdmiPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      ports: DeserializationUtil.classDeserializer(HdmiPorts.fromMap).deserialize(map['ports']),
    );
  }

  String toJson() => json.encode(toMap());

  factory HdmiPortData.fromJson(String source) => HdmiPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'HdmiPortData(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant HdmiPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}

class HdmiPorts {
  final List<PortInfo>? inputs;
  final List<PortInfo>? outputs;
  HdmiPorts({
    this.inputs,
    this.outputs,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs?.map((x) => x.toMap()).toList(),
      'outputs': outputs?.map((x) => x.toMap()).toList(),
    };
  }

  factory HdmiPorts.fromMap(Map<String, dynamic> map) {
    return HdmiPorts(
      inputs: map['inputs'] != null ? List<PortInfo>.from(map['inputs']?.map((x) => PortInfo.fromMap(x))) : null,
      outputs: map['outputs'] != null ? List<PortInfo>.from(map['outputs']?.map((x) => PortInfo.fromMap(x))) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory HdmiPorts.fromJson(String source) => HdmiPorts.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'HdmiPorts(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant HdmiPorts other) {
    if (identical(this, other)) return true;

    return listEquals(other.inputs, inputs) && listEquals(other.outputs, outputs);
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}
