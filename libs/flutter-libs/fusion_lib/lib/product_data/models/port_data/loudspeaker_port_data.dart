part of '../product_port_data.dart';

class LoudspeakerPortData {
  final int? inputs;
  final int? outputs;
  LoudspeakerPortData({
    this.inputs,
    this.outputs,
  });

  LoudspeakerPortData copyWith({
    int? inputs,
    int? outputs,
  }) {
    return LoudspeakerPortData(
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

  factory LoudspeakerPortData.fromMap(Map<String, dynamic> map) {
    return LoudspeakerPortData(
      inputs: map['inputs'] != null ? map['inputs'] as int : null,
      outputs: map['outputs'] != null ? map['outputs'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoudspeakerPortData.fromJson(String source) => LoudspeakerPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'LoudspeakerPortData(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant LoudspeakerPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}
