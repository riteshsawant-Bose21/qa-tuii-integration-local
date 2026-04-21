class SnapshotsRequestDto {
  final List<SnapshotItemDto> snapshots;

  SnapshotsRequestDto({required this.snapshots});

  factory SnapshotsRequestDto.fromJson(List<dynamic> json) {
    return SnapshotsRequestDto(
      snapshots: json.map((dynamic item) => SnapshotItemDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'snapshots': snapshots.map((SnapshotItemDto item) => item.toJson()).toList(),
    };
  }

  SnapshotsRequestDto copyWith({List<SnapshotItemDto>? snapshots}) {
    return SnapshotsRequestDto(snapshots: snapshots ?? this.snapshots);
  }

  @override
  String toString() => 'SnapshotsRequest(snapshots: $snapshots)';
}

/// Represents a single snapshot item with id, name, and data.
class SnapshotItemDto {
  final String id;
  final String name;
  final SnapshotDataDto data;

  SnapshotItemDto({
    required this.id,
    required this.name,
    required this.data,
  });

  factory SnapshotItemDto.fromJson(Map<String, dynamic> json) {
    return SnapshotItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      data: SnapshotDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'data': data.toJson(),
    };
  }

  SnapshotItemDto copyWith({
    String? id,
    String? name,
    SnapshotDataDto? data,
  }) {
    return SnapshotItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'SnapshotItem(id: $id, name: $name, data: $data)';
}

/// Represents the data object containing settings.
class SnapshotDataDto {
  final SnapshotSettingsDto settings;

  SnapshotDataDto({required this.settings});

  factory SnapshotDataDto.fromJson(Map<String, dynamic> json) {
    return SnapshotDataDto(
      settings: SnapshotSettingsDto.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'settings': settings.toJson(),
    };
  }

  SnapshotDataDto copyWith({SnapshotSettingsDto? settings}) {
    return SnapshotDataDto(settings: settings ?? this.settings);
  }

  @override
  String toString() => 'SnapshotData(settings: $settings)';
}

/// Represents the settings object containing dynamic audio configurations.
///
/// The audio map is completely dynamic - keys can be any device ID and
/// values can be any configuration map.
class SnapshotSettingsDto {
  /// Dynamic audio configuration map.
  /// Key: Device ID (e.g., "GAIN67622359", "FUCNC12244")
  /// Value: Device configuration as dynamic map (e.g., {"gain": -32, "mute": true})
  final Map<String, dynamic> audio;

  SnapshotSettingsDto({required this.audio});

  factory SnapshotSettingsDto.fromJson(Map<String, dynamic> json) {
    return SnapshotSettingsDto(
      audio: json['audio'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'audio': audio,
    };
  }

  SnapshotSettingsDto copyWith({Map<String, dynamic>? audio}) {
    return SnapshotSettingsDto(audio: audio ?? this.audio);
  }

  /// Get configuration for a specific device by ID.
  Map<String, dynamic>? getDeviceConfig(String deviceId) {
    final dynamic config = audio[deviceId];
    if (config is Map<String, dynamic>) {
      return config;
    }
    return null;
  }

  /// Get all device IDs in this audio configuration.
  List<String> get deviceIds => audio.keys.toList();

  @override
  String toString() => 'SnapshotSettings(audio: $audio)';
}
