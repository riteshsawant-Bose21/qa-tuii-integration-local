part of 'speaker_selection_vm.dart';

class SpeakerSelectionVmState extends Equatable {
  final String? listeningAreaId;
  final double? listeningHeight;
  final SpeakerEnvironmentType environmentType;
  final BackgroundNoise? backgroundNoise;

  final SpeakerSelectionMode speakerSelectionMode;

  final SpeakerSortOption sortOption;

  /// 0 = Mid-High/Full-Range tab, 1 = Subwoofer tab.
  /// Only relevant when [SelectModeArgs.useSubwoofer] is true.
  final int speakerListTab;

  // Filter Options
  final SelectModeArgs selectModeArgs;
  final SuggestModeArgs suggestModeArgs;
  final Set<int> expandSpeakerSpecs; // product_ids

  final List<SpeakerProduct> selectedSpeakers; // This can have mid/high/fullrange and subwoofers

  const SpeakerSelectionVmState({
    this.listeningAreaId,
    this.listeningHeight,
    this.environmentType = SpeakerEnvironmentType.indoor,
    this.backgroundNoise,
    this.speakerSelectionMode = SpeakerSelectionMode.select,
    this.selectModeArgs = const SelectModeArgs(),
    this.suggestModeArgs = const SuggestModeArgs(),
    this.selectedSpeakers = const <SpeakerProduct>[],
    this.sortOption = SpeakerSortOption.nameAsc,
    this.speakerListTab = 0,
    this.expandSpeakerSpecs = const <int>{},
  });

  @override
  List<Object?> get props => <Object?>[
    listeningAreaId,
    listeningHeight,
    environmentType,
    backgroundNoise,
    speakerSelectionMode,
    selectModeArgs,
    suggestModeArgs,
    selectedSpeakers,
    sortOption,
    speakerListTab,
    expandSpeakerSpecs,
  ];

  SpeakerSelectionVmState copyWith({
    ValueGetter<String?>? listeningAreaId,
    ValueGetter<double?>? listeningHeight,
    ValueGetter<SpeakerEnvironmentType>? environmentType,
    ValueGetter<BackgroundNoise?>? backgroundNoise,
    ValueGetter<SpeakerSelectionMode>? speakerSelectionMode,
    ValueGetter<SelectModeArgs>? selectModeArgs,
    ValueGetter<SuggestModeArgs>? suggestModeArgs,
    ValueGetter<List<SpeakerProduct>>? selectedSpeakers,
    ValueGetter<SpeakerSortOption>? sortOption,
    ValueGetter<int>? speakerListTab,
    ValueGetter<Set<int>>? expandSpeakerSpecs,
  }) {
    return SpeakerSelectionVmState(
      listeningAreaId: listeningAreaId != null ? listeningAreaId() : this.listeningAreaId,
      listeningHeight: listeningHeight != null ? listeningHeight() : this.listeningHeight,
      environmentType: environmentType != null ? environmentType() : this.environmentType,
      backgroundNoise: backgroundNoise != null ? backgroundNoise() : this.backgroundNoise,
      speakerSelectionMode: speakerSelectionMode != null ? speakerSelectionMode() : this.speakerSelectionMode,
      selectModeArgs: selectModeArgs != null ? selectModeArgs() : this.selectModeArgs,
      suggestModeArgs: suggestModeArgs != null ? suggestModeArgs() : this.suggestModeArgs,
      selectedSpeakers: selectedSpeakers != null ? selectedSpeakers() : this.selectedSpeakers,
      sortOption: sortOption != null ? sortOption() : this.sortOption,
      speakerListTab: speakerListTab != null ? speakerListTab() : this.speakerListTab,
      expandSpeakerSpecs: expandSpeakerSpecs != null ? expandSpeakerSpecs() : this.expandSpeakerSpecs,
    );
  }
}
