import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Enum representing the section from which a snapshot is being dragged
enum DragSection { snapshots, scenes }

/// State class for the Snapshots feature
class SnapshotsState extends Equatable {
  /// List of all standalone snapshots
  final List<SnapshotsModel> snapshots;

  /// Currently selected snapshot ID
  final String? selectedSnapshotId;

  /// ID of the snapshot currently being dragged
  final String? draggingSnapshotId;

  /// Section from which the drag originated
  final DragSection? draggingFromSection;

  /// Height of the snapshots panel (for drag divider)
  final double sourcesHeight;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  const SnapshotsState({
    this.snapshots = const <SnapshotsModel>[],
    this.selectedSnapshotId,
    this.draggingSnapshotId,
    this.draggingFromSection,
    this.sourcesHeight = 200,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state factory
  factory SnapshotsState.initial() => const SnapshotsState();

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

  SnapshotsState copyWith({
    List<SnapshotsModel>? snapshots,
    String? selectedSnapshotId,
    String? draggingSnapshotId,
    DragSection? draggingFromSection,
    double? sourcesHeight,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedSnapshotId = false,
    bool clearDraggingSnapshotId = false,
    bool clearDraggingFromSection = false,
    bool clearErrorMessage = false,
  }) {
    return SnapshotsState(
      snapshots: snapshots ?? this.snapshots,
      selectedSnapshotId: clearSelectedSnapshotId ? null : (selectedSnapshotId ?? this.selectedSnapshotId),
      draggingSnapshotId: clearDraggingSnapshotId ? null : (draggingSnapshotId ?? this.draggingSnapshotId),
      draggingFromSection: clearDraggingFromSection ? null : (draggingFromSection ?? this.draggingFromSection),
      sourcesHeight: sourcesHeight ?? this.sourcesHeight,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    snapshots,
    selectedSnapshotId,
    draggingSnapshotId,
    draggingFromSection,
    sourcesHeight,
    isLoading,
    errorMessage,
  ];
}
