import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Model for user-created snapshot pages.
class SnapshotPageModel extends Equatable {
  final String id;
  final String name;
  final List<String> snapshotIds;

  SnapshotPageModel({
    String? id,
    required this.name,
    required this.snapshotIds,
  }) : id = id ?? "SNAPPAGE${DateTime.now().millisecondsSinceEpoch}";

  @override
  List<Object?> get props => <Object?>[id, name, snapshotIds];
}

/// State for the Snapshots/Scenes tab panel.
sealed class SnapshotState extends Equatable {
  const SnapshotState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet.
class SnapshotInitial extends SnapshotState {
  const SnapshotInitial();
}

/// Loading state - fetching data.
class SnapshotLoading extends SnapshotState {
  const SnapshotLoading();
}

/// Loaded state - snapshots and scene sets successfully loaded.
class SnapshotLoaded extends SnapshotState {
  /// All scene sets from the project.
  final List<SceneSetModel> sceneSets;

  /// Snapshots grouped by scene set ID.
  final Map<String, List<SnapshotsModel>> snapshotsInSceneSets;

  /// All standalone snapshots.
  final List<SnapshotsModel> allSnapshots;

  /// Snapshots linked to each snapshot page (pageId → linked snapshots).
  final Map<String, List<SnapshotsModel>> snapshotsPerPage;

  /// Snapshot IDs that are already assigned to some snapshot page.
  final Set<String> usedSnapshotIds;

  /// Scene set IDs that are checked in the SCENES panel.
  final Set<String> selectedSceneSetIds;

  /// Currently active/selected scene set in PAGES panel.
  final String? selectedSceneSetId;

  /// Currently active/recalled snapshot (radio button in VC).
  final String? activeSnapshotId;

  /// User-created snapshot pages.
  final List<SnapshotPageModel> snapshotPages;

  /// Currently selected snapshot page in PAGES panel.
  final String? selectedSnapshotPageId;

  /// Ordered list of page entries (scene sets + snapshot pages) in insertion order.
  final List<ControllerPageModel> orderedPageEntries;

  /// The controller ID this state belongs to.
  final String? controllerId;

  const SnapshotLoaded({
    required this.sceneSets,
    required this.snapshotsInSceneSets,
    required this.allSnapshots,
    this.snapshotsPerPage = const <String, List<SnapshotsModel>>{},
    this.usedSnapshotIds = const <String>{},
    this.selectedSceneSetIds = const <String>{},
    this.selectedSceneSetId,
    this.activeSnapshotId,
    this.snapshotPages = const <SnapshotPageModel>[],
    this.selectedSnapshotPageId,
    this.orderedPageEntries = const <ControllerPageModel>[],
    this.controllerId,
  });

  /// Get checked scene sets as page items for the PAGES panel.
  List<SceneSetModel> get checkedSceneSets => sceneSets.where((SceneSetModel s) => selectedSceneSetIds.contains(s.id)).toList();

  /// Get snapshots for a specific scene set.
  List<SnapshotsModel> getSnapshotsForSceneSet(String sceneSetId) => snapshotsInSceneSets[sceneSetId] ?? const <SnapshotsModel>[];

  /// Get available snapshots (not already used in pages).
  List<SnapshotsModel> get availableSnapshots => allSnapshots.where((SnapshotsModel s) => !usedSnapshotIds.contains(s.id)).toList();

  SnapshotLoaded copyWith({
    List<SceneSetModel>? sceneSets,
    Map<String, List<SnapshotsModel>>? snapshotsInSceneSets,
    List<SnapshotsModel>? allSnapshots,
    Map<String, List<SnapshotsModel>>? snapshotsPerPage,
    Set<String>? usedSnapshotIds,
    Set<String>? selectedSceneSetIds,
    Object? selectedSceneSetId = _sentinel,
    Object? activeSnapshotId = _sentinel,
    List<SnapshotPageModel>? snapshotPages,
    Object? selectedSnapshotPageId = _sentinel,
    List<ControllerPageModel>? orderedPageEntries,
    Object? controllerId = _sentinel,
  }) {
    return SnapshotLoaded(
      sceneSets: sceneSets ?? this.sceneSets,
      snapshotsInSceneSets: snapshotsInSceneSets ?? this.snapshotsInSceneSets,
      allSnapshots: allSnapshots ?? this.allSnapshots,
      snapshotsPerPage: snapshotsPerPage ?? this.snapshotsPerPage,
      usedSnapshotIds: usedSnapshotIds ?? this.usedSnapshotIds,
      selectedSceneSetIds: selectedSceneSetIds ?? this.selectedSceneSetIds,
      selectedSceneSetId: identical(selectedSceneSetId, _sentinel) ? this.selectedSceneSetId : selectedSceneSetId as String?,
      activeSnapshotId: identical(activeSnapshotId, _sentinel) ? this.activeSnapshotId : activeSnapshotId as String?,
      snapshotPages: snapshotPages ?? this.snapshotPages,
      selectedSnapshotPageId: identical(selectedSnapshotPageId, _sentinel) ? this.selectedSnapshotPageId : selectedSnapshotPageId as String?,
      orderedPageEntries: orderedPageEntries ?? this.orderedPageEntries,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sceneSets,
    snapshotsInSceneSets,
    allSnapshots,
    snapshotsPerPage,
    usedSnapshotIds,
    selectedSceneSetIds,
    selectedSceneSetId,
    activeSnapshotId,
    snapshotPages,
    selectedSnapshotPageId,
    orderedPageEntries,
    controllerId,
  ];
}

/// Error state - failed to load data.
class SnapshotError extends SnapshotState {
  final String message;

  const SnapshotError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

/// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
