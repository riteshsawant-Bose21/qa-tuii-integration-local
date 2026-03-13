part of 'add_speaker_view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.selectedColor = SpeakerColor.black,
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedListeningAreaForDropDown,
    this.splResult,
    this.suggestedProductId,
    this.selectedTab = 0,
  });

  final SpeakerColor selectedColor;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;

  /// THIS WILL BE USED ONLY FOR SCHEMATIC PAGE WHEN THIS POPUP IS OPENED FROM THERE
  final ListeningArea? selectedListeningAreaForDropDown;

  /// SPL calculation result for suggest mode
  final SplMultiMountResult? splResult;

  /// The product ID the user picked in suggest mode
  final int? suggestedProductId;

  /// Active tab index for the frequency category tab bar
  final int selectedTab;

  SpeakerSelectionViewModelState copyWith({
    SpeakerColor? selectedColor,
    SpeakerSortOption? sortOption,
    String? searchQuery,
    bool? isLoading,
    List<SpeakerProduct>? speakers,
    ListeningArea? selectedListeningAreaForDropDown,
    SplMultiMountResult? splResult,
    int? suggestedProductId,
    int? selectedTab,
    bool clearSplResult = false,
    bool clearSuggestedProductId = false,
  }) {
    return SpeakerSelectionViewModelState(
      selectedColor: selectedColor ?? this.selectedColor,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      selectedListeningAreaForDropDown: selectedListeningAreaForDropDown ?? this.selectedListeningAreaForDropDown,
      splResult: clearSplResult ? null : (splResult ?? this.splResult),
      suggestedProductId: clearSuggestedProductId ? null : (suggestedProductId ?? this.suggestedProductId),
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedColor,
    sortOption,
    searchQuery,
    isLoading,
    selectedListeningAreaForDropDown,
    splResult,
    suggestedProductId,
    selectedTab,
  ];
}
