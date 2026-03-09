import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_page/viewModel/sources_viewmodel/config_sources_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Cubit for managing Sources feature state and business logic
class ConfigSourcesViewmodel extends Cubit<ConfigSourcesState> {
  final ProjectViewModel _projectViewModel;

  ConfigSourcesViewmodel({
    required ProjectViewModel projectViewModel,
  }) : _projectViewModel = projectViewModel,
       super(const SourcesInitial()) {
    _loadSources();
  }

  /// Load sources from ProjectViewModel
  void _loadSources() {
    try {
      final List<Source> sources = _projectViewModel.getSourcesWithoutSourceSet();
      emit(
        SourcesLoaded(
          sources: sources,
          filteredSources: sources,
        ),
      );
    } catch (e) {
      emit(SourcesError(message: e.toString()));
    }
  }

  /// Sync state with ProjectViewModel
  void syncWithProjectViewModel() {
    final ConfigSourcesState currentState = state;

    try {
      final List<Source> sources = _projectViewModel.getSourcesWithoutSourceSet();

      if (currentState is SourcesLoaded) {
        final List<Source> filteredSources = _filterSourcesInternal(sources, currentState.searchQuery);
        emit(
          currentState.copyWith(
            sources: sources,
            filteredSources: filteredSources,
          ),
        );
      } else {
        emit(
          SourcesLoaded(
            sources: sources,
            filteredSources: sources,
          ),
        );
      }
    } catch (e) {
      emit(SourcesError(message: e.toString()));
    }
  }

  /// Refresh data from ProjectViewModel
  void refresh() => syncWithProjectViewModel();

  /// ==================== Search Operations ====================

  /// Filter sources based on search query
  void filterSources(String query) {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      final List<Source> filteredSources = _filterSourcesInternal(currentState.sources, query);
      emit(
        currentState.copyWith(
          searchQuery: query,
          filteredSources: filteredSources,
        ),
      );
    }
  }

  /// Internal method to filter sources
  List<Source> _filterSourcesInternal(List<Source> sources, String query) {
    if (query.isEmpty) {
      return sources;
    }
    return sources.where((Source source) => source.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// Clear search query
  void clearSearch() {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      emit(
        currentState.copyWith(
          searchQuery: '',
          filteredSources: currentState.sources,
        ),
      );
    }
  }

  /// ==================== Drag and Drop Operations ====================

  /// Start dragging a source
  void startDrag(String sourceId) {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      emit(currentState.copyWith(draggingSourceId: sourceId));
    }
  }

  /// End dragging
  void endDrag() {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      emit(currentState.copyWith(clearDraggingSourceId: true));
    }
  }

  /// Handle drop on sources section (remove from source set)
  void handleDropOnSources(Source source) {
    final SourceSet? sourceSet = _projectViewModel.getSourceSetForSource(sourceId: source.id);
    if (sourceSet != null) {
      _projectViewModel.removeSourceFromSourceSet(sourceId: source.id, sourceSetId: sourceSet.id);
    }
    endDrag();
    syncWithProjectViewModel();
  }

  /// Check if a drop should be accepted on sources section
  bool shouldAcceptDropOnSources(String sourceId) => isSourceInAnySourceSet(sourceId);

  /// Check if source is in any source set
  bool isSourceInAnySourceSet(String sourceId) {
    for (final SourceSet sourceSet in _projectViewModel.sourceSets) {
      final List<Source> sourcesInSet = _projectViewModel.getSourcesInSourceSet(sourceSetId: sourceSet.id);
      if (sourcesInSet.any((Source s) => s.id == sourceId)) return true;
    }
    return false;
  }

  /// ==================== UI State Management ====================

  /// Update the height of the sources panel
  void updateSourcesHeight(double delta, double screenHeight) {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      final double minHeight = screenHeight * 0.15;
      final double maxHeight = screenHeight * 0.5;
      final double newHeight = (currentState.sourcesHeight + delta).clamp(minHeight, maxHeight);
      emit(currentState.copyWith(sourcesHeight: newHeight));
    }
  }

  /// Initialize sources height based on screen size
  void initializeSourcesHeight(double screenHeight) {
    final ConfigSourcesState currentState = state;
    if (currentState is SourcesLoaded) {
      final double initialHeight = screenHeight * 0.25;
      emit(currentState.copyWith(sourcesHeight: initialHeight));
    }
  }
}
