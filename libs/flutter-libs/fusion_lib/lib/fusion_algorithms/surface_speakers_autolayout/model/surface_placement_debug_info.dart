part of '../surface_speakers_autolayout.dart';

/// Describes why a provisional speaker was removed or merged during placement resolution.
enum SpeakerRemovalReason {
  /// Speaker fell within the corner-threshold of a polygon vertex.
  cornerCollision,

  /// Speaker was merged with an adjacent too-close speaker into a single midpoint speaker.
  adjacentMerge,

  /// Speaker landed on a corner after a midpoint merge and was subsequently removed.
  postMergeCornerCollision,
}

/// Record of a single speaker that was removed (or merged) during placement resolution.
class RemovedSpeakerInfo {
  /// Original position of the removed speaker (in room-space metres).
  final Offset position;

  /// Why the speaker was removed.
  final SpeakerRemovalReason reason;

  /// The nearest polygon corner (only set for [SpeakerRemovalReason.cornerCollision]
  /// and [SpeakerRemovalReason.postMergeCornerCollision]).
  final Offset? nearestCorner;

  /// Distance to the nearest corner that triggered removal (metres).
  final double? distanceToCorner;

  /// For [SpeakerRemovalReason.adjacentMerge]: the other speaker that this one was merged with.
  final Offset? mergedWithPosition;

  /// For [SpeakerRemovalReason.adjacentMerge]: the resulting midpoint speaker position.
  final Offset? mergedToPosition;

  const RemovedSpeakerInfo({
    required this.position,
    required this.reason,
    this.nearestCorner,
    this.distanceToCorner,
    this.mergedWithPosition,
    this.mergedToPosition,
  });

  String get reasonLabel {
    switch (reason) {
      case SpeakerRemovalReason.cornerCollision:
        return 'Corner collision';
      case SpeakerRemovalReason.adjacentMerge:
        return 'Merged with adjacent speaker';
      case SpeakerRemovalReason.postMergeCornerCollision:
        return 'Corner collision after merge';
    }
  }
}

/// Debug metadata produced by [SurfaceSpeakerPlacer.calculatePlacement].
///
/// Contains a record of every provisional speaker that was removed or merged during
/// the overlap-resolution step, together with the reason and context.
class SurfacePlacementDebugInfo {
  /// Polygon corners of the room used for placement (room-space metres).
  final List<Offset> roomCorners;

  /// All initially placed (provisional) speakers before any removal/merge.
  final List<Offset> provisionalPositions;

  /// Speakers removed / merged during resolution.
  final List<RemovedSpeakerInfo> removedSpeakers;

  /// Corner threshold used for corner-collision detection (metres).
  final double cornerThreshold;

  /// Adjacent-overlap threshold used for merge detection (metres).
  final double adjacentOverlapThreshold;

  const SurfacePlacementDebugInfo({
    required this.roomCorners,
    required this.provisionalPositions,
    required this.removedSpeakers,
    required this.cornerThreshold,
    required this.adjacentOverlapThreshold,
  });

  /// Speakers removed solely because of a corner collision.
  List<RemovedSpeakerInfo> get cornerCollisions => removedSpeakers.where((r) => r.reason == SpeakerRemovalReason.cornerCollision).toList();

  /// Speakers removed because they were merged into a midpoint with an adjacent speaker.
  List<RemovedSpeakerInfo> get mergedSpeakers => removedSpeakers.where((r) => r.reason == SpeakerRemovalReason.adjacentMerge).toList();

  /// Speakers removed after a merge produced a position too close to a corner.
  List<RemovedSpeakerInfo> get postMergeCollisions => removedSpeakers.where((r) => r.reason == SpeakerRemovalReason.postMergeCornerCollision).toList();
}
