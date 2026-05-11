import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';

import '../../../core/assets/asset_svg.dart';
import '../../speaker_selection_popup/views/widgets/constant_enums.dart';

part 'speaker_selection_vm_state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionVmState> {
  final bool isFromBuildingPage;
  final String? zoneId, subZoneId;
  SpeakerSelectionViewModel({this.isFromBuildingPage = false, required this.zoneId, required this.subZoneId}) : super(const SpeakerSelectionVmState()) {
    if (isFromBuildingPage) {
      final String? areaId = serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea()?.id;
      if (areaId != null) setListeningArea(areaId);
    } else {
      final String? defaultAreaId = getListeningAreas().firstOrNull?.id;
      setListeningArea(defaultAreaId);
    }
  }

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController floorHeightController = TextEditingController();
  final TextEditingController customListenerHeightController = TextEditingController();

  List<ListeningArea> getListeningAreas() {
    List<ListeningArea> allListeningAreas = <ListeningArea>[];
    if (subZoneId != null) {
      // allListeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: subZoneId!);
      allListeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: subZoneId!);
    } else if (zoneId != null) {
      allListeningAreas = projectViewModel.getListeningAreasForZone(zoneId: zoneId!);
    } else {
      allListeningAreas = projectViewModel.getAllListeningAreas();
    }

    return allListeningAreas;
  }

  // void toggleAddNewListeningArea(bool value) {
  //   emit(
  //     state.copyWith(
  //       shouldAddNewListeningArea: () => value,
  //       listeningAreaId: () => value ? null : state.listeningAreaId,
  //     ),
  //   );
  // }

  // void setNewListeningAreaName(String? value) => emit(state.copyWith(newListeningAreaName: () => value));
  // void setNewListeningAreaFloorId(String? value) => emit(state.copyWith(floorId: () => value));

  // void addNewListeningArea(BuildContext context) {
  // if (state.newListeningAreaName?.isEmpty ?? false) return FusionToast.error(context, message: "Please enter listening area name");
  // if (state.floorId?.isEmpty ?? true) return FusionToast.error(context, message: "Please select floor");

  // final ListeningArea newArea = ListeningArea(name: state.newListeningAreaName!, vertices: <FusionCanvasPoint>[], isDrawn: false);

  // projectViewModel.addListeningArea(area: newArea, floorId: state.floorId!);

  // if (subZoneId != null) {
  //   projectViewModel.addListeningAreaToSubZone(areaId: newArea.id, subZoneId: subZoneId!);
  // } else {
  //   projectViewModel.addListeningAreaToZone(listeningAreaId: newArea.id, zoneId: zoneId!);
  // }

  // emit(state.copyWith(listeningAreaId: () => newArea.id, shouldAddNewListeningArea: () => false));
  // }

  /// ----------------------------------- GET PRODUCTS ------------------------------------
  // Show here products based on criterias.
  List<SpeakerProduct> get speakers {
    final ProductQueryViewModel productQueryViewModel = serviceLocator<ProductQueryViewModel>();

    if (state.speakerSelectionMode == SpeakerSelectionMode.suggest) {
      return getSuggestedSpeakers(productQueryViewModel.speakers);
    }

    Iterable<SpeakerProduct> filtered = productQueryViewModel.speakers;
    final SpeakerSelectModeArgs args = state.selectModeArgs;

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

    // Low frequency slider: keep speakers that can extend down to the selected
    // cutoff frequency (lower/equal low-end frequency is better).
    filtered = filtered.where((SpeakerProduct product) {
      final FrequencyRange? range = product.frequencyRange;
      if (range == null) return true;
      if (range.low <= 0) return true;
      return range.low <= args.lowFrequencyInHz;
    });

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

    // Channel filter: map mono/stereo to available passbands.
    // If catalog metadata is missing, keep the product visible.
    filtered = filtered.where((SpeakerProduct product) {
      final int? passbands = product.noOfPassbands;
      if (passbands == null || passbands <= 0) return true;

      return switch (args.audioChannel) {
        AudioChannel.mono => passbands <= 1,
        AudioChannel.stereo => passbands >= 2,
      };
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

    return _sortProducts(filtered.toList());
  }

  List<SpeakerProduct> _sortProducts(List<SpeakerProduct> items) {
    final List<SpeakerProduct> copy = List<SpeakerProduct>.from(items);
    final ProductQueryViewModel productQueryViewModel = serviceLocator<ProductQueryViewModel>();

    double maxSplValue(MaxSpl? maxSpl) {
      if (maxSpl == null || maxSpl.at.isEmpty) return 0.0;
      final Iterable<double> values = maxSpl.at.map((MeasurementValue e) => e.value);
      return values.reduce((double a, double b) => a > b ? a : b);
    }

    num powerHandlingValue(PowerHandling? powerHandling) {
      if (powerHandling == null) return 0;
      if (powerHandling.longTermRms != 0) return powerHandling.longTermRms;
      if (powerHandling.peak != 0) return powerHandling.peak;
      return 0;
    }

    int compareByOption(SpeakerProduct a, SpeakerProduct b) {
      switch (state.sortOption) {
        case SpeakerSortOption.nameAsc:
          return a.modelName.toLowerCase().compareTo(b.modelName.toLowerCase());
        case SpeakerSortOption.nameDesc:
          return b.modelName.toLowerCase().compareTo(a.modelName.toLowerCase());
        case SpeakerSortOption.priceLowToHigh:
          return productQueryViewModel.getPrice(a.productId).compareTo(productQueryViewModel.getPrice(b.productId));
        case SpeakerSortOption.priceHighToLow:
          return productQueryViewModel.getPrice(b.productId).compareTo(productQueryViewModel.getPrice(a.productId));
        case SpeakerSortOption.maxSplHighToLow:
          return maxSplValue(b.maxSpl).compareTo(maxSplValue(a.maxSpl));
        case SpeakerSortOption.maxSplLowToHigh:
          return maxSplValue(a.maxSpl).compareTo(maxSplValue(b.maxSpl));
        case SpeakerSortOption.powerHandlingHighToLow:
          return powerHandlingValue(b.powerHandling).compareTo(powerHandlingValue(a.powerHandling));
        case SpeakerSortOption.powerHandlingLowToHigh:
          return powerHandlingValue(a.powerHandling).compareTo(powerHandlingValue(b.powerHandling));
      }
    }

    copy.sort(compareByOption);
    return copy;
  }

  ListeningArea get selectedListeningArea => projectViewModel.getListeningArea(areaId: state.listeningAreaId!);

  List<SpeakerProduct> _getSelectedProductsForListeningArea(String areaId) {
    final List<SpeakerProduct> catalog = serviceLocator<ProductQueryViewModel>().speakers;
    final List<Speaker> existingSpeakers = projectViewModel.getListeningAreaSpeakers(areaId: areaId);

    final Set<int> seenProductIds = <int>{};
    return existingSpeakers
        .map((Speaker speaker) => catalog.firstWhereOrNull((SpeakerProduct sp) => sp.productId == speaker.productId))
        .whereType<SpeakerProduct>()
        .where((SpeakerProduct product) => seenProductIds.add(product.productId))
        .toList();
  }

  /// -------------------------------- METHODS TO UPDATE STATE ----------------------------
  /// RELATED TO LISTENING AREA
  ///
  void setListeningArea(String? areaId) {
    if (areaId == null) {
      emit(
        state.copyWith(
          listeningAreaId: () => null,
          selectedSpeakers: () => <SpeakerProduct>[],
        ),
      );
      return;
    }

    // Temporarily set the id so selectedListeningArea getter works.
    emit(state.copyWith(listeningAreaId: () => areaId));

    final ListeningArea la = selectedListeningArea;

    // Hydrate ALL previously saved settings from the LA into state.
    emit(
      state.copyWith(
        speakerSelectionMode: () => la.speakerSelectionMode,
        selectModeArgs: () => la.speakerSelectModeArgs,
        suggestModeArgs: () => la.speakerSuggestModeArgs,
        selectedSpeakers: () => _getSelectedProductsForListeningArea(areaId),
      ),
    );

    ceilingHeightController.text = la.ceilingHeight.toString();
    floorHeightController.text = la.floorHeight.toString();
    customListenerHeightController.text = la.listeningHeight.toString();

    _recalculateIfSuggestMode();
  }

  void setCeilingHeight(double height) {
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(ceilingHeight: height));
    _recalculateIfSuggestMode();
  }

  void setFloorHeight(double? height) {
    final double safe = (height ?? 4.0).clamp(0.0, double.infinity);
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(floorHeight: safe));
  }

  void setListeningHeight(double? height) {
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(listeningHeight: height));
    _recalculateIfSuggestMode();
  }

  void setEnvironmentType(SpeakerEnvironmentType type) {
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(environmentType: type));
    _recalculateIfSuggestMode();
  }

  void setBackgroundNoise(BackgroundNoise? noise) {
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(backgroundNoise: noise));
    _recalculateIfSuggestMode();
  }

  void setListeningHeightOption(ListeningHeightOption option) {
    projectViewModel.updateListeningArea(
      area: selectedListeningArea.copyWith(
        listeningHeightOption: option,
        listeningHeight: ListeningHeightOption.getValue(option) ?? 1.7,
      ),
    );
    _recalculateIfSuggestMode();
  }

  void setSpeakerSelectionMode(SpeakerSelectionMode mode) {
    final bool hasModeChanged = state.speakerSelectionMode != mode;

    emit(
      state.copyWith(
        speakerSelectionMode: () => mode,
        selectedSpeakers: () => hasModeChanged ? <SpeakerProduct>[] : state.selectedSpeakers,
        speakerListTab: () => hasModeChanged ? 0 : state.speakerListTab,
        clearSplResult: mode == SpeakerSelectionMode.select,
        clearSplResultSubwoofer: mode == SpeakerSelectionMode.select,
      ),
    );

    _recalculateIfSuggestMode();
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: () => option));
  void setSpeakerListTab(int tab) => emit(state.copyWith(speakerListTab: () => tab));

  /// RELATED TO SPEAKER SELECTION - MANUAL PROCESS
  void updatedSelectModeArgs(Function(SpeakerSelectModeArgs args) updates) {
    final SpeakerSelectModeArgs updatedArgs = updates(state.selectModeArgs);
    emit(state.copyWith(selectModeArgs: () => updatedArgs));
  }

  void setMountingType(MountingType type) => updatedSelectModeArgs((SpeakerSelectModeArgs args) {
    final List<MountingType> current = List<MountingType>.from(args.mountingTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    return args.copyWith(mountingTypes: () => current);
  });

  void setMaxSplRange(SpeakerMaxSplRange? range) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(maxSplRange: () => range));
  void setAudioChannel(AudioChannel option) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(audioChannel: () => option));
  void setSpeakerColor(SpeakerColorOption option) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(speakerColorOption: () => option));
  void setWiringType(WiringType option) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(wiringType: () => option));
  void setLowFrequencyInHz(double frequency) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(lowFrequencyInHz: () => frequency));

  void setUseSubwoofer(bool useSubwoofer) {
    final List<SpeakerProduct> updatedSpeakers = List<SpeakerProduct>.from(state.selectedSpeakers);
    if (!useSubwoofer) updatedSpeakers.removeWhere((SpeakerProduct sp) => sp.isSubwoofer);
    updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(useSubwoofer: () => useSubwoofer));
    emit(
      state.copyWith(
        selectedSpeakers: () => updatedSpeakers,
        speakerListTab: () => 0, // reset to Mid-High tab
      ),
    );
  }

  void setMonoSubwoofer(bool monoSubwoofer) => updatedSelectModeArgs((SpeakerSelectModeArgs args) => args.copyWith(monoSubwoofer: () => monoSubwoofer));

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

  // RELATED TO SPEAKER SELECTION - SUGGEST
  void updateSuggestModeArgs(Function(SpeakerSuggestModeArgs args) updates) {
    final SpeakerSuggestModeArgs updatedArgs = updates(state.suggestModeArgs);
    emit(state.copyWith(suggestModeArgs: () => updatedArgs));
    _recalculateIfSuggestMode();
  }

  /// Recalculate suggest results when suggest mode inputs change.
  void _recalculateIfSuggestMode() {
    if (state.speakerSelectionMode != SpeakerSelectionMode.suggest) return;
    if (state.listeningAreaId == null) return;

    final ListeningArea listeningArea = selectedListeningArea;

    try {
      final List<SpeakerProduct> speakers = serviceLocator<ProductQueryViewModel>().speakers;
      final SpeakerSuggestModeArgs suggestArgs = state.suggestModeArgs;

      final SplInput input = SplInput(
        mountingType: <String>[suggestArgs.mountingType.name],
        speakerHeight: listeningArea.ceilingHeight,
        listenerHeight: listeningArea.listeningHeight,
        environment: listeningArea.environmentType.name,
        targetSplRange: <double>[suggestArgs.splRange.start, suggestArgs.splRange.end],
      );

      if (suggestArgs.lowFrequency == LowFrequency.withSubwoofer) {
        final List<SpeakerProduct> nonSubs = speakers.where((SpeakerProduct s) => !s.isSubwoofer).toList();
        final List<SpeakerProduct> subs = speakers.where((SpeakerProduct s) => s.isSubwoofer).toList();
        final SplMultiMountResult midHighResult = calculateSpl(input, speakers: nonSubs);

        SplMultiMountResult? subResult;
        if (subs.isNotEmpty) {
          try {
            subResult = calculateSpl(input, speakers: subs);
          } catch (_) {}
        }

        emit(
          state.copyWith(
            splResult: () => midHighResult,
            splResultSubwoofer: () => subResult,
          ),
        );
      } else {
        final List<SpeakerProduct> nonSubs = speakers.where((SpeakerProduct s) => !s.isSubwoofer).toList();
        final SplMultiMountResult result = calculateSpl(input, speakers: nonSubs);
        emit(
          state.copyWith(
            splResult: () => result,
            clearSplResultSubwoofer: true,
          ),
        );
      }
    } catch (_) {
      // Silently ignore incomplete config or SPL calculation errors.
    }
  }

  Map<String, List<SpeakerProduct>> getSuggestedSpeakersByCategory(List<SpeakerProduct> allSpeakers) {
    final SpeakerSuggestModeArgs suggestArgs = state.suggestModeArgs;
    final SplMultiMountResult? result = suggestArgs.lowFrequency == LowFrequency.withSubwoofer ? state.splResultSubwoofer : state.splResult;
    if (result == null || result.results.isEmpty) return <String, List<SpeakerProduct>>{};

    final SplPerMountResult mountResult = result.results.first;

    SpeakerProduct? findByModelName(String modelName) {
      final String lower = modelName.toLowerCase().trim();
      return allSpeakers.where((SpeakerProduct s) => s.modelName.toLowerCase().trim() == lower).firstOrNull;
    }

    List<SpeakerProduct> resolveModels(List<String> modelNames) {
      final List<SpeakerProduct> resolved = <SpeakerProduct>[];
      for (final String name in modelNames) {
        final SpeakerProduct? product = findByModelName(name);
        if (product != null) resolved.add(product);
      }
      return resolved;
    }

    return <String, List<SpeakerProduct>>{
      'Maximum SPL': resolveModels(mountResult.recommendedModelsMax),
      'Target SPL': resolveModels(mountResult.recommendedModelsMid),
      'Minimum SPL': resolveModels(mountResult.recommendedModelsMin),
    };
  }

  List<SpeakerProduct> getSuggestedSpeakers(List<SpeakerProduct> allSpeakers) {
    final Map<String, List<SpeakerProduct>> byCategory = getSuggestedSpeakersByCategory(allSpeakers);

    final List<SpeakerProduct> ordered = <SpeakerProduct>[
      ...byCategory['Maximum SPL']?.take(1) ?? const <SpeakerProduct>[],
      ...byCategory['Target SPL']?.take(1) ?? const <SpeakerProduct>[],
      ...byCategory['Minimum SPL']?.take(1) ?? const <SpeakerProduct>[],
    ];

    final Set<int> seenProductIds = <int>{};
    return ordered.where((SpeakerProduct product) => seenProductIds.add(product.productId)).toList();
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

  /// Commits all staged changes to the currently selected ListeningArea.
  ///
  /// Ceiling height, floor height, listening height and environment type are
  /// written directly on every change (see their respective setters).  Everything
  /// else — background noise, speaker selection mode, mounting type, wiring type
  /// and low-frequency setting — is held in state until this method is called.
  void save() {
    if (state.listeningAreaId == null) return;
    final ListeningArea la = selectedListeningArea;

    final SpeakerProduct? targetSpeaker = state.selectedSpeakers.firstWhereOrNull((SpeakerProduct element) => !element.isSubwoofer);

    log("MOUNTING TYPE TO SAVE: ${targetSpeaker?.mountType}.  === ${MountingType.fromJson(targetSpeaker?.mountType)}");
    final LowFrequency lowFrequency =
        state.speakerSelectionMode == SpeakerSelectionMode.suggest
            ? state.suggestModeArgs.lowFrequency
            : (state.selectModeArgs.useSubwoofer ? LowFrequency.withSubwoofer : LowFrequency.fullRange);

    projectViewModel.updateListeningArea(
      area: la.copyWith(
        speakerSelectionMode: state.speakerSelectionMode,
        mountingType: MountingType.fromJson(targetSpeaker?.mountType),
        wiringType: state.selectModeArgs.wiringType,
        lowFrequency: lowFrequency,
        speakerSelectModeArgs: state.selectModeArgs,
        speakerSuggestModeArgs: state.suggestModeArgs,
      ),
    );

    _syncSelectedSpeakersToListeningArea();
  }

  void _syncSelectedSpeakersToListeningArea() {
    if (state.listeningAreaId == null) return;

    final String listeningAreaId = selectedListeningArea.id;
    final FloorModel currentFloor = projectViewModel.currentFloor;
    final LocationModel location = LocationModel(floorId: currentFloor.id, listeningAreaId: listeningAreaId);
    final List<SpeakerProduct> catalog = serviceLocator<ProductQueryViewModel>().speakers;
    final List<Speaker> existingSpeakers = projectViewModel.getListeningAreaSpeakers(areaId: listeningAreaId);

    bool isSubwooferSpeaker(Speaker speaker) {
      final SpeakerProduct? existing = catalog.firstWhereOrNull((SpeakerProduct p) => p.productId == speaker.productId);
      return existing?.isSubwoofer ?? false;
    }

    void removeSpeakers(Iterable<Speaker> speakers) {
      for (final Speaker speaker in speakers) {
        projectViewModel.removeHardware(hardwareId: speaker.id);
      }
    }

    void addSpeakerFromProduct(SpeakerProduct product) {
      final Speaker toAdd = projectViewModel.fromSpeakerProductModel(product, location, isFromBuildingPage);
      projectViewModel.addHardware(hardware: toAdd);
    }

    final SpeakerProduct? selectedFullRange = state.selectedSpeakers.where((SpeakerProduct sp) => !sp.isSubwoofer).firstOrNull;
    final SpeakerProduct? selectedSubwoofer = state.selectedSpeakers.where((SpeakerProduct sp) => sp.isSubwoofer).firstOrNull;

    if (!state.selectModeArgs.useSubwoofer) {
      // Full-range mode: if nothing selected, remove all LA speakers.
      if (selectedFullRange == null) {
        removeSpeakers(existingSpeakers);
        return;
      }

      final bool alreadyApplied =
          existingSpeakers.isNotEmpty &&
          existingSpeakers.every((Speaker speaker) => !isSubwooferSpeaker(speaker) && speaker.productId == selectedFullRange.productId);

      if (alreadyApplied) return;

      removeSpeakers(existingSpeakers);
      addSpeakerFromProduct(selectedFullRange);
      return;
    }

    // With-subwoofer mode: sync each type independently.
    // If selected product for a type is null, remove existing speakers of that type.
    void syncType({required bool subwooferType, required SpeakerProduct? selectedProduct}) {
      final List<Speaker> sameTypeExisting = existingSpeakers.where((Speaker speaker) => isSubwooferSpeaker(speaker) == subwooferType).toList();

      if (selectedProduct == null) {
        removeSpeakers(sameTypeExisting);
        return;
      }

      final bool alreadyApplied = sameTypeExisting.any((Speaker speaker) => speaker.productId == selectedProduct.productId);
      if (alreadyApplied) return;

      removeSpeakers(sameTypeExisting);
      addSpeakerFromProduct(selectedProduct);
    }

    syncType(subwooferType: false, selectedProduct: selectedFullRange);
    syncType(subwooferType: true, selectedProduct: selectedSubwoofer);
  }

  Future<bool> addOrReplaceSpeaker({required BuildContext context, required SpeakerProduct product}) async {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String listeningAreaId = selectedListeningArea.id;
    final FloorModel currentFloor = projectViewModel.currentFloor;

    // Validate required LA properties before allowing speaker addition.
    final ListeningArea la = selectedListeningArea;
    if (la.listeningHeight <= 0) {
      FusionToast.error(context, message: 'Please enter a valid listening height for this area.');
      return false;
    }

    final LocationModel location = LocationModel(floorId: currentFloor.id, listeningAreaId: listeningAreaId);
    final Speaker speaker = projectViewModel.fromSpeakerProductModel(product, location, isFromBuildingPage);

    final List<SpeakerProduct> catalog = serviceLocator<ProductQueryViewModel>().speakers;
    final List<Speaker> listeningAreaSpeakers = projectViewModel.getListeningAreaSpeakers(areaId: listeningAreaId);

    bool isSubwooferSpeaker(Speaker existingSpeaker) {
      final SpeakerProduct? existing = catalog.firstWhereOrNull((SpeakerProduct sp) => sp.productId == existingSpeaker.productId);
      return existing?.isSubwoofer ?? false;
    }

    if (!state.selectModeArgs.useSubwoofer && product.isSubwoofer) {
      // Subwoofer cannot be added in full-range mode.
      return false;
    }

    if (!state.selectModeArgs.useSubwoofer) {
      final bool alreadyExists =
          listeningAreaSpeakers.isNotEmpty && listeningAreaSpeakers.every((Speaker sp) => !isSubwooferSpeaker(sp) && sp.productId == product.productId);

      if (alreadyExists) return true;

      for (final Speaker existing in listeningAreaSpeakers) {
        projectViewModel.removeHardware(hardwareId: existing.id);
      }

      projectViewModel.addHardware(hardware: speaker);
      projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(autoPlacement: false));
      return true;
    }

    final List<Speaker> sameTypeExisting = listeningAreaSpeakers.where((Speaker sp) => isSubwooferSpeaker(sp) == product.isSubwoofer).toList();
    final bool alreadyExistsInType = sameTypeExisting.any((Speaker sp) => sp.productId == product.productId);

    if (alreadyExistsInType) return true;

    for (final Speaker existing in sameTypeExisting) {
      projectViewModel.removeHardware(hardwareId: existing.id);
    }

    projectViewModel.addHardware(hardware: speaker);
    projectViewModel.updateListeningArea(area: selectedListeningArea.copyWith(autoPlacement: false));
    return true;
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
