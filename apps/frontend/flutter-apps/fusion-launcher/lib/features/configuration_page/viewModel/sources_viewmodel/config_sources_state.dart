import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Sources feature
sealed class ConfigSourcesState extends Equatable {
  const ConfigSourcesState();

  /// Get sources list (empty for non-loaded states)
  List<Source> get sources => <Source>[];

  /// Get filtered sources list
  List<Source> get filteredSources => <Source>[];

  /// Get search query
  String get searchQuery => '';

  /// Get dragging source ID
  String? get draggingSourceId => null;

  /// Get sources height
  double get sourcesHeight => 200;

  /// Check if any drag operation is in progress
  bool get isDragging => draggingSourceId != null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class SourcesInitial extends ConfigSourcesState {
  const SourcesInitial();
}

/// Loading state - fetching sources
class SourcesLoading extends ConfigSourcesState {
  const SourcesLoading();
}

/// Loaded state - sources successfully loaded
class SourcesLoaded extends ConfigSourcesState {
  @override
  final List<Source> sources;

  @override
  final List<Source> filteredSources;

  @override
  final String searchQuery;

  @override
  final String? draggingSourceId;

  @override
  final double sourcesHeight;

  const SourcesLoaded({
    required this.sources,
    required this.filteredSources,
    this.searchQuery = '',
    this.draggingSourceId,
    this.sourcesHeight = 200,
  });

  /// Create a copy with updated values
  SourcesLoaded copyWith({
    List<Source>? sources,
    List<Source>? filteredSources,
    String? searchQuery,
    String? draggingSourceId,
    double? sourcesHeight,
    bool clearDraggingSourceId = false,
  }) {
    return SourcesLoaded(
      sources: sources ?? this.sources,
      filteredSources: filteredSources ?? this.filteredSources,
      searchQuery: searchQuery ?? this.searchQuery,
      draggingSourceId: clearDraggingSourceId ? null : (draggingSourceId ?? this.draggingSourceId),
      sourcesHeight: sourcesHeight ?? this.sourcesHeight,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sources,
    filteredSources,
    searchQuery,
    draggingSourceId,
    sourcesHeight,
  ];
}

/// Error state - failed to load sources
class SourcesError extends ConfigSourcesState {
  final String message;

  const SourcesError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
