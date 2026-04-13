part of '../product_port_data.dart';

class FusionConnectPortData {
  final int? maxInputs;
  final int? maxOutputs;
  FusionConnectPortData({
    this.maxInputs,
    this.maxOutputs,
  });
  FusionConnectPortData copyWith({
    int? maxInputs,
    int? maxOutputs,
  }) {
    return FusionConnectPortData(
      maxInputs: maxInputs ?? this.maxInputs,
      maxOutputs: maxOutputs ?? this.maxOutputs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'max_inputs': maxInputs,
      'max_outputs': maxOutputs,
    };
  }

  factory FusionConnectPortData.fromMap(Map<String, dynamic> map) {
    return FusionConnectPortData(
      maxInputs: DeserializationUtil.intDeserializer.deserialize(map['max_inputs']),
      maxOutputs: DeserializationUtil.intDeserializer.deserialize(map['max_outputs']),
    );
  }
  String toJson() => json.encode(toMap());
  factory FusionConnectPortData.fromJson(String source) => FusionConnectPortData.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() => 'FusionConnectPortData(maxInputs: $maxInputs, maxOutputs: $maxOutputs)';
  @override
  bool operator ==(covariant FusionConnectPortData other) {
    if (identical(this, other)) return true;

    return other.maxInputs == maxInputs && other.maxOutputs == maxOutputs;
  }

  @override
  int get hashCode => maxInputs.hashCode ^ maxOutputs.hashCode;
}
