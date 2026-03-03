import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Base state class for the Scene Sets feature
sealed class ConfigSceneSetsState extends Equatable {
  const ConfigSceneSetsState();

  /// Get scene sets list (empty for non-loaded states)
  List<SceneSetModel> get sceneSets => <SceneSetModel>[];

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class SceneSetsInitial extends ConfigSceneSetsState {
  const SceneSetsInitial();
}

/// Loading state - fetching scene sets
class SceneSetsLoading extends ConfigSceneSetsState {
  const SceneSetsLoading();
}

/// Loaded state - scene sets successfully loaded
class SceneSetsLoaded extends ConfigSceneSetsState {
  @override
  final List<SceneSetModel> sceneSets;

  const SceneSetsLoaded({
    required this.sceneSets,
  });

  /// Create a copy with updated values
  SceneSetsLoaded copyWith({
    List<SceneSetModel>? sceneSets,
  }) {
    return SceneSetsLoaded(
      sceneSets: sceneSets ?? this.sceneSets,
    );
  }

  @override
  List<Object?> get props => <Object?>[sceneSets];
}

/// Error state - failed to load scene sets
class SceneSetsError extends ConfigSceneSetsState {
  final String message;

  const SceneSetsError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
