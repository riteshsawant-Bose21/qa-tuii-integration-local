import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// State class for the Scene Sets feature
class SceneSetsState extends Equatable {
  /// List of all scene sets
  final List<SceneSetModel> sceneSets;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  const SceneSetsState({
    this.sceneSets = const <SceneSetModel>[],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state factory
  factory SceneSetsState.initial() => const SceneSetsState();

  SceneSetsState copyWith({
    List<SceneSetModel>? sceneSets,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SceneSetsState(
      sceneSets: sceneSets ?? this.sceneSets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sceneSets,
    isLoading,
    errorMessage,
  ];
}
