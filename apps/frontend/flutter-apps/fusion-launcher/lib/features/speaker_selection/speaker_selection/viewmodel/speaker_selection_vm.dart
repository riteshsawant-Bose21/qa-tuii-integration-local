import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';

import '../../../../core/assets/asset_svg.dart';
import '../../../add_output_device_drawer/viewmodel/add_output_device_vm.dart';
import '../../../speaker_selection_popup/views/widgets/constant_enums.dart';

part 'speaker_selection_vm_state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionVmState> {
  final bool isFromBuildingPage;
  SpeakerSelectionViewModel({this.isFromBuildingPage = false}) : super(const SpeakerSelectionVmState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController floorHeightController = TextEditingController();
  final TextEditingController customListenerHeightController = TextEditingController();

  /// ----------------------------------- GET PRODUCTS ------------------------------------
  // Show here products based on criterias.
  List<SpeakerProduct> get speakers {
    final ProductQueryViewModel productQueryViewModel = serviceLocator<ProductQueryViewModel>();
    Iterable<SpeakerProduct> filtered = productQueryViewModel.speakers;
    final SelectModeArgs args = state.selectModeArgs;

    final String query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct product) {
        final String searchableText = '${product.modelName} ${product.description}'.toLowerCase();
        return searchableText.contains(query);
      });
    }

    if (args.mountingTypes.isNotEmpty) {
      final List<String> mountingKeys = args.mountingTypes.map((MountingType type) => type.name.toLowerCase()).toList();
      filtered = filtered.where((SpeakerProduct product) {
        final String mountType = (product.mountType ?? '').toLowerCase();
        return mountingKeys.any(mountType.contains);
      });
    }

    if (args.maxSplRange != null) {
      filtered = filtered.where((SpeakerProduct product) {
        final List<double> values = product.maxSpl?.at.map((MeasurementValue value) => value.value.toDouble()).toList() ?? const <double>[];
        if (values.isEmpty) return true;

        final double maxSpl = values.reduce((double a, double b) => a > b ? a : b);

        switch (args.maxSplRange!) {
          case SpeakerMaxSplRange.lessThan105db:
            return maxSpl < 105;
          case SpeakerMaxSplRange.range105to115db:
            return maxSpl >= 105 && maxSpl <= 115;
          case SpeakerMaxSplRange.greaterThan115db:
            return maxSpl > 115;
        }
      });
    }

    final bool wantsHighImpedance = args.wiringType == WiringType.highImpedance;
    filtered = filtered.where((SpeakerProduct product) {
      final bool hasHighImpedance =
          product.isHighImpedanceRated ||
          (product.availableTaps?.taps70V.isNotEmpty ?? false) ||
          (product.availableTaps?.taps100V.isNotEmpty ?? false) ||
          product.highImpedanceTaps.isNotEmpty;
      final bool hasLowImpedance = product.nominalImpedance != null || product.impedance != null;
      return wantsHighImpedance ? hasHighImpedance : hasLowImpedance;
    });

    final String wantedColor = args.speakerColorOption.name.toLowerCase();
    final List<SpeakerProduct> colorFiltered =
        filtered.where((SpeakerProduct product) {
          if (product.assets.assets.isEmpty) return false;
          return product.assets.assets.entries.any((MapEntry<String, List<String>> entry) {
            return entry.key.toLowerCase() == wantedColor && entry.value.isNotEmpty;
          });
        }).toList();

    if (colorFiltered.isNotEmpty) {
      filtered = colorFiltered;
    }

    if (!args.useSubwoofer) {
      // No subwoofer mode: always show only full-range/mid-high speakers
      filtered = filtered.where((SpeakerProduct product) => !product.isSubwoofer);
    } else {
      // With subwoofer mode: filter based on active tab
      // Tab 0 = Mid-High (non-subwoofer), Tab 1 = Subwoofer
      if (state.speakerListTab == 0) {
        filtered = filtered.where((SpeakerProduct product) => !product.isSubwoofer);
      } else {
        filtered = filtered.where((SpeakerProduct product) => product.isSubwoofer);
      }
    }

    return filtered.toList();
  }

  ListeningArea get selectedListeningArea => projectViewModel.getListeningArea(areaId: state.listeningAreaId!);

  /// -------------------------------- METHODS TO UPDATE STATE ----------------------------
  /// RELATED TO LISTENING AREA
  ///
  void setListeningArea(String? areaId) {
    emit(state.copyWith(listeningAreaId: () => areaId));

    ceilingHeightController.text = selectedListeningArea.ceilingHeight.toString();
    floorHeightController.text = selectedListeningArea.floorHeight.toString();
    customListenerHeightController.text = selectedListeningArea.listeningHeight.toString();
  }

  void setCeilingHeight(double? height) => projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(ceilingHeight: height?.toString()));
  void setFloorHeight(double? height) => projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(floorHeight: height));
  void setListeningHeight(double? height) => projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(listeningHeight: height));
  void setEnvironmentType(SpeakerEnvironmentType type) => projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(environmentType: type));
  void setBackgroundNoise(BackgroundNoise? noise) => projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(backgroundNoise: noise));

  void setListeningHeightOption(ListeningHeightOption option) {
    projectViewModel.updateListeningArea(
      area: selectedListeningArea.copyWith(
        listeningHeightOption: option,
        listeningHeight: ListeningHeightOption.getValue(option) ?? 1.7,
      ),
    );
  }

  void setSpeakerSelectionMode(SpeakerSelectionMode mode) => emit(state.copyWith(speakerSelectionMode: () => mode));
  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: () => option));
  void setSpeakerListTab(int tab) => emit(state.copyWith(speakerListTab: () => tab));

  /// RELATED TO SPEAKER SELECTION - MANUAL PROCESS
  void updatedSelectModeArgs(Function(SelectModeArgs args) updates) {
    final SelectModeArgs updatedArgs = updates(state.selectModeArgs);
    emit(state.copyWith(selectModeArgs: () => updatedArgs));
  }

  void setMountingType(MountingType type) => updatedSelectModeArgs((SelectModeArgs args) {
    final List<MountingType> current = List<MountingType>.from(args.mountingTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    return args.copyWith(mountingTypes: () => current);
  });

  void setMaxSplRange(SpeakerMaxSplRange range) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(maxSplRange: () => range));
  void setAudioChannel(AudioChannel option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(audioChannel: () => option));
  void setSpeakerColor(SpeakerColorOption option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(speakerColorOption: () => option));
  void setWiringType(WiringType option) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(wiringType: () => option));
  void setLowFrequencyInHz(double frequency) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(lowFrequencyInHz: () => frequency));

  void setUseSubwoofer(bool useSubwoofer) {
    final List<SpeakerProduct> updatedSpeakers = List<SpeakerProduct>.from(state.selectedSpeakers);
    if (!useSubwoofer) updatedSpeakers.removeWhere((SpeakerProduct sp) => sp.isSubwoofer);
    updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(useSubwoofer: () => useSubwoofer));
    emit(
      state.copyWith(
        selectedSpeakers: () => updatedSpeakers,
        speakerListTab: () => 0, // reset to Mid-High tab
      ),
    );
  }

  void setMonoSubwoofer(bool monoSubwoofer) => updatedSelectModeArgs((SelectModeArgs args) => args.copyWith(monoSubwoofer: () => monoSubwoofer));

  bool isSpeakerSpecsExpanded(int productId) => state.expandSpeakerSpecs.contains(productId);

  void toggleSpeakerSpecs(int productId) {
    final Set<int> expanded = Set<int>.from(state.expandSpeakerSpecs);
    if (expanded.contains(productId)) {
      expanded.remove(productId);
    } else {
      expanded.add(productId);
    }
    emit(state.copyWith(expandSpeakerSpecs: () => expanded));
  }

  void addSpeaker({required SpeakerProduct speaker}) {
    if (state.speakerSelectionMode == SpeakerSelectionMode.suggest) {
      // In suggest mode, we only allow one speaker to be added
      emit(state.copyWith(selectedSpeakers: () => <SpeakerProduct>[speaker]));
    } else {
      final List<SpeakerProduct> updatedSpeakers = List<SpeakerProduct>.from(state.selectedSpeakers);
      if (state.selectModeArgs.useSubwoofer && speaker.isSubwoofer) {
        updatedSpeakers.removeWhere((SpeakerProduct sp) => sp.isSubwoofer);
        updatedSpeakers.add(speaker);
      } else if (!speaker.isSubwoofer) {
        updatedSpeakers.removeWhere((SpeakerProduct sp) => !sp.isSubwoofer);
        updatedSpeakers.add(speaker);
      }

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
