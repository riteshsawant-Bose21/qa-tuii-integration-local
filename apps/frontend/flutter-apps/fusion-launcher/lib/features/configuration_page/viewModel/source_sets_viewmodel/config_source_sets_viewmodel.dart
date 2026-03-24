import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_page/viewModel/source_sets_viewmodel/config_source_sets_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Cubit for managing Source Sets feature state and business logic
class ConfigSourceSetsViewmodel extends Cubit<ConfigSourceSetsState> {
  final ProjectViewModel _projectViewModel;

  ConfigSourceSetsViewmodel({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const SourceSetsInitial()) {
    _loadSourceSets();
  }

  /// Load source sets from ProjectViewModel
  void _loadSourceSets() {
    try {
      final List<SourceSet> sourceSets = _projectViewModel.sourceSets;
      final Map<String, List<Source>> sourcesMap = _buildSourcesMap(sourceSets);
      emit(
        SourceSetsLoaded(
          sourceSets: sourceSets,
          sourcesInSourceSets: sourcesMap,
        ),
      );
    } catch (e) {
      emit(SourceSetsError(message: e.toString()));
    }
  }

  /// Build sources map for all source sets
  Map<String, List<Source>> _buildSourcesMap(List<SourceSet> sourceSets) {
    final Map<String, List<Source>> sourcesMap = <String, List<Source>>{};
    for (final SourceSet sourceSet in sourceSets) {
      sourcesMap[sourceSet.id] = _projectViewModel.getSourcesInSourceSet(sourceSetId: sourceSet.id);
    }
    return sourcesMap;
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final ConfigSourceSetsState currentState = state;

    try {
      final List<SourceSet> sourceSets = _projectViewModel.sourceSets;
      final Map<String, List<Source>> sourcesMap = _buildSourcesMap(sourceSets);

      if (currentState is SourceSetsLoaded) {
        emit(
          currentState.copyWith(
            sourceSets: sourceSets,
            sourcesInSourceSets: sourcesMap,
          ),
        );
      } else {
        emit(
          SourceSetsLoaded(
            sourceSets: sourceSets,
            sourcesInSourceSets: sourcesMap,
          ),
        );
      }
    } catch (e) {
      emit(SourceSetsError(message: e.toString()));
    }
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// ==================== Source Set Operations ====================

  /// Add a new source set
  void addSourceSet({required String name, required List<String> sourceIds}) {
    final SourceSet newSourceSet = SourceSet(name: name);
    _projectViewModel.addSourceSet(sourceSet: newSourceSet);
    _projectViewModel.updateSourcesInSourceSet(
      sourceSetId: newSourceSet.id,
      sourceIds: sourceIds,
    );
    syncWithProjectViewModel();
  }

  /// Delete a source set
  void deleteSourceSet(String sourceSetId) {
    _projectViewModel.removeSourceSet(sourceSetId: sourceSetId);
    syncWithProjectViewModel();
  }

  /// Update/rename a source set
  void updateSourceSet(SourceSet sourceSet) {
    _projectViewModel.updateSourceSet(sourceSet: sourceSet);
    syncWithProjectViewModel();
  }

  /// Reorder source sets
  void reorderSourceSets(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final List<SourceSet> sourceSets = state.sourceSets;
    if (oldIndex >= 0 && oldIndex < sourceSets.length && adjustedNewIndex >= 0 && adjustedNewIndex < sourceSets.length) {
      final String sourceSetToMove = sourceSets[oldIndex].id;
      final String sourceSetAtNewIndex = sourceSets[adjustedNewIndex].id;
      _projectViewModel.reOrderSourceSet(
        sourceSetIdToMove: sourceSetToMove,
        sourceSetAtNewIndex: sourceSetAtNewIndex,
      );
      syncWithProjectViewModel();
    }
  }

  /// ==================== Sources in Source Set Operations ====================

  /// Get sources in a source set
  List<Source> getSourcesInSourceSet({required String sourceSetId}) {
    return _projectViewModel.getSourcesInSourceSet(sourceSetId: sourceSetId);
  }

  /// Add source to source set
  void addSourceToSourceSet({required String sourceId, required String sourceSetId}) {
    _projectViewModel.addSourceToSourceSet(sourceId: sourceId, sourceSetId: sourceSetId);
    syncWithProjectViewModel();
  }

  /// Remove source from source set
  void removeSourceFromSourceSet({required String sourceId, required String sourceSetId}) {
    _projectViewModel.removeSourceFromSourceSet(sourceId: sourceId, sourceSetId: sourceSetId);
    syncWithProjectViewModel();
  }

  /// Get source set for a source
  SourceSet? getSourceSetForSource({required String sourceId}) {
    return _projectViewModel.getSourceSetForSource(sourceId: sourceId);
  }

  /// Check if source is in a specific source set
  bool isSourceInSourceSet({required String sourceId, required String sourceSetId}) {
    final List<Source> sourcesInSet = getSourcesInSourceSet(sourceSetId: sourceSetId);
    return sourcesInSet.any((Source source) => source.id == sourceId);
  }

  /// Get available sources (not in any source set)
  List<Source> getAvailableSources() {
    return _projectViewModel.getSourcesWithoutSourceSet();
  }

  /// Update sources in a source set
  void updateSourcesInSourceSet({required String sourceSetId, required List<String> sourceIds}) {
    _projectViewModel.updateSourcesInSourceSet(sourceSetId: sourceSetId, sourceIds: sourceIds);
    syncWithProjectViewModel();
  }

  /// Get all sources
  List<Source> getAllSources() {
    return _projectViewModel.sources;
  }

  /// Get all source sets
  List<SourceSet> getAllSourceSets() {
    return _projectViewModel.getAllSourceSets();
  }

  /// Check if source set can be linked
  bool canLinkSourceSet({required String sourceSetId}) {
    return _projectViewModel.canLinkSourceSet(sourceSetId: sourceSetId);
  }

  /// Link a source set
  void linkSourceSet({required String sourceSetId}) {
    _projectViewModel.linkSourceSet(sourceSetId: sourceSetId);
    syncWithProjectViewModel();
  }

  /// Unlink a source set
  void unlinkSourceSet({required String sourceSetId}) {
    _projectViewModel.unlinkSourceSet(sourceSetId: sourceSetId);
    syncWithProjectViewModel();
  }
}
