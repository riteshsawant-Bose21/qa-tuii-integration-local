part of '../product_port_data.dart';

class Aes67PortData {
  final int? maxInputs;
  final int? maxOutputs;
  Aes67PortData({
    this.maxInputs,
    this.maxOutputs,
  });

  Aes67PortData copyWith({
    int? maxInputs,
    int? maxOutputs,
  }) {
    return Aes67PortData(
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

  factory Aes67PortData.fromMap(Map<String, dynamic> map) {
    return Aes67PortData(
      maxInputs: DeserializationUtil.intDeserializer.deserialize(map['max_inputs']),
      maxOutputs: DeserializationUtil.intDeserializer.deserialize(map['max_outputs']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Aes67PortData.fromJson(String source) => Aes67PortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Aes67PortData(maxInputs: $maxInputs, maxOutputs: $maxOutputs)';

  @override
  bool operator ==(covariant Aes67PortData other) {
    if (identical(this, other)) return true;

    return other.maxInputs == maxInputs && other.maxOutputs == maxOutputs;
  }

  @override
  int get hashCode => maxInputs.hashCode ^ maxOutputs.hashCode;
}
