part of '../product_port_data.dart';

class XlrPortData {
  final int? inputs;
  final int? outputs;
  XlrPortData({
    this.inputs,
    this.outputs,
  });
  XlrPortData copyWith({
    int? inputs,
    int? outputs,
  }) {
    return XlrPortData(
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
      'outputs': outputs,
    };
  }

  factory XlrPortData.fromMap(Map<String, dynamic> map) {
    return XlrPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
    );
  }
  String toJson() => json.encode(toMap());
  factory XlrPortData.fromJson(String source) => XlrPortData.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() => 'XlrPortData(inputs: $inputs, outputs: $outputs)';
  @override
  bool operator ==(covariant XlrPortData other) {
    if (identical(this, other)) return true;
    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}
