class Device {
  final String name;
  final String serialNumber;
  final String deviceId;
  final String project;
  final String location;
  final String model;
  final String type;
  final String status;
  final int incidents;
  final String image;
  final String lastSeen;
  final String zone;
  final String equipmentLocation;
  final String firmware;
  final String macAddress;
  final bool online;
  final int temperature;
  final int cpuUsage;
  final int memoryUsage;
  final String deviceType;


  Device({
    required this.name,
    required this.serialNumber,
    required this.deviceId,
    required this.project,
    required this.model,
    required this.location,
    required this.type,
    required this.status,
    required this.incidents,
    required this.image,
    required this.lastSeen,
    required this.zone,
    required this.equipmentLocation,
    required this.firmware,
    required this.macAddress,
    required this.online,
    required this.temperature,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.deviceType,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      type: json['deviceType']?.toString() ?? '',
      project: json['projectName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      equipmentLocation: json['equipmentLocation']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      lastSeen: json['lastSeen']?.toString() ?? '',
      firmware: json['firmware']?.toString() ?? '',
      macAddress: json['macAddress']?.toString() ?? '',
      incidents: json['incidents'] ?? 0,
      online: json['online'] ?? "öffline",
      temperature: json['temperature'] ?? 0,
      cpuUsage: json['cpuUsage'] ?? 0,
      memoryUsage: json['storageUsage'] ?? 0,
      deviceType: json['macAddress']?.toString() ?? '',
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
