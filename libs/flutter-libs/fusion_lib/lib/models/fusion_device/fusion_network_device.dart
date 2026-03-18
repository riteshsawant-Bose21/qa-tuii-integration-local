/// Model class representing a Fusion network device discovered on the network.
class FusionNetworkDevice {
  /// The IP address of the device.
  final String address;

  /// The unique identifier for this device instance.
  final String id;

  /// The location of the device (can be empty).
  final String location;

  /// The name of the device.
  final String name;

  /// the model name of the device
  final String modelName;

  /// The Xyte cloud identifier (can be empty).
  final String xyteCloudId;

  /// Whether the device has been claimed.
  final bool isClaimed;

  /// The serial number of the device.
  final String serialNumber;

  /// Whether this device is the primary device.
  final bool isPrimary;

  const FusionNetworkDevice({
    required this.address,
    required this.id,
    this.location = '',
    required this.name,
    this.modelName = 'FM8Y',
    this.xyteCloudId = '',
    this.isClaimed = false,
    required this.serialNumber,
    this.isPrimary = false,
  });

  factory FusionNetworkDevice.fromJson(Map<String, dynamic> json) {
    return FusionNetworkDevice(
      address: json['address'] as String? ?? '',
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      name: json['name'] as String? ?? '',
      // modelName: json['model_name'] as String? ?? 'FM8Y',
      modelName: 'FM8Y', //using this as we dont have model name in the api currently
      xyteCloudId: json['xyte_cloud_id'] as String? ?? '',
      isClaimed: json['is_claimed'] as bool? ?? false,
      serialNumber: json['serial_number'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'id': id,
      'location': location,
      'name': name,
      'model_name': modelName,
      'xyte_cloud_id': xyteCloudId,
      'is_claimed': isClaimed,
      'serial_number': serialNumber,
      'is_primary': isPrimary,
    };
  }

  FusionNetworkDevice copyWith({
    String? address,
    String? id,
    String? location,
    String? name,
    String? modelName,
    String? xyteCloudId,
    bool? isClaimed,
    String? serialNumber,
    bool? isPrimary,
  }) {
    return FusionNetworkDevice(
      address: address ?? this.address,
      id: id ?? this.id,
      location: location ?? this.location,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      xyteCloudId: xyteCloudId ?? this.xyteCloudId,
      isClaimed: isClaimed ?? this.isClaimed,
      serialNumber: serialNumber ?? this.serialNumber,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  String toString() {
    return 'FusionNetworkDevice(address: $address, id: $id, name: $name, model_name: $modelName ,  serialNumber: $serialNumber, isPrimary: $isPrimary, isClaimed: $isClaimed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FusionNetworkDevice &&
        other.address == address &&
        other.id == id &&
        other.location == location &&
        other.name == name &&
        other.modelName == modelName &&
        other.xyteCloudId == xyteCloudId &&
        other.isClaimed == isClaimed &&
        other.serialNumber == serialNumber &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return Object.hash(
      address,
      id,
      location,
      name,
      modelName,
      xyteCloudId,
      isClaimed,
      serialNumber,
      isPrimary,
    );
  }
}
