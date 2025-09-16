/// DSP device specifications and data types for API integration

/// DSP device specification containing I/O capabilities
class DeviceSpec {
  final String name;
  final int analogInputs;
  final int analogOutputs;
  final int networkInputs; // network input capacity
  final int networkOutputs; // network output capacity
  final String imageUrl;
  final double price;

  const DeviceSpec({
    required this.name,
    required this.analogInputs,
    required this.analogOutputs,
    required this.networkInputs,
    required this.networkOutputs,
    required this.imageUrl,
    this.price = 0.0,
  });

  /// Total analog I/O capacity
  int get totalAnalogIO => analogInputs + analogOutputs;

  /// Total network I/O capacity
  int get totalNetworkIO => networkInputs + networkOutputs;

  /// Check if device can handle given analog requirements
  bool canHandle({required int inputs, required int outputs}) {
    return analogInputs >= inputs && analogOutputs >= outputs;
  }

  /// Check if device can handle network I/O requirements
  bool canHandleNetworkIO({required int inputs, required int outputs}) {
    return networkInputs >= inputs && networkOutputs >= outputs;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'analog_inputs': analogInputs,
        'analog_outputs': analogOutputs,
        'network_inputs': networkInputs,
        'network_outputs': networkOutputs,
        'total_analog_io': totalAnalogIO,
        'total_network_io': totalNetworkIO,
        'image_url': imageUrl,
        'price': price,
      };

  factory DeviceSpec.fromJson(Map<String, dynamic> json) => DeviceSpec(
        name: json['name'] ?? '',
        analogInputs: json['analog_inputs'] ?? 0,
        analogOutputs: json['analog_outputs'] ?? 0,
        networkInputs: json['network_inputs'] ?? 0,
        networkOutputs: json['network_outputs'] ?? 0,
        imageUrl: json['image_url'] ?? '',
        price: json['price'] ?? 0.0,
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
        other.networkInputs == networkInputs &&
        other.networkOutputs == networkOutputs &&
        other.price == price;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      analogInputs.hashCode ^
      analogOutputs.hashCode ^
      networkInputs.hashCode ^
      networkOutputs.hashCode ^
      price.hashCode;
}
