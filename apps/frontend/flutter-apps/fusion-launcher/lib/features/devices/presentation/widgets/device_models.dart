enum NetworkHardwareType {
  dsp,
  amplifier,
  controller,
  endpoint,
}

/// Model for network hardware (physical devices discovered on network)
class NetworkHardware {
  final String id;
  final String modelName;
  final String deviceName;
  final String ipAddress;
  final String firmware;
  final NetworkHardwareType? type;
  String? assignedToDeviceId;

  NetworkHardware({
    required this.id,
    required this.modelName,
    required this.deviceName,
    required this.ipAddress,
    required this.firmware,
    required this.type,
    this.assignedToDeviceId,
  });

  NetworkHardware copyWith({
    String? id,
    String? modelName,
    String? deviceName,
    String? ipAddress,
    String? firmware,
    NetworkHardwareType? type,
    String? assignedToDeviceId,
  }) {
    return NetworkHardware(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      firmware: firmware ?? this.firmware,
      type: type ?? this.type,
      assignedToDeviceId: assignedToDeviceId ?? this.assignedToDeviceId,
    );
  }

  factory NetworkHardware.empty() {
    return NetworkHardware(
      id: '',
      modelName: '--',
      deviceName: '--',
      ipAddress: '--',
      type: null,
      firmware: '--',
    );
  }

  bool get isEmpty => id.isEmpty;
}
