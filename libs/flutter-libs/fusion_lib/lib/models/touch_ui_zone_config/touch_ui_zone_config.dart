// ---------------------------------------------------------------------------
// Root model for a TouchUI zone configuration document.
// ---------------------------------------------------------------------------

class TouchUIZoneConfig {
  final List<TouchUIZone> zones;

  const TouchUIZoneConfig({
    this.zones = const [],
  });

  TouchUIZoneConfig copyWith({
    List<TouchUIZone>? zones,
  }) {
    return TouchUIZoneConfig(
      zones: zones ?? this.zones,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'touchui_zone_config': <String, dynamic>{
      'zones': zones.map((z) => z.toJson()).toList(),
    },
  };

  factory TouchUIZoneConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> inner = Map<String, dynamic>.from(json['touchui_zone_config'] as Map);
    return TouchUIZoneConfig(
      zones:
          (inner['zones'] as List<dynamic>?)
              ?.map(
                (e) => TouchUIZone.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }
}

// ---------------------------------------------------------------------------
// Zone
// ---------------------------------------------------------------------------

class TouchUIZone {
  final String zoneId;
  final String zoneName;
  final TouchUIGainConfig gain;
  final List<TouchUIZoneSource> sources;

  const TouchUIZone({
    required this.zoneId,
    required this.zoneName,
    required this.gain,
    this.sources = const [],
  });

  TouchUIZone copyWith({
    String? zoneId,
    String? zoneName,
    TouchUIGainConfig? gain,
    List<TouchUIZoneSource>? sources,
  }) {
    return TouchUIZone(
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      gain: gain ?? this.gain,
      sources: sources ?? this.sources,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'zoneId': zoneId,
    'zoneName': zoneName,
    'gain': gain.toJson(),
    'sources': sources.map((s) => s.toJson()).toList(),
  };

  factory TouchUIZone.fromJson(Map<String, dynamic> json) => TouchUIZone(
    zoneId: json['zoneId'] as String,
    zoneName: json['zoneName'] as String,
    gain: TouchUIGainConfig.fromJson(
      Map<String, dynamic>.from(json['gain'] as Map),
    ),
    sources:
        (json['sources'] as List<dynamic>?)
            ?.map(
              (e) => TouchUIZoneSource.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        const [],
  );
}

// ---------------------------------------------------------------------------
// Gain configuration
// ---------------------------------------------------------------------------

class TouchUIGainConfig {
  final String id;
  final int min;
  final int max;
  final int defGain;
  final bool defMute;

  const TouchUIGainConfig({
    required this.id,
    this.min = 0,
    this.max = 100,
    this.defGain = 50,
    this.defMute = false,
  });

  TouchUIGainConfig copyWith({
    String? id,
    int? min,
    int? max,
    int? defGain,
    bool? defMute,
  }) {
    return TouchUIGainConfig(
      id: id ?? this.id,
      min: min ?? this.min,
      max: max ?? this.max,
      defGain: defGain ?? this.defGain,
      defMute: defMute ?? this.defMute,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'Id': id,
    'Min': min,
    'Max': max,
    'DefGain': defGain,
    'DefMute': defMute,
  };

  factory TouchUIGainConfig.fromJson(Map<String, dynamic> json) => TouchUIGainConfig(
    id: json['Id'] as String,
    min: (json['Min'] as num?)?.toInt() ?? 0,
    max: (json['Max'] as num?)?.toInt() ?? 100,
    defGain: (json['DefGain'] as num?)?.toInt() ?? 50,
    defMute: json['DefMute'] as bool? ?? false,
  );
}

// ---------------------------------------------------------------------------
// Source
// ---------------------------------------------------------------------------

class TouchUIZoneSource {
  final int index;
  final String name;

  const TouchUIZoneSource({
    required this.index,
    required this.name,
  });

  TouchUIZoneSource copyWith({
    int? index,
    String? name,
  }) {
    return TouchUIZoneSource(
      index: index ?? this.index,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'Index': index,
    'Name': name,
  };

  factory TouchUIZoneSource.fromJson(Map<String, dynamic> json) => TouchUIZoneSource(
    index: (json['Index'] as num).toInt(),
    name: json['Name'] as String,
  );
}
