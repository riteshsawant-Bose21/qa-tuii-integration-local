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

  /// Controller type: 'pro' or 'lt'.
  final String type;
  final List<String> zoneIds;
  final List<WallPages> pages;
  final WallControllerSchedule schedule;

  const WallController({
    required this.id,
    required this.name,
    this.type = 'lt',
    this.zoneIds = const [],
    this.pages = const [],
    this.schedule = const WallControllerSchedule(),
  });

  WallController copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? zoneIds,
    List<WallPages>? pages,
    WallControllerSchedule? schedule,
  }) {
    return WallController(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      zoneIds: zoneIds ?? this.zoneIds,
      pages: pages ?? this.pages,
      schedule: schedule ?? this.schedule,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'zoneIds': zoneIds,
    'pages': pages.map((p) => p.toJson()).toList(),
    'schedule': schedule.toJson(),
  };

  factory WallController.fromJson(Map<String, dynamic> json) => WallController(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String? ?? 'lt',
    zoneIds: (json['zoneIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    pages: (json['pages'] as List<dynamic>?)?.map((e) => WallPages.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
    schedule: json['schedule'] != null ? WallControllerSchedule.fromJson(Map<String, dynamic>.from(json['schedule'] as Map)) : const WallControllerSchedule(),
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
  final String? functionId;
  final List<WallZoneSource> sources;
  final List<WallSubZone> subZones;

  WallZone({
    required this.id,
    required this.name,
    required this.gain,
    required this.ono,
    required this.functionId,
    this.sources = const [],
    this.subZones = const [],
  });

  WallZone copyWith({
    String? id,
    String? name,
    WallGainConfig? gain,
    WallZoneOno? ono,
    String? functionId,
    List<WallZoneSource>? sources,
    List<WallSubZone>? subZones,
  }) {
    return WallZone(
      id: id ?? this.id,
      name: name ?? this.name,
      gain: gain ?? this.gain,
      ono: ono ?? this.ono,
      functionId: functionId ?? this.functionId,
      sources: sources ?? this.sources,
      subZones: subZones ?? this.subZones,
    );
  }

  int sourceSelected = 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'gain': gain.toJson(),
    'ono': ono.toJson(),
    'functionId': functionId,
    'sources': sources.map((s) => s.toJson()).toList(),
    'subZones': subZones.map((sz) => sz.toJson()).toList(),
  };

  factory WallZone.fromJson(Map<String, dynamic> json) => WallZone(
    id: json['id'] as String,
    name: json['name'] as String,
    gain: WallGainConfig.fromJson(Map<String, dynamic>.from(json['gain'] as Map)),
    ono: WallZoneOno.fromJson(Map<String, dynamic>.from(json['ono'] as Map)),
    functionId: json['functionId'] as String?,
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
    this.defaultGainValue = '0',
    this.defaultMuteValue = '0',
    this.minValue = '-60',
    this.maxValue = '12',
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

// ---------------------------------------------------------------------------
// WallControllerSchedule – schedule config embedded in WallController
// ---------------------------------------------------------------------------

class WallControllerSchedule {
  /// 'none' | 'all' | 'selected'
  final String displayMode;

  /// Whether "Show upcoming items" is enabled.
  final bool showUpcoming;

  /// Schedule IDs selected when displayMode is 'selected'.
  final List<String> selectedScheduleIds;

  const WallControllerSchedule({
    this.displayMode = 'all',
    this.showUpcoming = false,
    this.selectedScheduleIds = const [],
  });

  WallControllerSchedule copyWith({
    String? displayMode,
    bool? showUpcoming,
    List<String>? selectedScheduleIds,
  }) {
    return WallControllerSchedule(
      displayMode: displayMode ?? this.displayMode,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      selectedScheduleIds: selectedScheduleIds ?? this.selectedScheduleIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'displayMode': displayMode,
    'showUpcoming': showUpcoming,
    'selectedScheduleIds': selectedScheduleIds,
  };

  factory WallControllerSchedule.fromJson(Map<String, dynamic> json) => WallControllerSchedule(
    displayMode: json['displayMode'] as String? ?? 'all',
    showUpcoming: json['showUpcoming'] as bool? ?? false,
    selectedScheduleIds: (json['selectedScheduleIds'] as List<dynamic>?)?.cast<String>() ?? const [],
  );
}

// ---------------------------------------------------------------------------
// WallPageSnapshot – a snapshot/scene reference inside a WallPages entry
// ---------------------------------------------------------------------------

class WallPageSnapshot {
  final String id;
  final String name;

  const WallPageSnapshot({
    required this.id,
    required this.name,
  });

  WallPageSnapshot copyWith({String? id, String? name}) => WallPageSnapshot(id: id ?? this.id, name: name ?? this.name);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
  };

  factory WallPageSnapshot.fromJson(Map<String, dynamic> json) => WallPageSnapshot(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

// ---------------------------------------------------------------------------
// WallPages – a page entry in the wall-controller config
//
//   isPage: true  → snapshot page
//   isPage: false → scene-set page
// ---------------------------------------------------------------------------

class WallPages {
  final String pageId;
  final String name;

  /// true  = snapshot page
  /// false = scene-set page
  final bool isPage;

  final List<WallPageSnapshot> snapshotsList;

  const WallPages({
    required this.pageId,
    required this.name,
    required this.isPage,
    this.snapshotsList = const [],
  });

  WallPages copyWith({
    String? pageId,
    String? name,
    bool? isPage,
    List<WallPageSnapshot>? snapshotsList,
  }) {
    return WallPages(
      pageId: pageId ?? this.pageId,
      name: name ?? this.name,
      isPage: isPage ?? this.isPage,
      snapshotsList: snapshotsList ?? this.snapshotsList,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pageId': pageId,
    'name': name,
    'isPage': isPage,
    'snapshotsList': snapshotsList.map((s) => s.toJson()).toList(),
  };

  factory WallPages.fromJson(Map<String, dynamic> json) => WallPages(
    pageId: json['pageId'] as String,
    name: json['name'] as String,
    isPage: json['isPage'] as bool? ?? true,
    snapshotsList: (json['snapshotsList'] as List<dynamic>?)?.map((e) => WallPageSnapshot.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
  );
}
