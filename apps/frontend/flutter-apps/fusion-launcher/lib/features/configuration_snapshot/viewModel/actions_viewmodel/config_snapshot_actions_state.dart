import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Snapshot Actions feature
sealed class ConfigSnapshotActionsState extends Equatable {
  const ConfigSnapshotActionsState();

  /// Get actions list (empty for non-loaded states)
  List<SceneActionModel> get actions => <SceneActionModel>[];

  /// Get selected snapshot ID
  String? get selectedSnapshotId => null;

  /// Get action by ID from current actions list
  SceneActionModel? getActionById(String actionId) {
    try {
      return actions.firstWhere((SceneActionModel a) => a.id == actionId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no snapshot selected
class SnapshotActionsInitial extends ConfigSnapshotActionsState {
  const SnapshotActionsInitial();
}

/// Loading state - fetching actions for a snapshot
class SnapshotActionsLoading extends ConfigSnapshotActionsState {
  @override
  final String? selectedSnapshotId;

  const SnapshotActionsLoading({this.selectedSnapshotId});

  @override
  List<Object?> get props => <Object?>[selectedSnapshotId];
}

/// Loaded state - actions successfully loaded
class SnapshotActionsLoaded extends ConfigSnapshotActionsState {
  @override
  final List<SceneActionModel> actions;

  @override
  final String? selectedSnapshotId;

  const SnapshotActionsLoaded({
    required this.actions,
    required this.selectedSnapshotId,
  });

  /// Create a copy with updated values
  SnapshotActionsLoaded copyWith({
    List<SceneActionModel>? actions,
    String? selectedSnapshotId,
  }) {
    return SnapshotActionsLoaded(
      actions: actions ?? this.actions,
      selectedSnapshotId: selectedSnapshotId ?? this.selectedSnapshotId,
    );
  }

  @override
  List<Object?> get props => <Object?>[actions, selectedSnapshotId];
}

/// Error state - failed to load actions
class SnapshotActionsError extends ConfigSnapshotActionsState {
  final String message;

  @override
  final String? selectedSnapshotId;

  const SnapshotActionsError({
    required this.message,
    this.selectedSnapshotId,
  });

  @override
  List<Object?> get props => <Object?>[message, selectedSnapshotId];
}
