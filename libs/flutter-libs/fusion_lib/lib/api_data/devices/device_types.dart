/// DSP device specifications and data types for API integration

/// DSP device specification containing I/O capabilities
class DeviceSpec {
  final String name;
  final int analogInputs;
  final int analogOutputs;
  final int networkIO; // limit for network I/O handling
  final String imageUrl;

  const DeviceSpec({
    required this.name,
    required this.analogInputs,
    required this.analogOutputs,
    required this.networkIO,
    required this.imageUrl,
  });

  /// Total analog I/O capacity
  int get totalAnalogIO => analogInputs + analogOutputs;

  /// Check if device can handle given analog requirements
  bool canHandle({required int inputs, required int outputs}) {
    return analogInputs >= inputs && analogOutputs >= outputs;
  }

  /// Check if device can handle network I/O requirements
  bool canHandleNetworkIO(int networkIORequired) {
    return networkIO >= networkIORequired;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'analog_inputs': analogInputs,
        'analog_outputs': analogOutputs,
        'network_io': networkIO,
        'total_analog_io': totalAnalogIO,
        'image_url': imageUrl,
      };

  factory DeviceSpec.fromJson(Map<String, dynamic> json) => DeviceSpec(
        name: json['name'] ?? '',
        analogInputs: json['analog_inputs'] ?? 0,
        analogOutputs: json['analog_outputs'] ?? 0,
        networkIO: json['network_io'] ?? 0,
        imageUrl: json['image_url'] ?? '',
      );

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceSpec &&
        other.name == name &&
        other.analogInputs == analogInputs &&
        other.analogOutputs == analogOutputs &&
        other.networkIO == networkIO;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      analogInputs.hashCode ^
      analogOutputs.hashCode ^
      networkIO.hashCode;
}
