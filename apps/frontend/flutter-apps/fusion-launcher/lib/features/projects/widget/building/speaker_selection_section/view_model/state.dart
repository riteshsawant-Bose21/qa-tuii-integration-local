part of 'view_model.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.mode = SpeakerSelectionMode.select,
    this.selectedMountingTypes = const <MountingType>{},
    this.selectedLowFrequencies = const <LowFrequency>{},
    this.selectedColors = const <SpeakerColor>{},
    this.selectedWirings = const <WiringType>{},
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.speakers,
    this.selectedSignalType = SignalType.mono,
  });

  final SpeakerSelectionMode mode;
  final Set<MountingType> selectedMountingTypes;
  final Set<LowFrequency> selectedLowFrequencies;
  final Set<SpeakerColor> selectedColors;
  final Set<WiringType> selectedWirings;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;
  final List<SpeakerProduct>? speakers;
  final SignalType selectedSignalType;

  SpeakerSelectionViewModelState copyWith({
    SpeakerSelectionMode? mode,
    Set<MountingType>? selectedMountingTypes,
    Set<LowFrequency>? selectedLowFrequencies,
    Set<SpeakerColor>? selectedColors,
    Set<WiringType>? selectedWirings,
    SpeakerSortOption? sortOption,
    String? searchQuery,
    bool? isLoading,
    List<SpeakerProduct>? speakers,
  }) {
    return SpeakerSelectionViewModelState(
      mode: mode ?? this.mode,
      selectedMountingTypes: selectedMountingTypes ?? this.selectedMountingTypes,
      selectedLowFrequencies: selectedLowFrequencies ?? this.selectedLowFrequencies,
      selectedColors: selectedColors ?? this.selectedColors,
      selectedWirings: selectedWirings ?? this.selectedWirings,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      speakers: speakers ?? this.speakers,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    mode,
    selectedMountingTypes,
    selectedLowFrequencies,
    selectedColors,
    selectedWirings,
    sortOption,
    searchQuery,
    isLoading,
    speakers,
  ];
}
