/// Model for project devices (devices in your project)
class ProjectDevice {
  final String id;
  final String name;
  final String location;
  String? assignedHardwareId;

  ProjectDevice({
    required this.id,
    required this.name,
    required this.location,
    this.assignedHardwareId,
  });

  ProjectDevice copyWith({
    String? id,
    String? name,
    String? location,
    String? assignedHardwareId,
  }) {
    return ProjectDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      assignedHardwareId: assignedHardwareId ?? this.assignedHardwareId,
    );
  }
}

/// Model for network hardware (physical devices discovered on network)
class NetworkHardware {
  final String id;
  final String modelName;
  final String ipAddress;
  final String firmware;
  String? assignedToDeviceId;

  NetworkHardware({
    required this.id,
    required this.modelName,
    required this.ipAddress,
    required this.firmware,
    this.assignedToDeviceId,
  });

  NetworkHardware copyWith({
    String? id,
    String? modelName,
    String? ipAddress,
    String? firmware,
    String? assignedToDeviceId,
  }) {
    return NetworkHardware(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      ipAddress: ipAddress ?? this.ipAddress,
      firmware: firmware ?? this.firmware,
      assignedToDeviceId: assignedToDeviceId ?? this.assignedToDeviceId,
    );
  }

  factory NetworkHardware.empty() {
    return NetworkHardware(
      id: '',
      modelName: '--',
      ipAddress: '--',
      firmware: '--',
    );
  }

  bool get isEmpty => id.isEmpty;
}
