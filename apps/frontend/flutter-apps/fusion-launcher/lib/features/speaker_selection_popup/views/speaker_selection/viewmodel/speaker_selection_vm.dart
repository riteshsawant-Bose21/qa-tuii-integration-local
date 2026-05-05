import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';

import '../../../../../core/assets/asset_svg.dart';
import '../../../../add_output_device_drawer/viewmodel/add_output_device_vm.dart';
import '../../widgets/constant_enums.dart';

part 'speaker_selection_vm_state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionVmState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionVmState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();
  final TextEditingController searchController = TextEditingController();

  /// -------------------------------- METHODS TO UPDATE STATE ---------------------------- ----
  /// RELATED TO LISTENING AREA
  ///
  void setListeningArea(String? areaId) => emit(state.copyWith(listeningAreaId: () => areaId));
  void setCeilingHeight(double? height) => emit(state.copyWith(ceilingHeight: () => height));
  void setFloorHeight(double? height) => emit(state.copyWith(floorHeight: () => height));
  void setListeningHeight(double? height) => emit(state.copyWith(listeningHeight: () => height));
  void setEnvironmentType(SpeakerEnvironmentType type) => emit(state.copyWith(environmentType: () => type));
  void setBackgroundNoise(BackgroundNoise? noise) => emit(state.copyWith(backgroundNoise: () => noise));
  void setListeningHeightOption(ListeningHeightOption option) {
    emit(
      state.copyWith(
        listeningHeightOption: () => option,
        listeningHeight: () => option == ListeningHeightOption.custom ? state.listeningHeight : ListeningHeightOption.getValue(option)!,
      ),
    );
  }

  void setSpeakerSelectionMode(SpeakerSelectionMode mode) => emit(state.copyWith(speakerSelectionMode: () => mode));

  /// RELATED TO SPEAKER SELECTION - MANUAL PROCESS
  void updatedSelectModeArgs(Function(SelectModeArgs args) updates) {
    final SelectModeArgs updatedArgs = updates(state.selectModeArgs);
    emit(state.copyWith(selectModeArgs: () => updatedArgs));
  }

  void setMountingType(MountingType type) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(mountingTypes: () => <MountingType>[type]));
  void setMaxSplRange(SpeakerMaxSplRange range) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(maxSplRange: () => range));
  void setAudioChannel(AudioChannel option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(audioChannel: () => option));
  void setSpeakerColor(SpeakerColorOption option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(speakerColorOption: () => option));
  void setWiringType(WiringType option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(wiringType: () => option));
  void setLowFrequencyInHz(double frequency) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(lowFrequencyInHz: () => frequency));
  void setUseSubwoofer(bool useSubwoofer) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(useSubwoofer: () => useSubwoofer));
  void setMonoSubwoofer(bool monoSubwoofer) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(monoSubwoofer: () => monoSubwoofer));


  void addSpeaker({required SpeakerProduct speaker}) {
    if (state.speakerSelectionMode == SpeakerSelectionMode.suggest) {
      // In suggest mode, we only allow one speaker to be added
      emit(state.copyWith(selectedSpeakers: () => <SpeakerProduct>[speaker]));
    } else {
      // In the list, only two speakers should be there, one mid/high and one subwoofer.
      // If the new speaker is a mid/high, we will remove the existing mid/high and add the new one.
      // If the new speaker is a subwoofer, we will remove the existing subwoofer and add the new one.
      final List<SpeakerProduct> updatedSpeakers = List<SpeakerProduct>.from(state.selectedSpeakers);
      if (state.selectModeArgs.useSubwoofer && speaker.isSubwoofer) {
        updatedSpeakers.removeWhere((SpeakerProduct sp) => sp.isSubwoofer);
      } else if (!speaker.isSubwoofer) {
        updatedSpeakers.removeWhere((SpeakerProduct sp) => !sp.isSubwoofer);
      }
      updatedSpeakers.add(speaker);

      emit(state.copyWith(selectedSpeakers: () => updatedSpeakers));
    }
  }

  void removeSpeaker({required SpeakerProduct speaker}) {
    final List<SpeakerProduct> updatedSpeakers = List<SpeakerProduct>.from(state.selectedSpeakers)..remove(speaker);
    emit(state.copyWith(selectedSpeakers: () => updatedSpeakers));
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}

extension SpeakerListenerHeightExt on ListeningHeightOption {
  String get icon {
    return switch (this) {
      ListeningHeightOption.sitting => AssetSvg.seated,
      ListeningHeightOption.standing => AssetSvg.standing,
      ListeningHeightOption.custom => AssetSvg.customHeight,
    };
  }
}

extension SpeakerEnvTpyeExt on SpeakerEnvironmentType {
  String get icon {
    return switch (this) {
      SpeakerEnvironmentType.indoor => AssetSvg.indoorEnv,
      SpeakerEnvironmentType.outdoor => AssetSvg.outdoorEnv,
    };
  }
}

extension MountingTypeExt on MountingType {
  String get icon {
    switch (this) {
      case MountingType.surface:
        return AssetSvg.surfaceSpeaker;
      case MountingType.pendant:
        return AssetSvg.pendantSpeaker;
      case MountingType.ceiling:
        return AssetSvg.ceilingSpeaker;
    }
  }
}

// ignore: constant_identifier_names
enum SpeakerMaxSplRange {
  lessThan105db,
  range105to115db,
  greaterThan115db;

  String get displayName {
    switch (this) {
      case SpeakerMaxSplRange.lessThan105db:
        return '< 105dB';
      case SpeakerMaxSplRange.range105to115db:
        return '105 - 115 dB';
      case SpeakerMaxSplRange.greaterThan115db:
        return '> 115dB';
    }
  }
}

enum SpeakerColorOption {
  black,
  white;

  String get displayName {
    switch (this) {
      case SpeakerColorOption.black:
        return 'Black';
      case SpeakerColorOption.white:
        return 'White';
    }
  }
}

class SelectModeArgs extends Equatable {
  final List<MountingType> mountingTypes;
  final SpeakerMaxSplRange? maxSplRange;
  final SpeakerColorOption speakerColorOption;
  final double lowFrequencyInHz;
  final AudioChannel audioChannel;
  final WiringType wiringType;
  final bool useSubwoofer;
  final bool monoSubwoofer;

  const SelectModeArgs({
    this.mountingTypes = const <MountingType>[],
    this.maxSplRange,
    this.speakerColorOption = SpeakerColorOption.black,
    this.lowFrequencyInHz = 70.0, // in Hz
    this.audioChannel = AudioChannel.stereo,
    this.wiringType = WiringType.highImpedance,
    this.useSubwoofer = false,
    this.monoSubwoofer = false,
  });

  @override
  List<Object?> get props => <Object?>[
    mountingTypes,
    maxSplRange,
    speakerColorOption,
    lowFrequencyInHz,
    audioChannel,
    wiringType,
    useSubwoofer,
    monoSubwoofer,
  ];

  SelectModeArgs copyWith({
    ValueGetter<List<MountingType>>? mountingTypes,
    ValueGetter<SpeakerMaxSplRange?>? maxSplRange,
    ValueGetter<SpeakerColorOption>? speakerColorOption,
    ValueGetter<double>? lowFrequencyInHz,
    ValueGetter<AudioChannel>? audioChannel,
    ValueGetter<WiringType>? wiringType,
    ValueGetter<bool>? useSubwoofer,
    ValueGetter<bool>? monoSubwoofer,
  }) {
    return SelectModeArgs(
      mountingTypes: mountingTypes != null ? mountingTypes() : this.mountingTypes,
      maxSplRange: maxSplRange != null ? maxSplRange() : this.maxSplRange,
      speakerColorOption: speakerColorOption != null ? speakerColorOption() : this.speakerColorOption,
      lowFrequencyInHz: lowFrequencyInHz != null ? lowFrequencyInHz() : this.lowFrequencyInHz,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      wiringType: wiringType != null ? wiringType() : this.wiringType,
      useSubwoofer: useSubwoofer != null ? useSubwoofer() : this.useSubwoofer,
      monoSubwoofer: monoSubwoofer != null ? monoSubwoofer() : this.monoSubwoofer,
    );
  }
}

class SuggestModeArgs extends Equatable {
  final MountingType mountingType;
  final double splRangeMin;
  final double splRangeMax;
  final LowFrequency lowFrequency;

  const SuggestModeArgs({
    this.mountingType = MountingType.surface,
    this.splRangeMin = 60.0,
    this.splRangeMax = 70.0,
    this.lowFrequency = LowFrequency.fullRange,
  });

  @override
  List<Object?> get props => <Object?>[mountingType, splRangeMin, splRangeMax, lowFrequency];

  SuggestModeArgs copyWith({
    ValueGetter<MountingType>? mountingType,
    ValueGetter<double>? splRangeMin,
    ValueGetter<double>? splRangeMax,
    ValueGetter<LowFrequency>? lowFrequency,
  }) {
    return SuggestModeArgs(
      mountingType: mountingType != null ? mountingType() : this.mountingType,
      splRangeMin: splRangeMin != null ? splRangeMin() : this.splRangeMin,
      splRangeMax: splRangeMax != null ? splRangeMax() : this.splRangeMax,
      lowFrequency: lowFrequency != null ? lowFrequency() : this.lowFrequency,
    );
  }
}
