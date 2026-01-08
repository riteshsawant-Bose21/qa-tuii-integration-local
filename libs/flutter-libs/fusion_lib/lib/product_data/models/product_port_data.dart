// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:fusion_lib/fusion_utils/fusion_utils.dart';

class ProductPortData {
  final Aes67PortData? aes67;
  final AnalogPortData? analog;
  final BluetoothPortData? bluetoothIo;
  final FusionConnectPortData? fusionConnect;
  final GPIOPortData? gpio;
  final HdmiPortData? hdmiIo;
  final USBPortData? usbIoPorts;
  ProductPortData({
    this.aes67,
    this.analog,
    this.bluetoothIo,
    this.fusionConnect,
    this.gpio,
    this.hdmiIo,
    this.usbIoPorts,
  });

  ProductPortData copyWith({
    Aes67PortData? aes67,
    AnalogPortData? analog,
    BluetoothPortData? bluetoothIo,
    FusionConnectPortData? fusionConnect,
    GPIOPortData? gpio,
    HdmiPortData? hdmiIo,
    USBPortData? usbIoPorts,
  }) {
    return ProductPortData(
      aes67: aes67 ?? this.aes67,
      analog: analog ?? this.analog,
      bluetoothIo: bluetoothIo ?? this.bluetoothIo,
      fusionConnect: fusionConnect ?? this.fusionConnect,
      gpio: gpio ?? this.gpio,
      hdmiIo: hdmiIo ?? this.hdmiIo,
      usbIoPorts: usbIoPorts ?? this.usbIoPorts,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'aes67': aes67?.toMap(),
      'analog': analog?.toMap(),
      'bluetoothIo': bluetoothIo?.toMap(),
      'fusionConnect': fusionConnect?.toMap(),
      'gpio': gpio?.toMap(),
      'hdmiIo': hdmiIo?.toMap(),
      'usbIoPorts': usbIoPorts?.toMap(),
    };
  }

  factory ProductPortData.fromMap(Map<String, dynamic> map) {
    return ProductPortData(
      aes67: map['aes67'] != null ? Aes67PortData.fromMap(map['aes67'] as Map<String, dynamic>) : null,
      analog: map['analog'] != null ? AnalogPortData.fromMap(map['analog'] as Map<String, dynamic>) : null,
      bluetoothIo: map['bluetoothIo'] != null ? BluetoothPortData.fromMap(map['bluetoothIo'] as Map<String, dynamic>) : null,
      fusionConnect: map['fusionConnect'] != null ? FusionConnectPortData.fromMap(map['fusionConnect'] as Map<String, dynamic>) : null,
      gpio: map['gpio'] != null ? GPIOPortData.fromMap(map['gpio'] as Map<String, dynamic>) : null,
      hdmiIo: map['hdmiIo'] != null ? HdmiPortData.fromMap(map['hdmiIo'] as Map<String, dynamic>) : null,
      usbIoPorts: map['usbIoPorts'] != null ? USBPortData.fromMap(map['usbIoPorts'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductPortData.fromJson(String source) => ProductPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductPortData(aes67: $aes67, analog: $analog, bluetoothIo: $bluetoothIo, fusionConnect: $fusionConnect, gpio: $gpio, hdmiIo: $hdmiIo, usbIoPorts: $usbIoPorts)';
  }

  @override
  bool operator ==(covariant ProductPortData other) {
    if (identical(this, other)) return true;

    return other.aes67 == aes67 &&
        other.analog == analog &&
        other.bluetoothIo == bluetoothIo &&
        other.fusionConnect == fusionConnect &&
        other.gpio == gpio &&
        other.hdmiIo == hdmiIo &&
        other.usbIoPorts == usbIoPorts;
  }

  @override
  int get hashCode {
    return aes67.hashCode ^ analog.hashCode ^ bluetoothIo.hashCode ^ fusionConnect.hashCode ^ gpio.hashCode ^ hdmiIo.hashCode ^ usbIoPorts.hashCode;
  }
}

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

class AnalogPortData {
  final int? inputs;
  final int? inputBalanced;
  final int? inputUnbalanced;
  final int? outputs;
  final int? outputBalanced;
  final int? outputUnbalanced;
  AnalogPortData({
    this.inputs,
    this.inputBalanced,
    this.inputUnbalanced,
    this.outputs,
    this.outputBalanced,
    this.outputUnbalanced,
  });

  AnalogPortData copyWith({
    int? inputs,
    int? inputBalanced,
    int? inputUnbalanced,
    int? outputs,
    int? outputBalanced,
    int? outputUnbalanced,
  }) {
    return AnalogPortData(
      inputs: inputs ?? this.inputs,
      inputBalanced: inputBalanced ?? this.inputBalanced,
      inputUnbalanced: inputUnbalanced ?? this.inputUnbalanced,
      outputs: outputs ?? this.outputs,
      outputBalanced: outputBalanced ?? this.outputBalanced,
      outputUnbalanced: outputUnbalanced ?? this.outputUnbalanced,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
      'input_balanced': inputBalanced,
      'input_unbalanced': inputUnbalanced,
      'outputs': outputs,
      'output_balanced': outputBalanced,
      'output_unbalanced': outputUnbalanced,
    };
  }

  factory AnalogPortData.fromMap(Map<String, dynamic> map) {
    return AnalogPortData(
      inputs: DeserializationUtil.intDeserializer.deserialize(map['inputs']),
      inputBalanced: DeserializationUtil.intDeserializer.deserialize(map['input_balanced']),
      inputUnbalanced: DeserializationUtil.intDeserializer.deserialize(map['input_unbalanced']),
      outputs: DeserializationUtil.intDeserializer.deserialize(map['outputs']),
      outputBalanced: DeserializationUtil.intDeserializer.deserialize(map['output_balanced']),
      outputUnbalanced: DeserializationUtil.intDeserializer.deserialize(map['output_unbalanced']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AnalogPortData.fromJson(String source) => AnalogPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AnalogPortData(inputs: $inputs, inputBalanced: $inputBalanced, inputUnbalanced: $inputUnbalanced, outputs: $outputs, outputBalanced: $outputBalanced, outputUnbalanced: $outputUnbalanced)';
  }

  @override
  bool operator ==(covariant AnalogPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs &&
        other.inputBalanced == inputBalanced &&
        other.inputUnbalanced == inputUnbalanced &&
        other.outputs == outputs &&
        other.outputBalanced == outputBalanced &&
        other.outputUnbalanced == outputUnbalanced;
  }

  @override
  int get hashCode {
    return inputs.hashCode ^ inputBalanced.hashCode ^ inputUnbalanced.hashCode ^ outputs.hashCode ^ outputBalanced.hashCode ^ outputUnbalanced.hashCode;
  }
}

class BluetoothPortData {
  final int? inputs;
  BluetoothPortData({
    this.inputs,
  });

  BluetoothPortData copyWith({
    int? inputs,
  }) {
    return BluetoothPortData(
      inputs: inputs ?? this.inputs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'inputs': inputs,
    };
  }

  factory BluetoothPortData.fromMap(Map<String, dynamic> map) {
    return BluetoothPortData(
      inputs: map['inputs'] != null ? map['inputs'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BluetoothPortData.fromJson(String source) => BluetoothPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BluetoothPortData(inputs: $inputs)';

  @override
  bool operator ==(covariant BluetoothPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs;
  }

  @override
  int get hashCode => inputs.hashCode;
}

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

class GPIOPortData {
  final int? totalGpio;
  final int? assignableInputs;
  final int? assignableOutputs;
  GPIOPortData({
    this.totalGpio,
    this.assignableInputs,
    this.assignableOutputs,
  });
  GPIOPortData copyWith({
    int? totalGpio,
    int? assignableInputs,
    int? assignableOutputs,
  }) {
    return GPIOPortData(
      totalGpio: totalGpio ?? this.totalGpio,
      assignableInputs: assignableInputs ?? this.assignableInputs,
      assignableOutputs: assignableOutputs ?? this.assignableOutputs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total_gpio': totalGpio,
      'assignable_inputs': assignableInputs,
      'assignable_outputs': assignableOutputs,
    };
  }

  factory GPIOPortData.fromMap(Map<String, dynamic> map) {
    return GPIOPortData(
      totalGpio: DeserializationUtil.intDeserializer.deserialize(map['total_gpio']),
      assignableInputs: DeserializationUtil.intDeserializer.deserialize(map['assignable_inputs']),
      assignableOutputs: DeserializationUtil.intDeserializer.deserialize(map['assignable_outputs']),
    );
  }
  String toJson() => json.encode(toMap());
  factory GPIOPortData.fromJson(String source) => GPIOPortData.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() => 'GPIOPortData(totalGpio: $totalGpio, assignableInputs: $assignableInputs, assignableOutputs: $assignableOutputs)';
  @override
  bool operator ==(covariant GPIOPortData other) {
    if (identical(this, other)) return true;
    return other.totalGpio == totalGpio && other.assignableInputs == assignableInputs && other.assignableOutputs == assignableOutputs;
  }

  @override
  int get hashCode => totalGpio.hashCode ^ assignableInputs.hashCode ^ assignableOutputs.hashCode;
}

class HdmiPortData {
  final int? inputs;
  final int? outputs;
  HdmiPortData({
    this.inputs,
    this.outputs,
  });

  HdmiPortData copyWith({
    int? inputs,
    int? outputs,
  }) {
    return HdmiPortData(
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

  factory HdmiPortData.fromMap(Map<String, dynamic> map) {
    return HdmiPortData(
      inputs: map['inputs'] != null ? map['inputs'] as int : null,
      outputs: map['outputs'] != null ? map['outputs'] as int : null,
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

class USBPortData {
  final int? inputs;
  final int? outputs;
  USBPortData({
    this.inputs,
    this.outputs,
  });

  USBPortData copyWith({
    int? inputs,
    int? outputs,
  }) {
    return USBPortData(
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

  factory USBPortData.fromMap(Map<String, dynamic> map) {
    return USBPortData(
      inputs: map['inputs'] != null ? map['inputs'] as int : null,
      outputs: map['outputs'] != null ? map['outputs'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory USBPortData.fromJson(String source) => USBPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'USBPortData(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(covariant USBPortData other) {
    if (identical(this, other)) return true;

    return other.inputs == inputs && other.outputs == outputs;
  }

  @override
  int get hashCode => inputs.hashCode ^ outputs.hashCode;
}

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
