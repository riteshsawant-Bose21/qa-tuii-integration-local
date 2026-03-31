part of '../product_port_data.dart';

class AnalogPortData {
  final int? inputs;
  final int? outputs;
  final AnalogPorts? ports;
  AnalogPortData({
    this.inputs,
    this.outputs,
    this.ports,
  });

  AnalogPortData copyWith({
    int? inputs,
    int? outputs,
    AnalogPorts? ports,
  }) {
    return AnalogPortData(
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

  factory AnalogPortData.fromMap(Map<String, dynamic> map) {
    return AnalogPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      ports: DeserializationUtil.classDeserializer(AnalogPorts.fromMap).deserialize(map['ports']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AnalogPortData.fromJson(String source) => AnalogPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AnalogPortData(inputs: $inputs, outputs: $outputs, ports: $ports)';
  }

  @override
  bool operator ==(covariant AnalogPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs && other.ports == ports;
  }

  @override
  int get hashCode {
    return inputs.hashCode ^ outputs.hashCode ^ ports.hashCode;
  }
}

class AnalogPorts {
  final List<PortInfo>? rcaInput;
  final List<PortInfo>? analogInput;
  final List<PortInfo>? analogOutputs;
  AnalogPorts({
    this.rcaInput,
    this.analogInput,
    this.analogOutputs,
  });

  AnalogPorts copyWith({
    List<PortInfo>? rcaInputs,
    List<PortInfo>? analogInputs,
    List<PortInfo>? analogOutputs,
  }) {
    return AnalogPorts(
      rcaInput: rcaInputs ?? this.rcaInput,
      analogInput: analogInputs ?? this.analogInput,
      analogOutputs: analogOutputs ?? this.analogOutputs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rca_input': rcaInput?.map((x) => x.toMap()).toList(),
      'analog_input': analogInput?.map((x) => x.toMap()).toList(),
      'analog_outputs': analogOutputs?.map((x) => x.toMap()).toList(),
    };
  }

  factory AnalogPorts.fromMap(Map<String, dynamic> map) {
    return AnalogPorts(
      rcaInput: PortInfo.fromList(map['rca_input']),
      analogInput: PortInfo.fromList(map['analog_input']),
      analogOutputs: PortInfo.fromList(map['analog_outputs']),
    );
  }

  @override
  bool operator ==(covariant AnalogPorts other) {
    if (identical(this, other)) return true;

    return listEquals(other.rcaInput, rcaInput) && listEquals(other.analogInput, analogInput) && listEquals(other.analogOutputs, analogOutputs);
  }

  @override
  int get hashCode => rcaInput.hashCode ^ analogInput.hashCode ^ analogOutputs.hashCode;

  @override
  String toString() => 'AnalogPorts(rcaInputs: $rcaInput, analogInputs: $analogInput, analogOutputs: $analogOutputs)';
}
