class Device {
  final String name;
  final String deviceId;
  final String project;
  final String location;
  final String model;
  final String type;
  final String status;
  final int incidents;
  final String image;
  final String lastSeen;

  Device({
    required this.name,
    required this.deviceId,
    required this.project,
    required this.model,
    required this.location,
    required this.type,
    required this.status,
    required this.incidents,
    required this.image,
    required this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      project: json['projectName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      type: json['deviceType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      incidents: json['incidents'] ?? 0,
      image: json['image']?.toString() ?? '',
      lastSeen: json['lastSeen']?.toString() ?? '',
    );
  }
}

class DevicesModel {
  final int total;
  final int healthy;
  final int critical;
  final int inactive;
  final List<Device> devices;

  DevicesModel({
    required this.total,
    required this.healthy,
    required this.critical,
    required this.inactive,
    required this.devices,
  });

  factory DevicesModel.fromJson(Map<String, dynamic> json) {
    return DevicesModel(
      total: json['total'] ?? 0,
      healthy: json['healthy'] ?? 0,
      critical: json['critical'] ?? 0,
      inactive: json['inactive'] ?? 0,
      devices: (json['devices'] as List? ?? [])
          .map((e) => Device.fromJson(e))
          .toList(),
    );
  }

  DevicesModel copyWith({
    int? total,
    int? healthy,
    int? critical,
    int? inactive,
    List<Device>? devices,
  }) {
    return DevicesModel(
      total: total ?? this.total,
      healthy: healthy ?? this.healthy,
      critical: critical ?? this.critical,
      inactive: inactive ?? this.inactive,
      devices: devices ?? this.devices,
    );
  }
}
