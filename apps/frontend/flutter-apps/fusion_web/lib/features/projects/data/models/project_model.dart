import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.description,
    required super.clientName,
    required super.region,
    required super.status,
    required super.healthyDevices,
    required super.warningDevices,
    required super.criticalDevices,
    required super.incidents,
    required super.lastUpdated,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return ProjectModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clientName: json['client_name'] ?? '',
      region: json['region'] ?? '',
      status: json['status'] ?? 'active',
      healthyDevices: parseInt(json['healthy_devices']),
      warningDevices: parseInt(json['warning_devices']),
      criticalDevices: parseInt(json['critical_devices']),
      incidents: parseInt(json['incidents']),
      lastUpdated: parseDateTime(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'client_name': clientName,
      'region': region,
      'status': status,
      'healthy_devices': healthyDevices,
      'warning_devices': warningDevices,
      'critical_devices': criticalDevices,
      'incidents': incidents,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  static List<ProjectModel> mockProjects() {
    return [
      ProjectModel(
        id: '1',
        title: 'Skyline Resort & Spa',
        description: 'Multi-zone audio system for resort property.',
        clientName: 'Skyline Hotels',
        region: 'North America',
        status: 'active',
        healthyDevices: 56,
        warningDevices: 4,
        criticalDevices: 2,
        incidents: 3,
        lastUpdated: DateTime(2026, 2, 6),
      ),
      ProjectModel(
        id: '2',
        title: 'Government Building Retrofit',
        description: 'Audio infrastructure upgrade for government facility.',
        clientName: 'ProAudio Distribution NA',
        region: 'North America',
        status: 'active',
        healthyDevices: 60,
        warningDevices: 0,
        criticalDevices: 0,
        incidents: 0,
        lastUpdated: DateTime(2026, 2, 5),
      ),
      ProjectModel(
        id: '3',
        title: 'Metro University Campus Audio',
        description: 'Campus-wide distributed audio solution.',
        clientName: 'Metro University',
        region: 'North America',
        status: 'active',
        healthyDevices: 78,
        warningDevices: 2,
        criticalDevices: 0,
        incidents: 1,
        lastUpdated: DateTime(2026, 2, 5),
      ),
      ProjectModel(
        id: '4',
        title: 'Global Retail - London Flagship',
        description: 'Retail flagship audio deployment.',
        clientName: 'Global Retail Chain',
        region: 'Europe',
        status: 'active',
        healthyDevices: 32,
        warningDevices: 1,
        criticalDevices: 0,
        incidents: 0,
        lastUpdated: DateTime(2026, 2, 4),
      ),
      ProjectModel(
        id: '5',
        title: 'Global Retail - Paris Store',
        description: 'Retail audio installation for Paris store.',
        clientName: 'Global Retail Chain',
        region: 'Europe',
        status: 'active',
        healthyDevices: 28,
        warningDevices: 2,
        criticalDevices: 1,
        incidents: 1,
        lastUpdated: DateTime(2026, 2, 4),
      ),
      ProjectModel(
        id: '6',
        title: 'Skyline Downtown Conference Center',
        description: 'Conference center multi-zone audio system.',
        clientName: 'Skyline Hotels',
        region: 'North America',
        status: 'active',
        healthyDevices: 45,
        warningDevices: 3,
        criticalDevices: 1,
        incidents: 2,
        lastUpdated: DateTime(2026, 2, 3),
      ),
      ProjectModel(
        id: '7',
        title: 'Corporate HQ Pilot Program',
        description: 'Pilot deployment at corporate headquarters.',
        clientName: 'Bose Professional',
        region: 'North America',
        status: 'active',
        healthyDevices: 12,
        warningDevices: 0,
        criticalDevices: 0,
        incidents: 0,
        lastUpdated: DateTime(2026, 2, 1),
      ),
      ProjectModel(
        id: '8',
        title: 'Regional Theater Complex',
        description: 'Full theater audio system implementation.',
        clientName: 'SoundTech Solutions',
        region: 'North America',
        status: 'completed',
        healthyDevices: 64,
        warningDevices: 0,
        criticalDevices: 0,
        incidents: 0,
        lastUpdated: DateTime(2025, 12, 15),
      ),
    ];
  }
}
