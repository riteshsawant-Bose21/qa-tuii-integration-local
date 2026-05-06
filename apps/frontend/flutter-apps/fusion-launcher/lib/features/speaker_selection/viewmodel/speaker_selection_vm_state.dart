part of 'speaker_selection_vm.dart';

class SpeakerSelectionVmState extends Equatable {
  final String? listeningAreaId;

  // To add new listening area
  final bool shouldAddNewListeningArea;
  final String? floorId;
  final String? newListeningAreaName;

  final double? listeningHeight;
  final SpeakerSelectionMode speakerSelectionMode;
  final SpeakerSortOption sortOption;

  /// 0 = Mid-High/Full-Range tab, 1 = Subwoofer tab.
  /// Only relevant when [SelectModeArgs.useSubwoofer] is true.
  final int speakerListTab;

  final SpeakerSelectModeArgs selectModeArgs;
  final SpeakerSuggestModeArgs suggestModeArgs;
  final Set<int> expandSpeakerSpecs; // product_ids

  /// SPL calculation result for suggest mode.
  final SplMultiMountResult? splResult;

  /// SPL calculation result for subwoofers in suggest mode.
  final SplMultiMountResult? splResultSubwoofer;

  final List<SpeakerProduct> selectedSpeakers; // This can have mid/high/fullrange and subwoofers

  const SpeakerSelectionVmState({
    this.listeningAreaId,
    this.shouldAddNewListeningArea = false,
    this.floorId,
    this.newListeningAreaName,
    this.listeningHeight,
    this.speakerSelectionMode = SpeakerSelectionMode.select,
    this.selectModeArgs = const SpeakerSelectModeArgs(),
    this.suggestModeArgs = const SpeakerSuggestModeArgs(),
    this.splResult,
    this.splResultSubwoofer,
    this.selectedSpeakers = const <SpeakerProduct>[],
    this.sortOption = SpeakerSortOption.nameAsc,
    this.speakerListTab = 0,
    this.expandSpeakerSpecs = const <int>{},
  });

  @override
  List<Object?> get props => <Object?>[
    listeningAreaId,
    shouldAddNewListeningArea,
    floorId,
    newListeningAreaName,
    listeningHeight,
    speakerSelectionMode,
    selectModeArgs,
    suggestModeArgs,
    splResult,
    splResultSubwoofer,
    selectedSpeakers,
    sortOption,
    speakerListTab,
    expandSpeakerSpecs,
  ];

  SpeakerSelectionVmState copyWith({
    ValueGetter<String?>? listeningAreaId,
    ValueGetter<bool>? shouldAddNewListeningArea,
    ValueGetter<String?>? floorId,
    ValueGetter<String?>? newListeningAreaName,
    ValueGetter<double?>? listeningHeight,
    ValueGetter<SpeakerSelectionMode>? speakerSelectionMode,
    ValueGetter<SpeakerSelectModeArgs>? selectModeArgs,
    ValueGetter<SpeakerSuggestModeArgs>? suggestModeArgs,
    ValueGetter<SplMultiMountResult?>? splResult,
    ValueGetter<SplMultiMountResult?>? splResultSubwoofer,
    ValueGetter<List<SpeakerProduct>>? selectedSpeakers,
    ValueGetter<SpeakerSortOption>? sortOption,
    ValueGetter<int>? speakerListTab,
    ValueGetter<Set<int>>? expandSpeakerSpecs,
    bool clearSplResult = false,
    bool clearSplResultSubwoofer = false,
  }) {
    return SpeakerSelectionVmState(
      listeningAreaId: listeningAreaId != null ? listeningAreaId() : this.listeningAreaId,
      shouldAddNewListeningArea: shouldAddNewListeningArea != null ? shouldAddNewListeningArea() : this.shouldAddNewListeningArea,
      floorId: floorId != null ? floorId() : this.floorId,
      newListeningAreaName: newListeningAreaName != null ? newListeningAreaName() : this.newListeningAreaName,
      listeningHeight: listeningHeight != null ? listeningHeight() : this.listeningHeight,
      speakerSelectionMode: speakerSelectionMode != null ? speakerSelectionMode() : this.speakerSelectionMode,
      selectModeArgs: selectModeArgs != null ? selectModeArgs() : this.selectModeArgs,
      suggestModeArgs: suggestModeArgs != null ? suggestModeArgs() : this.suggestModeArgs,
      splResult: clearSplResult ? null : (splResult != null ? splResult() : this.splResult),
      splResultSubwoofer: clearSplResultSubwoofer ? null : (splResultSubwoofer != null ? splResultSubwoofer() : this.splResultSubwoofer),
      selectedSpeakers: selectedSpeakers != null ? selectedSpeakers() : this.selectedSpeakers,
      sortOption: sortOption != null ? sortOption() : this.sortOption,
      speakerListTab: speakerListTab != null ? speakerListTab() : this.speakerListTab,
      expandSpeakerSpecs: expandSpeakerSpecs != null ? expandSpeakerSpecs() : this.expandSpeakerSpecs,
    );
  }
}
