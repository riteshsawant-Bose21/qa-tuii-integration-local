class FirmwareBundle {
  final String id;
  final String version;
  final String approvalStatus;
  final String minPrevVersion;
  final String minDesktopAppVersion;
  final String releaseNotes;
  final String createdAt;
  final String updatedAt;

  FirmwareBundle({
    required this.id,
    required this.version,
    required this.approvalStatus,
    required this.minPrevVersion,
    required this.minDesktopAppVersion,
    required this.releaseNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirmwareBundle.fromJson(Map<String, dynamic> json) {
    return FirmwareBundle(
      id: json['id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? '',
      minPrevVersion: json['min_prev_version'] as String? ?? '',
      minDesktopAppVersion: json['min_desktop_app_version'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class FirmwareBundlesResponse {
  final List<FirmwareBundle> bundles;
  final int page;
  final int limit;
  final int total;

  FirmwareBundlesResponse({
    required this.bundles,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory FirmwareBundlesResponse.fromJson(Map<String, dynamic> json) {
    final bundlesJson = json['bundles'] as List<dynamic>? ?? [];
    return FirmwareBundlesResponse(
      bundles: bundlesJson
          .map((b) => FirmwareBundle.fromJson(b as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
    );
  }
}
