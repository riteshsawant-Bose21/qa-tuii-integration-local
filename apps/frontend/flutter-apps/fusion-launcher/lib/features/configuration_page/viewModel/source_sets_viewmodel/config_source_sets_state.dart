import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Source Sets feature
sealed class ConfigSourceSetsState extends Equatable {
  const ConfigSourceSetsState();

  /// Get source sets list (empty for non-loaded states)
  List<SourceSet> get sourceSets => <SourceSet>[];

  /// Get sources map for each source set (empty for non-loaded states)
  Map<String, List<Source>> get sourcesInSourceSets => <String, List<Source>>{};

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class SourceSetsInitial extends ConfigSourceSetsState {
  const SourceSetsInitial();
}

/// Loading state - fetching source sets
class SourceSetsLoading extends ConfigSourceSetsState {
  const SourceSetsLoading();
}

/// Loaded state - source sets successfully loaded
class SourceSetsLoaded extends ConfigSourceSetsState {
  @override
  final List<SourceSet> sourceSets;

  @override
  final Map<String, List<Source>> sourcesInSourceSets;

  const SourceSetsLoaded({
    required this.sourceSets,
    this.sourcesInSourceSets = const <String, List<Source>>{},
  });

  /// Create a copy with updated values
  SourceSetsLoaded copyWith({
    List<SourceSet>? sourceSets,
    Map<String, List<Source>>? sourcesInSourceSets,
  }) {
    return SourceSetsLoaded(
      sourceSets: sourceSets ?? this.sourceSets,
      sourcesInSourceSets: sourcesInSourceSets ?? this.sourcesInSourceSets,
    );
  }

  @override
  List<Object?> get props => <Object?>[sourceSets, sourcesInSourceSets];
}

/// Error state - failed to load source sets
class SourceSetsError extends ConfigSourceSetsState {
  final String message;

  const SourceSetsError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
