part of 'view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.mode = SpeakerSelectionMode.select,
    this.selectedColors = const <SpeakerColor>{},
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedSignalType = SignalType.mono,
    this.selectedListeningAreaForDropDown,
  });

  final SpeakerSelectionMode mode;
  final Set<SpeakerColor> selectedColors;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;
  final SignalType selectedSignalType;

  /// THIS WILL BE USED ONLY FOR SCHEMATIC PAGE WHEN THIS POPUP IS OPENED FROM THERE
  final ListeningArea? selectedListeningAreaForDropDown;

  SpeakerSelectionViewModelState copyWith({
    SpeakerSelectionMode? mode,
    Set<SpeakerColor>? selectedColors,
    SpeakerSortOption? sortOption,
    String? searchQuery,
    bool? isLoading,
    List<SpeakerProduct>? speakers,
    ListeningArea? selectedListeningAreaForDropDown,
  }) {
    return SpeakerSelectionViewModelState(
      mode: mode ?? this.mode,
      selectedColors: selectedColors ?? this.selectedColors,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      selectedListeningAreaForDropDown: selectedListeningAreaForDropDown ?? this.selectedListeningAreaForDropDown,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    mode,
    selectedColors,
    sortOption,
    searchQuery,
    isLoading,
    selectedListeningAreaForDropDown,
  ];
}
