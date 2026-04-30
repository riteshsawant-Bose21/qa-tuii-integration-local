import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/assets/asset_svg.dart';
import '../../add_output_device_drawer/viewmodel/add_output_device_vm.dart';

enum SpeakerListenerHeightOption {
  seated,
  standing,
  custom;

  String get displayName {
    return switch (this) {
      SpeakerListenerHeightOption.seated => 'Seated (1.1 M)',
      SpeakerListenerHeightOption.standing => 'Standing (1.7 M)',
      SpeakerListenerHeightOption.custom => 'Custom',
    };
  }

  String get icon {
    return switch (this) {
      SpeakerListenerHeightOption.seated => AssetSvg.seated,
      SpeakerListenerHeightOption.standing => AssetSvg.standing,
      SpeakerListenerHeightOption.custom => AssetSvg.customHeight,
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

class SpeakerSelectionVmState extends Equatable {
  final String? listeningAreaId;
  final double? ceilingHeight;
  final double? floorHeight;
  final double? listeningHeight;
  final SpeakerListenerHeightOption listeningHeightOption;
  final SpeakerEnvironmentType environmentType;
  final List<MountingType> mountingTypes;
  final BackgroundNoise? backgroundNoise;
  final SpeakerMaxSplRange? maxSplRange;
  final double? lowFrequencyInHz;
  final SpeakerSelectionMode speakerSelectionMode;
  final AudioChannel audioChannel;
  final SpeakerColorOption speakerColorOption;
  final WiringType wiringType;
  final bool useSubwoofer;

  const SpeakerSelectionVmState({
    this.listeningAreaId,
    this.ceilingHeight,
    this.floorHeight,
    this.mountingTypes = const <MountingType>[],
    this.listeningHeight,
    this.listeningHeightOption = SpeakerListenerHeightOption.seated,
    this.environmentType = SpeakerEnvironmentType.indoor,
    this.backgroundNoise,
    this.maxSplRange,
    this.lowFrequencyInHz = 70.0, // in Hz
    this.speakerSelectionMode = SpeakerSelectionMode.select,
    this.audioChannel = AudioChannel.stereo,
    this.speakerColorOption = SpeakerColorOption.black,
    this.wiringType = WiringType.highImpedance,
    this.useSubwoofer = false,
  });

  @override
  List<Object?> get props => <Object?>[
    listeningAreaId,
    ceilingHeight,
    floorHeight,
    listeningHeight,
    listeningHeightOption,
    environmentType,
    mountingTypes,
    backgroundNoise,
    maxSplRange,
    lowFrequencyInHz,
    speakerSelectionMode,
    audioChannel,
    speakerColorOption,
    wiringType,
    useSubwoofer,
  ];

  SpeakerSelectionVmState copyWith({
    ValueGetter<String?>? listeningAreaId,
    ValueGetter<double?>? ceilingHeight,
    ValueGetter<double?>? floorHeight,
    ValueGetter<double?>? listeningHeight,
    ValueGetter<SpeakerListenerHeightOption>? listeningHeightOption,
    ValueGetter<SpeakerEnvironmentType>? environmentType,
    ValueGetter<List<MountingType>>? mountingTypes,
    ValueGetter<BackgroundNoise?>? backgroundNoise,
    ValueGetter<SpeakerMaxSplRange>? maxSplRange,
    ValueGetter<double?>? lowFrequencyInHz,
    ValueGetter<SpeakerSelectionMode>? speakerSelectionMode,
    ValueGetter<AudioChannel>? audioChannel,
    ValueGetter<SpeakerColorOption>? speakerColorOption,
    ValueGetter<WiringType>? wiringType,
    ValueGetter<bool>? useSubwoofer,
  }) {
    return SpeakerSelectionVmState(
      listeningAreaId: listeningAreaId != null ? listeningAreaId() : this.listeningAreaId,
      ceilingHeight: ceilingHeight != null ? ceilingHeight() : this.ceilingHeight,
      floorHeight: floorHeight != null ? floorHeight() : this.floorHeight,
      listeningHeight: listeningHeight != null ? listeningHeight() : this.listeningHeight,
      listeningHeightOption: listeningHeightOption != null ? listeningHeightOption() : this.listeningHeightOption,
      environmentType: environmentType != null ? environmentType() : this.environmentType,
      mountingTypes: mountingTypes != null ? mountingTypes() : this.mountingTypes,
      backgroundNoise: backgroundNoise != null ? backgroundNoise() : this.backgroundNoise,
      maxSplRange: maxSplRange != null ? maxSplRange() : this.maxSplRange,
      lowFrequencyInHz: lowFrequencyInHz != null ? lowFrequencyInHz() : this.lowFrequencyInHz,
      speakerSelectionMode: speakerSelectionMode != null ? speakerSelectionMode() : this.speakerSelectionMode,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      speakerColorOption: speakerColorOption != null ? speakerColorOption() : this.speakerColorOption,
      wiringType: wiringType != null ? wiringType() : this.wiringType,
      useSubwoofer: useSubwoofer != null ? useSubwoofer() : this.useSubwoofer,
    );
  }
}

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionVmState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionVmState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();
  void setListeningArea(String? areaId) => emit(state.copyWith(listeningAreaId: () => areaId));
  void setCeilingHeight(double? height) => emit(state.copyWith(ceilingHeight: () => height));
  void setFloorHeight(double? height) => emit(state.copyWith(floorHeight: () => height));
  void setListeningHeight(double? height) => emit(state.copyWith(listeningHeight: () => height));
  void setEnvironmentType(SpeakerEnvironmentType type) => emit(state.copyWith(environmentType: () => type));
  void setListeningHeightOption(SpeakerListenerHeightOption option) => emit(state.copyWith(listeningHeightOption: () => option));
  void setMountingType(MountingType type) => emit(state.copyWith(mountingTypes: () => <MountingType>[type]));
  void setBackgroundNoise(BackgroundNoise? noise) => emit(state.copyWith(backgroundNoise: () => noise));
  void setMaxSplRange(SpeakerMaxSplRange range) => emit(state.copyWith(maxSplRange: () => range));
  void setSpeakerSelectionMode(SpeakerSelectionMode mode) => emit(state.copyWith(speakerSelectionMode: () => mode));
  void setAudioChannel(AudioChannel option) => emit(state.copyWith(audioChannel: () => option));
  void setSpeakerColorOption(SpeakerColorOption option) => emit(state.copyWith(speakerColorOption: () => option));
  void setWiringType(WiringType option) => emit(state.copyWith(wiringType: () => option));
  void setLowFrequencyInHz(double frequency) => emit(state.copyWith(lowFrequencyInHz: () => frequency));
  void setUseSubwoofer(bool useSubwoofer) => emit(state.copyWith(useSubwoofer: () => useSubwoofer));
}
