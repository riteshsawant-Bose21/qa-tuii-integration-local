part of 'view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.mode = SpeakerSelectionMode.select,
    this.selectedColors = const <SpeakerColor>{},
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedSignalType = SignalType.mono,
  });

  final SpeakerSelectionMode mode;
  final Set<SpeakerColor> selectedColors;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;
  final SignalType selectedSignalType;

  SpeakerSelectionViewModelState copyWith({
    SpeakerSelectionMode? mode,
    Set<SpeakerColor>? selectedColors,
    SpeakerSortOption? sortOption,
    String? searchQuery,
    bool? isLoading,
    List<SpeakerProduct>? speakers,
  }) {
    return SpeakerSelectionViewModelState(
      mode: mode ?? this.mode,
      selectedColors: selectedColors ?? this.selectedColors,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    mode,
    selectedColors,
    sortOption,
    searchQuery,
    isLoading,
  ];
}
