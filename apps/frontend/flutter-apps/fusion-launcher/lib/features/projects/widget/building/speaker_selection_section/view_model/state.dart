part of 'add_speaker_view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.selectedColor = SpeakerColor.black,
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedListeningAreaForDropDown,
  });

  final SpeakerColor selectedColor;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;

  /// THIS WILL BE USED ONLY FOR SCHEMATIC PAGE WHEN THIS POPUP IS OPENED FROM THERE
  final ListeningArea? selectedListeningAreaForDropDown;

  SpeakerSelectionViewModelState copyWith({
    SpeakerColor? selectedColor,
    SpeakerSortOption? sortOption,
    String? searchQuery,
    bool? isLoading,
    List<SpeakerProduct>? speakers,
    ListeningArea? selectedListeningAreaForDropDown,
  }) {
    return SpeakerSelectionViewModelState(
      selectedColor: selectedColor ?? this.selectedColor,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      selectedListeningAreaForDropDown: selectedListeningAreaForDropDown ?? this.selectedListeningAreaForDropDown,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedColor,
    sortOption,
    searchQuery,
    isLoading,
    selectedListeningAreaForDropDown,
  ];
}
