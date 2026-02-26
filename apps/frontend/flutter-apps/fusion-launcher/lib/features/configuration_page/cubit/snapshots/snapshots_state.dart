import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Enum representing the section from which a snapshot is being dragged
enum DragSection { snapshots, scenes }

/// Base state class for the Snapshots feature
sealed class SnapshotsState extends Equatable {
  const SnapshotsState();

  /// Get snapshots list (empty for non-loaded states)
  List<SnapshotsModel> get snapshots => <SnapshotsModel>[];

  /// Get selected snapshot ID
  String? get selectedSnapshotId => null;

  /// Get dragging snapshot ID
  String? get draggingSnapshotId => null;

  /// Get dragging from section
  DragSection? get draggingFromSection => null;

  /// Get sources height
  double get sourcesHeight => 200;

  /// Check if currently dragging from snapshots section
  bool get isDraggingFromSnapshots => draggingFromSection == DragSection.snapshots;

  /// Check if currently dragging from scenes section
  bool get isDraggingFromScenes => draggingFromSection == DragSection.scenes;

  /// Check if any drag operation is in progress
  bool get isDragging => draggingSnapshotId != null;

  /// Get selected snapshot model
  SnapshotsModel? get selectedSnapshot {
    if (selectedSnapshotId == null) return null;
    try {
      return snapshots.firstWhere((SnapshotsModel s) => s.id == selectedSnapshotId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class SnapshotsInitial extends SnapshotsState {
  const SnapshotsInitial();
}

/// Loading state - fetching snapshots
class SnapshotsLoading extends SnapshotsState {
  const SnapshotsLoading();
}

/// Loaded state - snapshots successfully loaded
class SnapshotsLoaded extends SnapshotsState {
  @override
  final List<SnapshotsModel> snapshots;

  @override
  final String? selectedSnapshotId;

  @override
  final String? draggingSnapshotId;

  @override
  final DragSection? draggingFromSection;

  @override
  final double sourcesHeight;

  const SnapshotsLoaded({
    required this.snapshots,
    this.selectedSnapshotId,
    this.draggingSnapshotId,
    this.draggingFromSection,
    this.sourcesHeight = 200,
  });

  /// Create a copy with updated values
  SnapshotsLoaded copyWith({
    List<SnapshotsModel>? snapshots,
    String? selectedSnapshotId,
    String? draggingSnapshotId,
    DragSection? draggingFromSection,
    double? sourcesHeight,
    bool clearSelectedSnapshotId = false,
    bool clearDraggingSnapshotId = false,
    bool clearDraggingFromSection = false,
  }) {
    return SnapshotsLoaded(
      snapshots: snapshots ?? this.snapshots,
      selectedSnapshotId: clearSelectedSnapshotId ? null : (selectedSnapshotId ?? this.selectedSnapshotId),
      draggingSnapshotId: clearDraggingSnapshotId ? null : (draggingSnapshotId ?? this.draggingSnapshotId),
      draggingFromSection: clearDraggingFromSection ? null : (draggingFromSection ?? this.draggingFromSection),
      sourcesHeight: sourcesHeight ?? this.sourcesHeight,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    snapshots,
    selectedSnapshotId,
    draggingSnapshotId,
    draggingFromSection,
    sourcesHeight,
  ];
}

/// Error state - failed to load snapshots
class SnapshotsError extends SnapshotsState {
  final String message;

  const SnapshotsError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
