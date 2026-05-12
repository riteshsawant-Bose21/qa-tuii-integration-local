class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String clientName;
  final String region;   // indoor / outdoor / hybrid
  final String status;   // Proposal / Development / Commissioned

  final int healthyDevices;
  final int warningDevices;
  final int criticalDevices;
  final int incidents;

  final DateTime lastUpdated;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.clientName,
    required this.region,
    required this.status,
    required this.healthyDevices,
    required this.warningDevices,
    required this.criticalDevices,
    required this.incidents,
    required this.lastUpdated,
  });

  // ---------------------------
  // FROM JSON (API → APP)
  // ---------------------------

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ProjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      clientName: json['venue'] ?? '',
      region: json['environment_type'] ?? '',
      status: json['project_phase'] ?? '',
      lastUpdated: parseDateTime(json['updated_at']),
      healthyDevices: 0,
      warningDevices: 0,
      criticalDevices: 0,
      incidents: 0,
    );
  }

  // ---------------------------
  // COPY WITH
  // ---------------------------

  ProjectModel copyWith({
    String? name,
    String? description,
    String? clientName,
    String? region,
    String? status,
    int? healthyDevices,
    int? warningDevices,
    int? criticalDevices,
    int? incidents,
    DateTime? lastUpdated,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      region: region ?? this.region,
      status: status ?? this.status,
      healthyDevices: healthyDevices ?? this.healthyDevices,
      warningDevices: warningDevices ?? this.warningDevices,
      criticalDevices: criticalDevices ?? this.criticalDevices,
      incidents: incidents ?? this.incidents,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ---------------------------
  // SAFE NORMALIZATION HELPERS
  // ---------------------------

  String _safeProjectPhase(String value) {
    switch (value.toLowerCase()) {
      case "proposal":
        return "Proposal";
      case "development":
        return "Development";
      case "commissioned":
        return "Commissioned";
      default:
        return "Proposal"; // fallback prevents 400 error
    }
  }

  String _safeEnvironment(String value) {
    switch (value.toLowerCase()) {
      case "indoor":
        return "indoor";
      case "outdoor":
        return "outdoor";
      case "hybrid":
        return "hybrid";
      default:
        return "indoor"; // fallback prevents 400 error
    }
  }

  // ---------------------------
  // TO JSON (APP → API)
  // ---------------------------

  Map<String, dynamic> toJson() {
    return {
      "project_id": id.isEmpty
          ? "50000001-0000-4000-8000-000000000008"
          : id,
      "name": name.isEmpty
          ? "Lollapalooza Stadium Concert Audio System"
          : name,
      "description": description.isEmpty
          ? "Designing a state-of-the-art audio system for a large stadium concert."
          : description,
      "venue": clientName.isEmpty
          ? "Grant Park, Chicago"
          : clientName,
      "application": "Audio System Design",
      "environment_type": _safeEnvironment(region),
      "project_phase": _safeProjectPhase(status),
      "is_project_file_created": false,
      "is_project_thumbnail_created": false,
      "budget": {
        "amount": 50000,
        "currency": "USD",
      },
    };
  }

  // ---------------------------
  // MOCK DATA
  // ---------------------------

  static List<ProjectModel> mockProjects() {
    return [
      ProjectModel(
        id: '1',
        name: 'Mock Project',
        description: 'Temporary mock data',
        clientName: 'Mock Venue',
        region: 'indoor',
        status: 'Development',
        healthyDevices: 10,
        warningDevices: 2,
        criticalDevices: 1,
        incidents: 1,
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}