import 'package:fusion_lib/fusion_lib.dart';

enum MixSceneType {
  source,
  matrix,
}

enum SignalType {
  mono("Mono"),
  stereo("Stereo");

  const SignalType(this.displayName);
  final String displayName;

  static SignalType? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'mono':
        return SignalType.mono;
      case 'stereo':
        return SignalType.stereo;
      default:
        return null;
    }
  }
}

// ============================================================================
// Base MixScene - Just metadata about the scene
// ============================================================================
abstract class MixScene {
  final String id;
  final String name;
  final MixSceneType type;

  MixScene({
    String? id,
    required this.name,
    required this.type,
  }) : id = id ?? "SCENE${FusionUtils.shortStringUUID()}";

  MixScene copyWith({
    String? id,
    String? name,
  });

  Map<String, dynamic> toJson();
}

// ============================================================================
// Source Mix Scene - No settings stored here
// ============================================================================
class SourceMixScene extends MixScene {
  final List<MixSettings> mixSettings;

  SourceMixScene({
    super.id,
    required super.name,
    super.type = MixSceneType.source,
    this.mixSettings = const [],
  });

  @override
  SourceMixScene copyWith({
    String? id,
    String? name,
    final List<MixSettings>? mixSettings,
  }) {
    return SourceMixScene(
      id: id ?? this.id,
      name: name ?? this.name,
      mixSettings: mixSettings ?? this.mixSettings,
    );
  }

  factory SourceMixScene.fromJson(Map<String, dynamic> json) {
    return SourceMixScene(
      id: json['id'],
      name: json['name'],
      mixSettings:
          (json['mixSettings'] as List<dynamic>?)?.map((e) {
            return MixSettings.fromJson(e);
          }).toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'mixSettings': mixSettings.map((e) => e.toJson()).toList(),
    };
  }
}

// ============================================================================
// Matrix Mix Scene - No settings stored here
// ============================================================================
class MatrixMixScene extends MixScene {
  final MatrixMixer mixerConfig;

  MatrixMixScene({
    super.id,
    required super.name,
    super.type = MixSceneType.matrix,
    required this.mixerConfig,
  });

  @override
  MatrixMixScene copyWith({
    String? id,
    String? name,
    MatrixMixer? mixerConfig,
  }) {
    return MatrixMixScene(
      id: id ?? this.id,
      name: name ?? this.name,
      mixerConfig: mixerConfig ?? this.mixerConfig,
    );
  }

  factory MatrixMixScene.fromJson(Map<String, dynamic> json) {
    return MatrixMixScene(
      id: json['id'],
      name: json['name'],
      mixerConfig: json['mixerConfig']['type'] == SignalType.mono.name
          ? MonoMatrixMixer.fromJson(json['mixerConfig'])
          : StereoMatrixMixer.fromJson(json['mixerConfig']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'mixerConfig': mixerConfig.toJson(),
    };
  }
}

// ============================================================================
// Mix Settings - Stored separately with context
// ============================================================================
class MixSettings {
  final String sourceId;
  final double gain;
  final bool muted;

  MixSettings({
    required this.sourceId,
    required this.gain,
    required this.muted,
  });

  MixSettings copyWith({
    String? sourceId,
    double? gain,
    bool? muted,
  }) {
    return MixSettings(
      sourceId: sourceId ?? this.sourceId,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
    );
  }

  factory MixSettings.fromJson(Map<String, dynamic> json) {
    return MixSettings(
      sourceId: json['sourceId'],
      gain: (json['gain'] as num).toDouble(),
      muted: json['muted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'gain': gain,
      'muted': muted,
    };
  }
}

// ============================================================================
// Matrix Settings - Base class (source-level settings)
// ============================================================================
abstract class MatrixSettings {
  final String sourceId;
  final String type;
  final double gain;
  final bool muted;

  MatrixSettings({
    required this.sourceId,
    required this.type,
    required this.gain,
    required this.muted,
  });

  MatrixSettings copyWith({
    String? sourceId,
    String? type,
    double? gain,
    bool? muted,
  });

  Map<String, dynamic> toJson();
}

// ============================================================================
// Mono Matrix Settings (per source)
// ============================================================================
class MonoMatrixSettings extends MatrixSettings {
  final double mixLevel;

  MonoMatrixSettings({
    required super.sourceId,
    super.type = "mono",
    required super.gain,
    required super.muted,
    required this.mixLevel,
  });

  @override
  MonoMatrixSettings copyWith({
    String? sourceId,
    String? type,
    double? gain,
    bool? muted,
    double? mixLevel,
  }) {
    return MonoMatrixSettings(
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
      mixLevel: mixLevel ?? this.mixLevel,
    );
  }

  factory MonoMatrixSettings.fromJson(Map<String, dynamic> json) {
    return MonoMatrixSettings(
      sourceId: json['sourceId'],
      type: json['type'],
      gain: (json['gain'] as num).toDouble(),
      muted: json['muted'] as bool,
      mixLevel: (json['mixLevel'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'type': type,
      'gain': gain,
      'muted': muted,
      'mixLevel': mixLevel,
    };
  }
}

// ============================================================================
// Stereo Matrix Settings (per source)
// ============================================================================
class StereoMatrixSettings extends MatrixSettings {
  final double leftMixLevel;
  final double rightMixLevel;

  StereoMatrixSettings({
    required super.sourceId,
    super.type = "stereo",
    required super.gain,
    required super.muted,
    required this.leftMixLevel,
    required this.rightMixLevel,
  });

  @override
  StereoMatrixSettings copyWith({
    String? sourceId,
    String? type,
    double? gain,
    bool? muted,
    double? leftMixLevel,
    double? rightMixLevel,
  }) {
    return StereoMatrixSettings(
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
      leftMixLevel: leftMixLevel ?? this.leftMixLevel,
      rightMixLevel: rightMixLevel ?? this.rightMixLevel,
    );
  }

  factory StereoMatrixSettings.fromJson(Map<String, dynamic> json) {
    return StereoMatrixSettings(
      sourceId: json['sourceId'],
      type: json['type'],
      gain: (json['gain'] as num).toDouble(),
      muted: json['muted'] as bool,
      leftMixLevel: (json['leftMixLevel'] as num).toDouble(),
      rightMixLevel: (json['rightMixLevel'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'type': type,
      'gain': gain,
      'muted': muted,
      'leftMixLevel': leftMixLevel,
      'rightMixLevel': rightMixLevel,
    };
  }
}

// ============================================================================
// Matrix Mixer - Base class (output-level configuration)
// ============================================================================
abstract class MatrixMixer {
  final String id;
  final List<MatrixSettings> settings;
  final SignalType type;

  MatrixMixer({
    String? id,
    required this.type,
    this.settings = const [],
  }) : id = id ?? "MIXER${FusionUtils.shortStringUUID()}";

  MatrixMixer copyWith({
    String? id,
    List<MatrixSettings>? settings,
  });

  MatrixMixer clone();

  Map<String, dynamic> toJson();
}

// ============================================================================
// Mono Matrix Mixer (output configuration)
// ============================================================================
class MonoMatrixMixer extends MatrixMixer {
  final double outGain;
  final bool outMuted;

  MonoMatrixMixer({
    super.id,
    super.type = SignalType.mono,
    required this.outGain,
    required this.outMuted,
    super.settings,
  });

  @override
  MonoMatrixMixer copyWith({
    String? id,
    double? outGain,
    bool? outMuted,
    List<MatrixSettings>? settings,
  }) {
    return MonoMatrixMixer(
      id: id ?? this.id,
      outGain: outGain ?? this.outGain,
      outMuted: outMuted ?? this.outMuted,
      settings: settings ?? this.settings,
    );
  }

  @override
  MatrixMixer clone() {
    return MonoMatrixMixer(
      id: id,
      outGain: outGain,
      outMuted: outMuted,
      settings: settings.map((e) {
        return e is MonoMatrixSettings
            ? e.copyWith()
            : e is StereoMatrixSettings
            ? e.copyWith()
            : e;
      }).toList(),
    );
  }

  factory MonoMatrixMixer.fromJson(Map<String, dynamic> json) {
    return MonoMatrixMixer(
      id: json['id'],
      outGain: (json['outGain'] as num).toDouble(),
      outMuted: json['outMuted'] as bool,
      type: SignalType.mono,
      settings:
          (json['settings'] as List<dynamic>?)?.map((e) {
            return MonoMatrixSettings.fromJson(e);
          }).toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'outGain': outGain,
      'outMuted': outMuted,
      'type': type.name,
      'settings': settings.map((e) => e.toJson()).toList(),
    };
  }
}

// ============================================================================
// Stereo Matrix Mixer (output configuration)
// ============================================================================
class StereoMatrixMixer extends MatrixMixer {
  final double leftOutGain;
  final double rightOutGain;
  final bool leftOutMuted;
  final bool rightOutMuted;

  StereoMatrixMixer({
    super.id,
    super.type = SignalType.stereo,
    required this.leftOutGain,
    required this.rightOutGain,
    required this.leftOutMuted,
    required this.rightOutMuted,
    super.settings,
  });

  @override
  StereoMatrixMixer copyWith({
    String? id,
    String? name,
    String? functionId,
    String? sceneId,
    double? leftOutGain,
    double? rightOutGain,
    bool? leftOutMuted,
    bool? rightOutMuted,
    List<MatrixSettings>? settings,
  }) {
    return StereoMatrixMixer(
      id: id ?? this.id,
      leftOutGain: leftOutGain ?? this.leftOutGain,
      rightOutGain: rightOutGain ?? this.rightOutGain,
      leftOutMuted: leftOutMuted ?? this.leftOutMuted,
      rightOutMuted: rightOutMuted ?? this.rightOutMuted,
      settings: settings ?? this.settings,
    );
  }

  @override
  MatrixMixer clone() {
    return StereoMatrixMixer(
      id: id,
      leftOutGain: leftOutGain,
      rightOutGain: rightOutGain,
      leftOutMuted: leftOutMuted,
      rightOutMuted: rightOutMuted,
      settings: settings.map((e) {
        return e is MonoMatrixSettings
            ? e.copyWith()
            : e is StereoMatrixSettings
            ? e.copyWith()
            : e;
      }).toList(),
    );
  }

  factory StereoMatrixMixer.fromJson(Map<String, dynamic> json) {
    return StereoMatrixMixer(
      id: json['id'],
      leftOutGain: (json['leftOutGain'] as num).toDouble(),
      rightOutGain: (json['rightOutGain'] as num).toDouble(),
      leftOutMuted: json['leftOutMuted'] as bool,
      rightOutMuted: json['rightOutMuted'] as bool,
      type: SignalType.stereo,
      settings:
          (json['settings'] as List<dynamic>?)?.map((e) {
            return StereoMatrixSettings.fromJson(e);
          }).toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leftOutGain': leftOutGain,
      'rightOutGain': rightOutGain,
      'leftOutMuted': leftOutMuted,
      'rightOutMuted': rightOutMuted,
      'type': type.name,
      'settings': settings.map((e) => e.toJson()).toList(),
    };
  }
}
