part of 'add_speaker_view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.selectedColor = SpeakerColor.black,
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedListeningAreaForDropDown,
    this.splResult,
    this.splResultSubwoofer,
    this.suggestedProductId,
    this.suggestedSubwooferProductId,
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

  /// SPL calculation result for subwoofers only (withSubwoofer mode)
  final SplMultiMountResult? splResultSubwoofer;

  /// The product ID the user picked in suggest mode (mid-high or full-range)
  final int? suggestedProductId;

  /// The subwoofer product ID the user picked in suggest mode (withSubwoofer only)
  final int? suggestedSubwooferProductId;

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
    SplMultiMountResult? splResultSubwoofer,
    int? suggestedProductId,
    int? suggestedSubwooferProductId,
    int? selectedTab,
    bool clearSplResult = false,
    bool clearSplResultSubwoofer = false,
    bool clearSuggestedProductId = false,
    bool clearSuggestedSubwooferProductId = false,
  }) {
    return SpeakerSelectionViewModelState(
      selectedColor: selectedColor ?? this.selectedColor,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      selectedListeningAreaForDropDown: selectedListeningAreaForDropDown ?? this.selectedListeningAreaForDropDown,
      splResult: clearSplResult ? null : (splResult ?? this.splResult),
      splResultSubwoofer: clearSplResultSubwoofer ? null : (splResultSubwoofer ?? this.splResultSubwoofer),
      suggestedProductId: clearSuggestedProductId ? null : (suggestedProductId ?? this.suggestedProductId),
      suggestedSubwooferProductId: clearSuggestedSubwooferProductId ? null : (suggestedSubwooferProductId ?? this.suggestedSubwooferProductId),
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
    splResultSubwoofer,
    suggestedProductId,
    suggestedSubwooferProductId,
    selectedTab,
  ];
}
