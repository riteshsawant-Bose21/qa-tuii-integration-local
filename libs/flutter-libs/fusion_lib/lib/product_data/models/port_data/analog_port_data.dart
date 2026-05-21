part of '../product_port_data.dart';

class AnalogPortData {
  final int? inputBalanced;
  final int? inputUnbalanced;
  final int? outputBalanced;
  final int? outputUnbalanced;
  int? get inputs => (inputBalanced ?? 0) + (inputUnbalanced ?? 0);
  int? get outputs => (outputBalanced ?? 0) + (outputUnbalanced ?? 0);
  final AnalogPorts? ports;
  AnalogPortData({
    this.inputBalanced,
    this.inputUnbalanced,
    this.outputBalanced,
    this.outputUnbalanced,

    this.ports,
  });

  AnalogPortData copyWith({
    int? inputBalanced,
    int? inputUnbalanced,
    int? outputBalanced,
    int? outputUnbalanced,
    AnalogPorts? ports,
  }) {
    return AnalogPortData(
      inputBalanced: inputBalanced ?? this.inputBalanced,
      inputUnbalanced: inputUnbalanced ?? this.inputUnbalanced,
      outputBalanced: outputBalanced ?? this.outputBalanced,
      outputUnbalanced: outputUnbalanced ?? this.outputUnbalanced,
      ports: ports ?? this.ports,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
      'outputs': outputs,
      'ports': ports?.toMap(),
      'input_balanced': inputBalanced,
      'input_unbalanced': inputUnbalanced,
      'output_balanced': outputBalanced,
      'output_unbalanced': outputUnbalanced,
    };
  }

  factory AnalogPortData.fromMap(Map<String, dynamic> map) {
    return AnalogPortData(
      ports: DeserializationUtil.classDeserializer(AnalogPorts.fromMap).deserialize(map['ports']),
      inputBalanced: DeserializationUtil.intDeserializer.deserialize(map['inputs_balanced']),
      inputUnbalanced: DeserializationUtil.intDeserializer.deserialize(map['inputs_unbalanced']),
      outputBalanced: DeserializationUtil.intDeserializer.deserialize(map['outputs_balanced']),
      outputUnbalanced: DeserializationUtil.intDeserializer.deserialize(map['outputs_unbalanced']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AnalogPortData.fromJson(String source) => AnalogPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AnalogPortData(inputs: $inputs, outputs: $outputs, ports: $ports, inputBalanced: $inputBalanced, inputUnbalanced: $inputUnbalanced, outputBalanced: $outputBalanced, outputUnbalanced: $outputUnbalanced)';
  }

  @override
  bool operator ==(covariant AnalogPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs &&
        other.outputs == outputs &&
        other.ports == ports &&
        other.inputBalanced == inputBalanced &&
        other.inputUnbalanced == inputUnbalanced &&
        other.outputBalanced == outputBalanced &&
        other.outputUnbalanced == outputUnbalanced;
  }

  @override
  int get hashCode {
    return inputs.hashCode ^
        outputs.hashCode ^
        ports.hashCode ^
        inputBalanced.hashCode ^
        inputUnbalanced.hashCode ^
        outputBalanced.hashCode ^
        outputUnbalanced.hashCode;
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
      rcaInput: rcaInputs ?? rcaInput,
      analogInput: analogInputs ?? analogInput,
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
