/// Root model for a wall-controller configuration document.
class WallControllerConfig {
  final List<WallController> controllers;
  final List<WallZone> zones;

  const WallControllerConfig({
    this.controllers = const [],
    this.zones = const [],
  });

  WallControllerConfig copyWith({
    List<WallController>? controllers,
    List<WallZone>? zones,
  }) {
    return WallControllerConfig(
      controllers: controllers ?? this.controllers,
      zones: zones ?? this.zones,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'wall_controller_config': <String, dynamic>{
      'controllers': controllers.map((c) => c.toJson()).toList(),
      'zones': zones.map((z) => z.toJson()).toList(),
    },
  };

  factory WallControllerConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> inner = Map<String, dynamic>.from(json['wall_controller_config'] as Map);
    return WallControllerConfig(
      controllers: (inner['controllers'] as List<dynamic>?)?.map((e) => WallController.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
      zones: (inner['zones'] as List<dynamic>?)?.map((e) => WallZone.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class WallController {
  final String id;
  final String name;
  final List<String> zoneIds;

  const WallController({
    required this.id,
    required this.name,
    this.zoneIds = const [],
  });

  WallController copyWith({
    String? id,
    String? name,
    List<String>? zoneIds,
  }) {
    return WallController(
      id: id ?? this.id,
      name: name ?? this.name,
      zoneIds: zoneIds ?? this.zoneIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'zoneIds': zoneIds,
  };

  factory WallController.fromJson(Map<String, dynamic> json) => WallController(
    id: json['id'] as String,
    name: json['name'] as String,
    zoneIds: (json['zoneIds'] as List<dynamic>?)?.cast<String>() ?? const [],
  );
}

// ---------------------------------------------------------------------------
// Zone
// ---------------------------------------------------------------------------

class WallZone {
  final String id;
  final String name;
  final WallGainConfig gain;
  final WallZoneOno ono;
  final List<WallZoneSource> sources;
  final List<WallSubZone> subZones;

  const WallZone({
    required this.id,
    required this.name,
    required this.gain,
    required this.ono,
    this.sources = const [],
    this.subZones = const [],
  });

  WallZone copyWith({
    String? id,
    String? name,
    WallGainConfig? gain,
    WallZoneOno? ono,
    List<WallZoneSource>? sources,
    List<WallSubZone>? subZones,
  }) {
    return WallZone(
      id: id ?? this.id,
      name: name ?? this.name,
      gain: gain ?? this.gain,
      ono: ono ?? this.ono,
      sources: sources ?? this.sources,
      subZones: subZones ?? this.subZones,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'gain': gain.toJson(),
    'ono': ono.toJson(),
    'sources': sources.map((s) => s.toJson()).toList(),
    'subZones': subZones.map((sz) => sz.toJson()).toList(),
  };

  factory WallZone.fromJson(Map<String, dynamic> json) => WallZone(
    id: json['id'] as String,
    name: json['name'] as String,
    gain: WallGainConfig.fromJson(Map<String, dynamic>.from(json['gain'] as Map)),
    ono: WallZoneOno.fromJson(Map<String, dynamic>.from(json['ono'] as Map)),
    sources: (json['sources'] as List<dynamic>?)?.map((e) => WallZoneSource.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
    subZones: (json['subZones'] as List<dynamic>?)?.map((e) => WallSubZone.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
  );
}

// ---------------------------------------------------------------------------
// Shared ONO counter
//
// All ono auto-assignments (zones and sub-zones) draw from a single
// monotonically-increasing pool so that every object number is unique within
// a project.
//
//   Zone     consumes 4 numbers: zone, gain, mute, sourceSelector
//   SubZone  consumes 3 numbers: subZone, gain, mute
//
// Use [resetOnoCounter()] to restart numbering (e.g. when loading a fresh
// project).
// ---------------------------------------------------------------------------

int _onoCounter = 8001;

/// Restart the shared ONO counter (e.g. at the start of a new project).
void resetOnoCounter([int startValue = 8001]) => _onoCounter = startValue;

/// Current value of the shared ONO counter (read-only convenience getter).
int get currentOnoCounter => _onoCounter;

// ---------------------------------------------------------------------------
// WallZoneOno – 4 consecutive numbers per zone
// ---------------------------------------------------------------------------

class WallZoneOno {
  /// Restart the global ONO counter (e.g. at the start of a new project).
  /// Prefer the top-level [resetOnoCounter] instead.
  static void resetCounter([int startValue = 8001]) => resetOnoCounter(startValue);

  /// Current value of the counter (read-only convenience getter).
  static int get currentCounter => currentOnoCounter;

  final int zone;
  final int gain;
  final int mute;
  final int sourceSelector;

  const WallZoneOno._({
    required this.zone,
    required this.gain,
    required this.mute,
    required this.sourceSelector,
  });

  /// Creates an [WallZoneOno] whose numbers are auto-assigned from the
  /// shared counter and advances the counter by 4.
  factory WallZoneOno.autoAssign() {
    final int base = _onoCounter;
    _onoCounter += 4;
    return WallZoneOno._(
      zone: base,
      gain: base + 1,
      mute: base + 2,
      sourceSelector: base + 3,
    );
  }

  /// Creates an [WallZoneOno] with explicit values (used during deserialization).
  factory WallZoneOno({
    required int zone,
    required int gain,
    required int mute,
    required int sourceSelector,
  }) = WallZoneOno._;

  WallZoneOno copyWith({
    int? zone,
    int? gain,
    int? mute,
    int? sourceSelector,
  }) {
    return WallZoneOno._(
      zone: zone ?? this.zone,
      gain: gain ?? this.gain,
      mute: mute ?? this.mute,
      sourceSelector: sourceSelector ?? this.sourceSelector,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'zone': zone,
    'gain': gain,
    'mute': mute,
    'sourceSelector': sourceSelector,
  };

  factory WallZoneOno.fromJson(Map<String, dynamic> json) => WallZoneOno._(
    zone: (json['zone'] as num).toInt(),
    gain: (json['gain'] as num).toInt(),
    mute: (json['mute'] as num).toInt(),
    sourceSelector: (json['sourceSelector'] as num).toInt(),
  );
}

// ---------------------------------------------------------------------------
// WallSubZoneOno – 3 consecutive numbers per sub-zone
// ---------------------------------------------------------------------------

class WallSubZoneOno {
  final int subZone;
  final int gain;
  final int mute;

  const WallSubZoneOno._({
    required this.subZone,
    required this.gain,
    required this.mute,
  });

  /// Creates a [WallSubZoneOno] whose numbers are auto-assigned from the
  /// shared counter and advances the counter by 3.
  factory WallSubZoneOno.autoAssign() {
    final int base = _onoCounter;
    _onoCounter += 3;
    return WallSubZoneOno._(
      subZone: base,
      gain: base + 1,
      mute: base + 2,
    );
  }

  /// Creates a [WallSubZoneOno] with explicit values (used during deserialization).
  factory WallSubZoneOno({
    required int subZone,
    required int gain,
    required int mute,
  }) = WallSubZoneOno._;

  WallSubZoneOno copyWith({
    int? subZone,
    int? gain,
    int? mute,
  }) {
    return WallSubZoneOno._(
      subZone: subZone ?? this.subZone,
      gain: gain ?? this.gain,
      mute: mute ?? this.mute,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'subZone': subZone,
    'gain': gain,
    'mute': mute,
  };

  factory WallSubZoneOno.fromJson(Map<String, dynamic> json) => WallSubZoneOno._(
    subZone: (json['subZone'] as num).toInt(),
    gain: (json['gain'] as num).toInt(),
    mute: (json['mute'] as num).toInt(),
  );
}

// ---------------------------------------------------------------------------
// Gain configuration
// ---------------------------------------------------------------------------

class WallGainConfig {
  final String gainID;
  final String defaultGainValue;
  final String defaultMuteValue;
  final String minValue;
  final String maxValue;

  const WallGainConfig({
    required this.gainID,
    this.defaultGainValue = '50',
    this.defaultMuteValue = '50',
    this.minValue = '0',
    this.maxValue = '100',
  });

  WallGainConfig copyWith({
    String? gainID,
    String? defaultGainValue,
    String? defaultMuteValue,
    String? minValue,
    String? maxValue,
  }) {
    return WallGainConfig(
      gainID: gainID ?? this.gainID,
      defaultGainValue: defaultGainValue ?? this.defaultGainValue,
      defaultMuteValue: defaultMuteValue ?? this.defaultMuteValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'gainID': gainID,
    'default_gain_value': defaultGainValue,
    'default_mute_value': defaultMuteValue,
    'min_value': minValue,
    'max_value': maxValue,
  };

  factory WallGainConfig.fromJson(Map<String, dynamic> json) => WallGainConfig(
    gainID: json['gainID'] as String,
    defaultGainValue: json['default_gain_value'] as String? ?? '50',
    defaultMuteValue: json['default_mute_value'] as String? ?? '50',
    minValue: json['min_value'] as String? ?? '0',
    maxValue: json['max_value'] as String? ?? '100',
  );
}

// ---------------------------------------------------------------------------
// Source
// ---------------------------------------------------------------------------

class WallZoneSource {
  final int index;
  final String sourceId;
  final String sourceName;

  const WallZoneSource({
    required this.index,
    required this.sourceId,
    required this.sourceName,
  });

  WallZoneSource copyWith({
    int? index,
    String? sourceId,
    String? sourceName,
  }) {
    return WallZoneSource(
      index: index ?? this.index,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'index': index,
    'sourceId': sourceId,
    'sourceName': sourceName,
  };

  factory WallZoneSource.fromJson(Map<String, dynamic> json) => WallZoneSource(
    index: (json['index'] as num).toInt(),
    sourceId: json['sourceId'] as String,
    sourceName: json['sourceName'] as String,
  );
}

// ---------------------------------------------------------------------------
// SubZone
// ---------------------------------------------------------------------------

class WallSubZone {
  final String id;
  final String name;
  final WallGainConfig gain;
  final WallSubZoneOno ono;

  const WallSubZone({
    required this.id,
    required this.name,
    required this.gain,
    required this.ono,
  });

  WallSubZone copyWith({
    String? id,
    String? name,
    WallGainConfig? gain,
    WallSubZoneOno? ono,
  }) {
    return WallSubZone(
      id: id ?? this.id,
      name: name ?? this.name,
      gain: gain ?? this.gain,
      ono: ono ?? this.ono,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'gain': gain.toJson(),
    'ono': ono.toJson(),
  };

  factory WallSubZone.fromJson(Map<String, dynamic> json) => WallSubZone(
    id: json['id'] as String,
    name: json['name'] as String,
    gain: WallGainConfig.fromJson(Map<String, dynamic>.from(json['gain'] as Map)),
    ono: WallSubZoneOno.fromJson(Map<String, dynamic>.from(json['ono'] as Map)),
  );
}
