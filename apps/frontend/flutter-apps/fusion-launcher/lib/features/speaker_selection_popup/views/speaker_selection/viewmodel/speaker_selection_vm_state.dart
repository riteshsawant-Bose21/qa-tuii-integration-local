part of 'speaker_selection_vm.dart';

class SpeakerSelectionVmState extends Equatable {
  final String? listeningAreaId;
  final double? ceilingHeight;
  final double? floorHeight;
  final double? listeningHeight;
  final ListeningHeightOption listeningHeightOption;
  final SpeakerEnvironmentType environmentType;
  final BackgroundNoise? backgroundNoise;

  final SpeakerSelectionMode speakerSelectionMode;

  // Filter Options
  final SelectModeArgs selectModeArgs;
  final SuggestModeArgs suggestModeArgs;

  final List<SpeakerProduct> selectedSpeakers; // This can have mid/high/fullrange and subwoofers

  const SpeakerSelectionVmState({
    this.listeningAreaId,
    this.ceilingHeight,
    this.floorHeight,
    this.listeningHeight,
    this.listeningHeightOption = ListeningHeightOption.sitting,
    this.environmentType = SpeakerEnvironmentType.indoor,
    this.backgroundNoise,
    this.speakerSelectionMode = SpeakerSelectionMode.select,
    this.selectModeArgs = const SelectModeArgs(),
    this.suggestModeArgs = const SuggestModeArgs(),
    this.selectedSpeakers = const <SpeakerProduct>[],
  });

  @override
  List<Object?> get props => <Object?>[
    listeningAreaId,
    ceilingHeight,
    floorHeight,
    listeningHeight,
    listeningHeightOption,
    environmentType,
    backgroundNoise,
    speakerSelectionMode,
    selectModeArgs,
    suggestModeArgs,
    selectedSpeakers,
  ];

  SpeakerSelectionVmState copyWith({
    ValueGetter<String?>? listeningAreaId,
    ValueGetter<double?>? ceilingHeight,
    ValueGetter<double?>? floorHeight,
    ValueGetter<double?>? listeningHeight,
    ValueGetter<ListeningHeightOption>? listeningHeightOption,
    ValueGetter<SpeakerEnvironmentType>? environmentType,
    ValueGetter<BackgroundNoise?>? backgroundNoise,
    ValueGetter<SpeakerSelectionMode>? speakerSelectionMode,
    ValueGetter<SelectModeArgs>? selectModeArgs,
    ValueGetter<SuggestModeArgs>? suggestModeArgs,
    ValueGetter<List<SpeakerProduct>>? selectedSpeakers,
  }) {
    return SpeakerSelectionVmState(
      listeningAreaId: listeningAreaId != null ? listeningAreaId() : this.listeningAreaId,
      ceilingHeight: ceilingHeight != null ? ceilingHeight() : this.ceilingHeight,
      floorHeight: floorHeight != null ? floorHeight() : this.floorHeight,
      listeningHeight: listeningHeight != null ? listeningHeight() : this.listeningHeight,
      listeningHeightOption: listeningHeightOption != null ? listeningHeightOption() : this.listeningHeightOption,
      environmentType: environmentType != null ? environmentType() : this.environmentType,
      backgroundNoise: backgroundNoise != null ? backgroundNoise() : this.backgroundNoise,
      speakerSelectionMode: speakerSelectionMode != null ? speakerSelectionMode() : this.speakerSelectionMode,
      selectModeArgs: selectModeArgs != null ? selectModeArgs() : this.selectModeArgs,
      suggestModeArgs: suggestModeArgs != null ? suggestModeArgs() : this.suggestModeArgs,
      selectedSpeakers: selectedSpeakers != null ? selectedSpeakers() : this.selectedSpeakers,
    );
  }
}
