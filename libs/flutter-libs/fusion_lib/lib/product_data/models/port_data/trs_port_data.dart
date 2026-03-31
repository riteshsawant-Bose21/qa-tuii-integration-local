part of '../product_port_data.dart';

class TrsPortData {
  final int? inputs;
  final int? outputs;
  TrsPortData({
    this.inputs,
    this.outputs,
  });
  TrsPortData copyWith({
    int? inputs,
    int? outputs,
  }) {
    return TrsPortData(
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

  factory TrsPortData.fromMap(Map<String, dynamic> map) {
    return TrsPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
    );
  }
  String toJson() => json.encode(toMap());
  factory TrsPortData.fromJson(String source) => TrsPortData.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() => 'TrsPortData(inputs: $inputs, outputs: $outputs)';
  @override
  bool operator ==(covariant TrsPortData other) {
    if (identical(this, other)) return true;
    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}
