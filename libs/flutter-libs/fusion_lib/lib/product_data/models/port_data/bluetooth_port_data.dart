part of '../product_port_data.dart';

class BluetoothPortData {
  final int? inputs;
  final int? outputs;
  final int? channels;
  BluetoothPortData({
    this.inputs,
    this.outputs,
    this.channels,
  });

  BluetoothPortData copyWith({
    int? inputs,
    int? outputs,
    int? channels,
  }) {
    return BluetoothPortData(
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,

      channels: channels ?? this.channels,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
      'outputs': outputs,
      'channels': channels,
    };
  }

  factory BluetoothPortData.fromMap(Map<String, dynamic> map) {
    return BluetoothPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      channels: DeserializationUtil.intDeserializer.deserialize(map['channels']),
    );
  }

  String toJson() => json.encode(toMap());

  factory BluetoothPortData.fromJson(String source) => BluetoothPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BluetoothPortData(inputs: $inputs, outputs: $outputs, channels: $channels)';

  @override
  bool operator ==(covariant BluetoothPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs && other.channels == channels;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode ^ channels.hashCode;
}
