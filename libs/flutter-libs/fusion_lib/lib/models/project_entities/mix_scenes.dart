import 'package:fusion_lib/fusion_lib.dart';

enum MixSceneType {
  source,
  matrix,
}

// ============================================================================
// Base MixScene - Just metadata about the scene
// ============================================================================
abstract class MixScene {
  final String id;
  final String name;
  final MixSceneType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  MixScene({
    String? id,
    required this.name,
    required this.type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? "SCENE${FusionUtils.shortStringUUID()}",
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  MixScene copyWith({
    String? id,
    String? name,
    MixSceneType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  Map<String, dynamic> toJson();
}

// ============================================================================
// Source Mix Scene - No settings stored here
// ============================================================================
class SourceMixScene extends MixScene {
  SourceMixScene({
    super.id,
    required super.name,
    super.type = MixSceneType.source,
    super.createdAt,
    super.updatedAt,
  });

  @override
  SourceMixScene copyWith({
    String? id,
    String? name,
    MixSceneType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SourceMixScene(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SourceMixScene.fromJson(Map<String, dynamic> json) {
    return SourceMixScene(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// Matrix Mix Scene - No settings stored here
// ============================================================================
class MatrixMixScene extends MixScene {
  MatrixMixScene({
    super.id,
    required super.name,
    super.type = MixSceneType.matrix,
    super.createdAt,
    super.updatedAt,
  });

  @override
  MatrixMixScene copyWith({
    String? id,
    String? name,
    MixSceneType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatrixMixScene(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MatrixMixScene.fromJson(Map<String, dynamic> json) {
    return MatrixMixScene(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// Mix Settings - Now includes function context
// The triple (functionId, sceneId, sourceId) uniquely identifies this setting
// ============================================================================
class MixSettings {
  final String id;
  final String functionId; // NEW: Which function this setting belongs to
  final String? sceneId; // NEW: Which scene this setting belongs to
  final String sourceId; // NEW: Which source this setting is for
  final double gain;
  final bool muted;

  MixSettings({
    String? id,
    required this.functionId,
    this.sceneId,
    required this.sourceId,
    required this.gain,
    required this.muted,
  }) : id = id ?? "MIXSET${FusionUtils.shortStringUUID()}";

  MixSettings copyWith({
    String? id,
    String? functionId,
    String? sceneId,
    String? sourceId,
    double? gain,
    bool? muted,
  }) {
    return MixSettings(
      id: id ?? this.id,
      functionId: functionId ?? this.functionId,
      sceneId: sceneId ?? this.sceneId,
      sourceId: sourceId ?? this.sourceId,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
    );
  }

  factory MixSettings.fromJson(Map<String, dynamic> json) {
    return MixSettings(
      id: json['id'],
      functionId: json['functionId'],
      sceneId: json['sceneId'],
      sourceId: json['sourceId'],
      gain: (json['gain'] as num).toDouble(),
      muted: json['muted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'functionId': functionId,
      'sceneId': sceneId,
      'sourceId': sourceId,
      'gain': gain,
      'muted': muted,
    };
  }
}

// ============================================================================
// Matrix Settings - Base class with function context
// ============================================================================
abstract class MatrixSettings {
  final String id;
  final String functionId; // NEW: Which function this setting belongs to
  String? sceneId; // NEW: Which scene this setting belongs to
  final String sourceId; // NEW: Which source this setting is for
  final String type;
  final double gain;
  final bool muted;

  MatrixSettings({
    String? id,
    required this.functionId,
    required this.sceneId,
    required this.sourceId,
    required this.type,
    this.gain = 0.0,
    this.muted = false,
  }) : id = id ?? "MATSET${FusionUtils.shortStringUUID()}";

  MatrixSettings copyWith({
    String? id,
    String? functionId,
    String? sceneId,
    String? sourceId,
    String? type,
    double? gain,
    bool? muted,
  });

  Map<String, dynamic> toJson();
}

// ============================================================================
// Mono Matrix Settings
// ============================================================================
class MonoMatrixSettings extends MatrixSettings {
  final double mixLevel;
  final double outGain;
  final bool outMuted;

  MonoMatrixSettings({
    super.id,
    required super.functionId,
    super.sceneId,
    required super.sourceId,
    super.type = "mono",
    required this.mixLevel,
    required this.outGain,
    required this.outMuted,
    super.gain,
    super.muted,
  });

  @override
  MonoMatrixSettings copyWith({
    String? id,
    String? functionId,
    String? sceneId,
    String? sourceId,
    String? type,
    double? mixLevel,
    double? outGain,
    bool? outMuted,
    double? gain,
    bool? muted,
  }) {
    return MonoMatrixSettings(
      id: id ?? this.id,
      functionId: functionId ?? this.functionId,
      sceneId: sceneId ?? this.sceneId,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      mixLevel: mixLevel ?? this.mixLevel,
      outGain: outGain ?? this.outGain,
      outMuted: outMuted ?? this.outMuted,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
    );
  }

  factory MonoMatrixSettings.fromJson(Map<String, dynamic> json) {
    return MonoMatrixSettings(
      id: json['id'],
      functionId: json['functionId'],
      sceneId: json['sceneId'],
      sourceId: json['sourceId'],
      type: json['type'],
      mixLevel: (json['mixLevel'] as num).toDouble(),
      outGain: (json['outGain'] as num).toDouble(),
      outMuted: json['outMuted'] as bool,
      gain: (json['gain'] as num?)?.toDouble() ?? 0.0,
      muted: json['muted'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'functionId': functionId,
      'sceneId': sceneId,
      'sourceId': sourceId,
      'type': type,
      'mixLevel': mixLevel,
      'outGain': outGain,
      'outMuted': outMuted,
      'gain': gain,
      'muted': muted,
    };
  }
}

// ============================================================================
// Stereo Matrix Settings
// ============================================================================
class StereoMatrixSettings extends MatrixSettings {
  final double leftMixLevel;
  final double rightMixLevel;
  final double leftOutGain;
  final double rightOutGain;
  final bool leftOutMuted;
  final bool rightOutMuted;

  StereoMatrixSettings({
    super.id,
    required super.functionId,
    super.sceneId,
    required super.sourceId,
    super.type = "stereo",
    required this.leftMixLevel,
    required this.rightMixLevel,
    required this.leftOutGain,
    required this.rightOutGain,
    required this.leftOutMuted,
    required this.rightOutMuted,
    super.gain,
    super.muted,
  });

  @override
  StereoMatrixSettings copyWith({
    String? id,
    String? functionId,
    String? sceneId,
    String? sourceId,
    String? type,
    double? leftMixLevel,
    double? rightMixLevel,
    double? leftOutGain,
    double? rightOutGain,
    bool? leftOutMuted,
    bool? rightOutMuted,
    double? gain,
    bool? muted,
  }) {
    return StereoMatrixSettings(
      id: id ?? this.id,
      functionId: functionId ?? this.functionId,
      sceneId: sceneId ?? this.sceneId,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      leftMixLevel: leftMixLevel ?? this.leftMixLevel,
      rightMixLevel: rightMixLevel ?? this.rightMixLevel,
      leftOutGain: leftOutGain ?? this.leftOutGain,
      rightOutGain: rightOutGain ?? this.rightOutGain,
      leftOutMuted: leftOutMuted ?? this.leftOutMuted,
      rightOutMuted: rightOutMuted ?? this.rightOutMuted,
      gain: gain ?? this.gain,
      muted: muted ?? this.muted,
    );
  }

  factory StereoMatrixSettings.fromJson(Map<String, dynamic> json) {
    return StereoMatrixSettings(
      id: json['id'],
      functionId: json['functionId'],
      sceneId: json['sceneId'],
      sourceId: json['sourceId'],
      type: json['type'],
      leftMixLevel: (json['leftMixLevel'] as num).toDouble(),
      rightMixLevel: (json['rightMixLevel'] as num).toDouble(),
      leftOutGain: (json['leftOutGain'] as num).toDouble(),
      rightOutGain: (json['rightOutGain'] as num).toDouble(),
      leftOutMuted: json['leftOutMuted'] as bool,
      rightOutMuted: json['rightOutMuted'] as bool,
      gain: (json['gain'] as num?)?.toDouble() ?? 0.0,
      muted: json['muted'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'functionId': functionId,
      'sceneId': sceneId,
      'sourceId': sourceId,
      'type': type,
      'leftMixLevel': leftMixLevel,
      'rightMixLevel': rightMixLevel,
      'leftOutGain': leftOutGain,
      'rightOutGain': rightOutGain,
      'leftOutMuted': leftOutMuted,
      'rightOutMuted': rightOutMuted,
      'gain': gain,
      'muted': muted,
    };
  }
}
