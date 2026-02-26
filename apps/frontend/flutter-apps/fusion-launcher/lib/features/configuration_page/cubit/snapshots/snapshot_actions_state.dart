import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// State class for the Snapshot Actions feature
class SnapshotActionsState extends Equatable {
  /// List of actions for the currently selected snapshot
  final List<SceneActionModel> actions;

  /// Currently selected snapshot ID (for context)
  final String? selectedSnapshotId;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  const SnapshotActionsState({
    this.actions = const <SceneActionModel>[],
    this.selectedSnapshotId,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state factory
  factory SnapshotActionsState.initial() => const SnapshotActionsState();

  /// Get action by ID from current actions list
  SceneActionModel? getActionById(String actionId) {
    try {
      return actions.firstWhere((SceneActionModel a) => a.id == actionId);
    } catch (_) {
      return null;
    }
  }

  SnapshotActionsState copyWith({
    List<SceneActionModel>? actions,
    String? selectedSnapshotId,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedSnapshotId = false,
    bool clearErrorMessage = false,
  }) {
    return SnapshotActionsState(
      actions: actions ?? this.actions,
      selectedSnapshotId: clearSelectedSnapshotId ? null : (selectedSnapshotId ?? this.selectedSnapshotId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    actions,
    selectedSnapshotId,
    isLoading,
    errorMessage,
  ];
}
