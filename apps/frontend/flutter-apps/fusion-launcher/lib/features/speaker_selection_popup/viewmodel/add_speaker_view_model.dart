import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../views/widgets/constant_enums.dart';
import '../views/widgets/replace_speaker_warning_dialog.dart';
import 'product_query_view_model.dart';

part 'state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionViewModelState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionViewModelState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  // THESE ARE FOR SCHEMATIC PAGE
  bool isFromBuildingPage = false;
  String? zoneId;
  String? subZoneId;

  void init({required bool isFromBuilding, String? zoneId, String? subZoneId}) {
    isFromBuildingPage = isFromBuilding;
    this.zoneId = zoneId;
    this.subZoneId = subZoneId;

    // Hydrate suggest-mode state when reopening the dialog so previously configured
    // values immediately show recommended lists and top-card selections.
    _recalculateIfSuggestMode();
    _restoreSuggestedSelectionFromExistingSpeakers();
  }

  void _restoreSuggestedSelectionFromExistingSpeakers() {
    final ListeningArea? la = selectedListeningArea;
    if (la == null || la.speakerSelectionMode != SpeakerSelectionMode.suggest) return;

    final List<Speaker> currentSpeakers = getAllPlacedAndNonPlacedSpeakers();
    if (currentSpeakers.isEmpty) return;

    final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();
    int? midHighProductId;
    int? subwooferProductId;

    for (final Speaker sp in currentSpeakers) {
      final int? productId = sp.productId;
      if (productId == null) continue;

      final SpeakerProduct? product = pq.speakers.where((SpeakerProduct s) => s.id == productId).firstOrNull;
      if (la.lowFrequency == LowFrequency.withSubwoofer) {
        if (product?.isSubwoofer == true) {
          subwooferProductId ??= productId;
        } else {
          midHighProductId ??= productId;
        }
      } else {
        // In full-range modes, keep only one suggested selection.
        midHighProductId ??= productId;
      }
    }

    emit(
      state.copyWith(
        suggestedProductId: midHighProductId,
        suggestedSubwooferProductId: la.lowFrequency == LowFrequency.withSubwoofer ? subwooferProductId : null,
      ),
    );
  }

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

  ListeningArea? get selectedListeningArea {
    if (isFromBuildingPage) {
      final ListeningArea? listeningArea = projectViewModel.getCurrentSelectedListeningArea();
      if (listeningArea != null) return listeningArea;
    }

    final List<ListeningArea> allListeningAreas = getListeningAreas();
    for (final ListeningArea la in allListeningAreas) {
      if (la.id == state.selectedListeningAreaForDropDown?.id) {
        return la;
      }
    }

    final ListeningArea? selectedListeningAreaForDropDown = state.selectedListeningAreaForDropDown;

    return selectedListeningAreaForDropDown ?? allListeningAreas.firstOrNull;
  }

  void setListeningAreaForDropDown(ListeningArea? listeningArea) => emit(state.copyWith(selectedListeningAreaForDropDown: listeningArea));

  void setMountingType(MountingType? type) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(mountingType: type);
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  void setSignalType(SignalType? signalType) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(signalType: signalType);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setLowFrequency(LowFrequency? lf) {
    if (selectedListeningArea == null) return;

    final bool wasSubwooferMode = selectedListeningArea!.lowFrequency == LowFrequency.withSubwoofer;
    final bool willBeSubwooferMode = lf == LowFrequency.withSubwoofer;

    if (wasSubwooferMode != willBeSubwooferMode) {
      final List<Speaker> existing = getAllPlacedAndNonPlacedSpeakers();
      final ProjectViewModel pvm = serviceLocator<ProjectViewModel>();
      final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();

      // In both directions, only remove subwoofers.
      // Non-subwoofer speakers transition naturally:
      //   full-range → withSubwoofer: they become mid-high speakers
      //   withSubwoofer → full-range: mid-high speakers become full-range speakers
      for (final Speaker sp in existing) {
        final SpeakerProduct? product = sp.productId != null ? pq.speakers.where((SpeakerProduct s) => s.id == sp.productId).firstOrNull : null;
        if (product != null && product.isSubwoofer) {
          pvm.removeHardware(hardwareId: sp.id);
        }
      }
    }

    final ListeningArea updatedLA = selectedListeningArea!.copyWith(lowFrequency: lf);
    projectViewModel.updateListeningArea(area: updatedLA);
    emit(state.copyWith(selectedTab: 0));
    _recalculateIfSuggestMode();
  }

  void setWiringType(WiringType? wiringType) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(wiringType: wiringType);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  bool get isSuggestMode => selectedListeningArea?.speakerSelectionMode == SpeakerSelectionMode.suggest;

  /// Recalculates SPL suggestions if currently in suggest mode and all required fields are set.
  void _recalculateIfSuggestMode() {
    if (!isSuggestMode) return;
    final ListeningArea? la = selectedListeningArea;
    if (la == null) return;
    if (la.environmentType == null || la.splRange == null) return;

    try {
      final List<SpeakerProduct> speakers = serviceLocator<ProductQueryViewModel>().speakers;
      final SplInput input = SplInput(
        mountingType: <String>[la.mountingType.name],
        speakerHeight: double.tryParse(la.ceilingHeight) ?? 0.0,
        listenerHeight: la.listeningHeight,
        environment: la.environmentType!.name,
        targetSplRange: <double>[
          la.splRange!.splRangeValues["min"]!,
          la.splRange!.splRangeValues["max"]!,
        ],
      );

      if (la.lowFrequency == LowFrequency.withSubwoofer) {
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
            splResult: midHighResult,
            splResultSubwoofer: subResult,
            clearSuggestedProductId: true,
            clearSuggestedSubwooferProductId: true,
          ),
        );
      } else {
        final List<SpeakerProduct> nonSubs = speakers.where((SpeakerProduct s) => !s.isSubwoofer).toList();
        final SplMultiMountResult result = calculateSpl(input, speakers: nonSubs);
        emit(state.copyWith(splResult: result, clearSuggestedProductId: true, clearSuggestedSubwooferProductId: true, clearSplResultSubwoofer: true));
      }
    } catch (_) {
      // Silently ignore — incomplete config or calculation error
    }
  }

  /// Call this from the UI when a property dropdown that affects suggest results changes
  /// (e.g. listener height, ceiling height, environment, SPL range, background noise).
  void recalculateSuggestions() => _recalculateIfSuggestMode();

  void setSpeakerSelectionMode(BuildContext context, SpeakerSelectionMode mode, List<SpeakerProduct> speakers) {
    if (selectedListeningArea == null) return;

    if (mode == SpeakerSelectionMode.suggest) {
      try {
        if (selectedListeningArea?.mountingType == null) {
          return FusionToast.error(context, message: 'Please select at least one mounting type');
        } else if ((selectedListeningArea?.listeningHeight ?? 0) <= 0) {
          return FusionToast.error(context, message: 'Please enter listening height');
        } else if (selectedListeningArea?.ceilingHeight.isEmpty != false || double.tryParse(selectedListeningArea?.ceilingHeight ?? '') == null) {
          return FusionToast.error(context, message: 'Please enter ceiling height');
        } else if (selectedListeningArea?.environmentType == null) {
          return FusionToast.error(context, message: 'Please select a environment type');
        } else if (selectedListeningArea?.splRange == null) {
          return FusionToast.error(context, message: 'Please select spl range');
        }

        final SplInput input = SplInput(
          mountingType: <String>[selectedListeningArea!.mountingType.name],
          speakerHeight: double.tryParse(selectedListeningArea!.ceilingHeight) ?? 0.0,
          listenerHeight: selectedListeningArea!.listeningHeight,
          environment: selectedListeningArea!.environmentType!.name,
          targetSplRange: <double>[
            selectedListeningArea!.splRange!.splRangeValues["min"]!,
            selectedListeningArea!.splRange!.splRangeValues["max"]!,
          ],
        );

        if (selectedListeningArea!.lowFrequency == LowFrequency.withSubwoofer) {
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
              splResult: midHighResult,
              splResultSubwoofer: subResult,
              clearSuggestedProductId: true,
              clearSuggestedSubwooferProductId: true,
            ),
          );
        } else {
          final List<SpeakerProduct> nonSubs = speakers.where((SpeakerProduct s) => !s.isSubwoofer).toList();
          final SplMultiMountResult result = calculateSpl(input, speakers: nonSubs);
          emit(state.copyWith(splResult: result, clearSuggestedProductId: true, clearSuggestedSubwooferProductId: true, clearSplResultSubwoofer: true));
        }
      } catch (e) {
        return FusionToast.error(context, message: 'Failed to calculate speaker suggestion. Please try again.');
      }
    } else {
      emit(state.copyWith(clearSplResult: true, clearSplResultSubwoofer: true, clearSuggestedProductId: true, clearSuggestedSubwooferProductId: true));
    }

    final ListeningArea updatedLA = selectedListeningArea!.copyWith(speakerSelectionMode: mode);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  Future<void> selectSuggestedSpeaker({required BuildContext context, required SpeakerProduct product, String? cachedImagePath}) async {
    final bool didApply = await addOrReplaceSpeaker(context: context, cachedImagePath: cachedImagePath, product: product);
    if (!didApply) return;

    final LowFrequency? lf = selectedListeningArea?.lowFrequency;
    if (lf == LowFrequency.withSubwoofer && state.selectedTab == 1) {
      emit(state.copyWith(suggestedSubwooferProductId: product.id));
    } else {
      emit(state.copyWith(suggestedProductId: product.id));
    }
  }

  /// Returns suggested speakers grouped by category from the SPL calculation result.
  /// Keys: "Maximum SPL", "Balanced", "Lowest Cost"
  /// In withSubwoofer mode, uses the appropriate result based on active tab.
  Map<String, List<SpeakerProduct>> getSuggestedSpeakersByCategory(List<SpeakerProduct> allSpeakers) {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;
    final bool isSubwooferTab = lf == LowFrequency.withSubwoofer && state.selectedTab == 1;
    final SplMultiMountResult? result = isSubwooferTab ? state.splResultSubwoofer : state.splResult;
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
      'Balanced': resolveModels(mountResult.recommendedModelsMid),
      'Lowest Cost': resolveModels(mountResult.recommendedModelsMin),
    };
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: option));
  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));
  void setSelectedTab(int index) => emit(state.copyWith(selectedTab: index));

  void setColor(SpeakerColor? color) => emit(state.copyWith(selectedColor: color));

  // ── Listening area property setters (extracted from UI) ──

  void updateListeningAreaName(String value) {
    if (selectedListeningArea == null) return;
    if (value.trim().isNotEmpty) {
      final ListeningArea updatedLA = selectedListeningArea!.copyWith(name: value.trim());
      projectViewModel.updateListeningArea(area: updatedLA);
    }
  }

  void setListenerHeight(ListeningHeightOption option) {
    if (selectedListeningArea == null) return;
    final double heightValue = ListeningHeightOption.getValue(option) ?? selectedListeningArea?.customListeningAreaHeight ?? 1.1;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(listeningHeight: heightValue);
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  /// Returns true if value was valid and applied, false otherwise.
  void setCustomListeningHeight(double value) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(listeningHeight: value);
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  void setCeilingHeight(String value) {
    if (selectedListeningArea == null) return;
    final double? parsed = double.tryParse(value);
    if (parsed == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(ceilingHeight: parsed.toString());
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  void setEnvironmentType(int selectedIndex) {
    if (selectedListeningArea == null) return;
    final SpeakerEnvironmentType selectedType = SpeakerEnvironmentType.values[selectedIndex];
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(environmentType: selectedType);
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  void setBackgroundNoise(int selectedIndex) {
    if (selectedListeningArea == null) return;
    final BackgroundNoise selectedNoise = BackgroundNoise.values[selectedIndex];
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(backgroundNoise: selectedNoise);
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  void setSplRange(int selectedIndex) {
    if (selectedListeningArea == null) return;
    final Map<String, double> splRangeValues = SplRange.values[selectedIndex].splRangeValues;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(
      minSPL: splRangeValues["min"]!,
      maxSPL: splRangeValues["max"]!,
      splRange: SplRange.values[selectedIndex],
    );
    projectViewModel.updateListeningArea(area: updatedLA);
    _recalculateIfSuggestMode();
  }

  /// Returns the available low frequency options based on current mode and selection.
  List<LowFrequency> getLowFrequencyOptions() {
    if (isSuggestMode) return LowFrequency.values;
    // final bool isSubwooferSelected = selectedListeningArea?.lowFrequency == LowFrequency.withSubwoofer;
    // return isSubwooferSelected ? LowFrequency.values : LowFrequency.values;
    return LowFrequency.values;
  }

  /// Returns tab labels for the frequency category tab bar.
  List<String> getTabLabels() {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;
    if (lf == LowFrequency.withSubwoofer) {
      return <String>['Mid-High', 'Subwoofer'];
    }
    return <String>[frequencyCategoryLabel];
  }

  /// Applies tab-based filtering for select mode when "With Subwoofer" is active.
  List<SpeakerProduct> getFilteredSpeakersForTab(List<SpeakerProduct> items) {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;

    if (lf == LowFrequency.withSubwoofer && items.isNotEmpty) {
      final int activeTab = state.selectedTab.clamp(0, 1);
      if (activeTab == 0) {
        // Actually full range, but taking as Mid-High tab
        return items.where((SpeakerProduct p) => !p.isSubwoofer).toList();
      } else {
        // Subwoofer tab: show only subwoofers
        return items.where((SpeakerProduct p) => p.isSubwoofer).toList();
      }
    } else {
      // Except subwoofer, all products are refering as full-range, so no need to filter by tab.
      return items.where((SpeakerProduct p) => !p.isSubwoofer).toList();
    }
  }

  /// Whether the current low frequency mode is a full-range mode (vocal/fullRange/extended/mono).
  bool get isFullRangeMode {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;
    return lf != LowFrequency.withSubwoofer;
  }

  /// Checks if existing placed speakers are incompatible with the new frequency mode.
  /// Returns true if a conflict exists (full-range speakers exist when switching to
  /// withSubwoofer, or mid-high/subwoofer speakers exist when switching to full-range).
  bool hasFrequencyModeConflict(LowFrequency? newLf) {
    final List<Speaker> allPlaced = getAllPlacedAndNonPlacedSpeakers();
    if (allPlaced.isEmpty) return false;

    final LowFrequency? currentLf = selectedListeningArea?.lowFrequency;
    if (currentLf == null || newLf == null) return false;

    final bool wasFullRange = currentLf != LowFrequency.withSubwoofer;
    final bool willBeFullRange = newLf != LowFrequency.withSubwoofer;

    // No conflict if staying in same category
    if (wasFullRange == willBeFullRange) return false;

    return true;
  }

  /// Returns the frequency category label based on the current low frequency selection.
  /// Vocal, Full Range, Extended are all considered "Full Range" on the right side.
  String get frequencyCategoryLabel {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;
    if (lf == null) return 'Full Range';
    switch (lf) {
      case LowFrequency.withSubwoofer:
        return 'Mid-High';
      case LowFrequency.fullRange:
      case LowFrequency.extendedBass:
        return 'Full Range';
    }
  }

  /// Returns the placed speakers grouped by frequency category.
  /// In withSubwoofer mode: always {"Mid-High": [...], "Subwoofer": [...]} (both sections, may be empty)
  /// Otherwise: {categoryLabel: [...all placed speakers...]} or empty map if none placed
  Map<String, List<Speaker>> getPlacedSpeakersByCategory() {
    final LowFrequency? lf = selectedListeningArea?.lowFrequency;

    if (lf == LowFrequency.withSubwoofer) {
      final List<Speaker> allPlaced = getAllPlacedAndNonPlacedSpeakers();
      final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();
      final List<Speaker> midHigh = <Speaker>[];
      final List<Speaker> subwoofer = <Speaker>[];
      for (final Speaker sp in allPlaced) {
        final SpeakerProduct? product = sp.productId != null ? pq.speakers.where((SpeakerProduct s) => s.id == sp.productId).firstOrNull : null;
        if (product != null && product.isSubwoofer) {
          subwoofer.add(sp);
        } else {
          midHigh.add(sp);
        }
      }
      // Always return both sections so the top card always shows Mid-High and Subwoofer slots
      return <String, List<Speaker>>{'Mid-High': midHigh, 'Subwoofer': subwoofer};
    }

    final List<Speaker> allPlaced = getAllPlacedAndNonPlacedSpeakers();
    if (allPlaced.isEmpty) return <String, List<Speaker>>{};
    return <String, List<Speaker>>{frequencyCategoryLabel: allPlaced};
  }

  List<Speaker> getAllPlacedAndNonPlacedSpeakers() {
    if (selectedListeningArea == null) return <Speaker>[];

    final List<Speaker> placedSpeakers = getPlacedSpeakers();
    final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakers();
    return Set<Speaker>.from(<Speaker>{...placedSpeakers, ...nonPlacedSpeakers}).toList();
  }

  bool isListeningAreaSelected(String listeningAreaId) {
    final ListeningArea? selectedArea = selectedListeningArea;
    if (selectedArea == null) return false;
    return selectedArea.id == listeningAreaId;
  }

  List<Speaker> getPlacedSpeakers() {
    if (selectedListeningArea == null) return <Speaker>[];
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<HardwareComponent> listeningAreaSpeakers = projectViewModel.getAllPlacedHardwareInListeningArea(listeningAreaId: selectedListeningArea!.id);
    return listeningAreaSpeakers.whereType<Speaker>().toList();
  }

  List<Speaker> getNonPlacedSpeakers() {
    if (selectedListeningArea == null) return <Speaker>[];
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<HardwareComponent> listeningAreaSpeakers = projectViewModel.getAllNonPlacedHardwareInListeningArea(listeningAreaId: selectedListeningArea!.id);
    return listeningAreaSpeakers.whereType<Speaker>().toList();
  }

  // Business logic helpers for UI formatting
  static String formatFrequencyRange(FrequencyRange? f) {
    if (f == null) return 'N/A';
    if ((f.low == 0) && (f.high == 0)) return 'N/A';
    return '${f.low}\u2013${f.high} ${f.unit}';
  }

  static String computeEnvironment(String? environment, {required bool isWeatherRated}) {
    if ((environment ?? '').trim().isNotEmpty) return environment!.trim();
    return isWeatherRated ? 'Weather rated' : 'N/A';
  }

  static String formatSensitivity(Sensitivity? s) {
    if (s == null || s.at.isEmpty) return 'N/A';
    return s.at.map((MeasurementValue e) => '${e.value} ${s.unit} @ ${e.key}').join(', ');
  }

  static String formatMaxSpl(MaxSpl? m) {
    if (m == null || m.at.isEmpty) return 'N/A';
    return m.at.map((MeasurementValue e) => '${e.value} ${m.unit} @ ${e.key}').join(', ');
  }

  static String formatPowerValue({num? value, String? unit}) {
    if (value == null || value == 0 || (unit == null || unit.isEmpty)) return 'N/A';
    return '${_trimTrailingZeros(value)} $unit';
  }

  static String formatPowerSummary({num? longTermRms, num? peak, String? unit}) {
    final String rms = formatPowerValue(value: longTermRms, unit: unit);
    final String pk = formatPowerValue(value: peak, unit: unit);
    if (rms == 'N/A' && pk == 'N/A') return 'N/A';
    return 'RMS $rms, Peak $pk';
  }

  static String _trimTrailingZeros(num value) {
    final String s = value.toString();
    if (!s.contains('.')) return s;
    return s.replaceFirst(RegExp(r"\.0+"), '').replaceFirst(RegExp(r"(\.\d*[1-9])0+"), r"$1");
  }

  List<SpeakerProduct> applyFilters(List<SpeakerProduct> speakers) {
    // Subwoofers bypass all property-level filters — they are separated by tab.
    final List<SpeakerProduct> subwoofers = speakers.where((SpeakerProduct p) => p.isSubwoofer).toList();
    Iterable<SpeakerProduct> filtered = speakers.where((SpeakerProduct p) => !p.isSubwoofer);

    final String query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final String hay = '${p.modelName} ${p.description} ${p.shortDescription ?? ''}'.toLowerCase();
        return hay.contains(query);
      });
    }

    final MountingType? mountingType = selectedListeningArea?.mountingType;

    if (mountingType != null) {
      final String key = mountingType.name.toLowerCase();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return mt.contains(key);
      });
    }

    final WiringType? wiringType = selectedListeningArea?.wiringType;

    if (wiringType != null) {
      final bool wantHiZ = wiringType == WiringType.highImpedance;
      filtered = filtered.where((SpeakerProduct p) {
        final bool hasHiZ =
            p.isHighImpedanceRated ||
            (p.availableTaps?.taps70V.isNotEmpty == true) ||
            (p.availableTaps?.taps100V.isNotEmpty == true) ||
            p.highImpedanceTaps.isNotEmpty;
        final bool hasLoZ = (p.nominalImpedance != null) || (p.impedance != null);
        return wantHiZ ? hasHiZ : hasLoZ;
      });
    }

    final LowFrequency? lowFrequency = selectedListeningArea?.lowFrequency;

    if (lowFrequency == LowFrequency.withSubwoofer) {
      // Keep select-mode catalog broad; frequency split is handled by the Mid-High/Subwoofer tabs.
      filtered = filtered.where((SpeakerProduct p) => !p.isSubwoofer);
    }

    // Color filter
    final String wantedColor = state.selectedColor.name.toLowerCase();
    final List<SpeakerProduct> colorFiltered =
        filtered.where((SpeakerProduct p) {
          final Map<String, List<String>> assetMap = p.assets.assets;
          if (assetMap.isEmpty) return false;
          return assetMap.entries.any((MapEntry<String, List<String>> entry) {
            final String key = entry.key.toLowerCase();
            final List<String> urls = entry.value;
            return wantedColor == key && urls.isNotEmpty;
          });
        }).toList();

    // If no products exist in the selected color, avoid hiding the entire catalog.
    if (colorFiltered.isNotEmpty) {
      filtered = colorFiltered;
    }

    // Environment filter
    final ListeningArea? currentSelectedListeningArea = serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea();

    if (currentSelectedListeningArea?.environmentType != null) {
      final SpeakerEnvironmentType et = currentSelectedListeningArea!.environmentType!;
      if (et == SpeakerEnvironmentType.indoor) {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isIndoorEnv = env.contains('indoor');
          return !p.isWeatherRated || isIndoorEnv;
        });
      } else if (et == SpeakerEnvironmentType.outdoor) {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isOutdoorEnv = env.contains('outdoor');
          return p.isWeatherRated || isOutdoorEnv;
        });
      }
    }

    return _sortProducts(<SpeakerProduct>[...filtered, ...subwoofers]);
  }

  List<SpeakerProduct> _sortProducts(List<SpeakerProduct> items) {
    final List<SpeakerProduct> copy = List<SpeakerProduct>.from(items);

    int compareByOption(SpeakerProduct a, SpeakerProduct b) {
      double maxSplValue(MaxSpl? m) {
        if (m == null || m.at.isEmpty) return 0.0;
        final Iterable<double> values = m.at.map((MeasurementValue e) => (e.value as num).toDouble());
        return values.isEmpty ? 0.0 : values.reduce((double x, double y) => x > y ? x : y);
      }

      num powerHandlingValue(PowerHandling? p) {
        if (p == null) return 0;
        if (p.longTermRms != 0) return p.longTermRms;
        if (p.peak != 0) return p.peak;
        return 0;
      }

      final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();

      switch (state.sortOption) {
        case SpeakerSortOption.nameAsc:
          return a.modelName.toLowerCase().compareTo(b.modelName.toLowerCase());
        case SpeakerSortOption.nameDesc:
          return b.modelName.toLowerCase().compareTo(a.modelName.toLowerCase());
        case SpeakerSortOption.priceLowToHigh:
          final double ap = pq.getPrice(a.id);
          final double bp = pq.getPrice(b.id);
          return ap.compareTo(bp);
        case SpeakerSortOption.priceHighToLow:
          final double ap = pq.getPrice(a.id);
          final double bp = pq.getPrice(b.id);
          return bp.compareTo(ap);
        case SpeakerSortOption.maxSplHighToLow:
          final double am = maxSplValue(a.maxSpl);
          final double bm = maxSplValue(b.maxSpl);
          return bm.compareTo(am);
        case SpeakerSortOption.maxSplLowToHigh:
          final double am = maxSplValue(a.maxSpl);
          final double bm = maxSplValue(b.maxSpl);
          return am.compareTo(bm);
        case SpeakerSortOption.powerHandlingHighToLow:
          final num ah = powerHandlingValue(a.powerHandling);
          final num bh = powerHandlingValue(b.powerHandling);
          return bh.compareTo(ah);
        case SpeakerSortOption.powerHandlingLowToHigh:
          final num ah = powerHandlingValue(a.powerHandling);
          final num bh = powerHandlingValue(b.powerHandling);
          return ah.compareTo(bh);
      }
    }

    copy.sort(compareByOption);

    return copy;
  }

  Future<bool> addOrReplaceSpeaker({required BuildContext context, String? cachedImagePath, required SpeakerProduct product}) async {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? listeningAreaId = context.read<SpeakerSelectionViewModel>().selectedListeningArea?.id;
    final FloorModel currentFloor = projectViewModel.currentFloor;

    if (selectedListeningArea == null) return false;

    // Validate required LA properties before allowing speaker addition.
    final ListeningArea la = selectedListeningArea!;
    if (la.listeningHeight <= 0) {
      FusionToast.error(context, message: 'Please enter a valid listening height for this area.');
      return false;
    }
    if (la.ceilingHeight.isEmpty || double.tryParse(la.ceilingHeight) == null) {
      FusionToast.error(context, message: 'Please enter a valid ceiling height for this area.');
      return false;
    }
    if (la.environmentType == null) {
      FusionToast.error(context, message: 'Please select an environment type for this area.');
      return false;
    }
    if (la.splRange == null) {
      FusionToast.error(context, message: 'Please select a target SPL range for this area.');
      return false;
    }

    final LocationModel location = LocationModel(floorId: currentFloor.id, listeningAreaId: listeningAreaId);
    final Speaker speaker = projectViewModel.fromSpeakerProductModel(cachedImagePath ?? '', product, location, isFromBuildingPage);

    final bool isWithSubwooferMode = selectedListeningArea!.lowFrequency == LowFrequency.withSubwoofer;

    // Get ALL speakers (placed + non-placed) so we never miss any.
    final List<Speaker> speakerList = getAllPlacedAndNonPlacedSpeakers();

    if (isWithSubwooferMode) {
      // ── WITH SUBWOOFER MODE ──
      // LA holds TWO speaker types: one Mid-High model + one Subwoofer model.
      // Each type can have multiple qty. They coexist independently.
      // Only compare/replace within the SAME type — never touch the other type.
      final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();

      bool isSpeakerSubwoofer(Speaker sp) {
        final SpeakerProduct? p = sp.productId != null ? pq.speakers.where((SpeakerProduct s) => s.id == sp.productId).firstOrNull : null;
        return p != null && p.isSubwoofer;
      }

      final List<Speaker> sameTypeSpeakers =
          product.isSubwoofer ? speakerList.where(isSpeakerSubwoofer).toList() : speakerList.where((Speaker sp) => !isSpeakerSubwoofer(sp)).toList();

      if (sameTypeSpeakers.isEmpty || sameTypeSpeakers.first.speakerSKU == speaker.speakerSKU) {
        // No speaker of this type yet, or same model — add another instance.
        projectViewModel.addHardware(hardware: speaker);
        return true;
      }

      // Different model of the same type — ask to replace only that type.
      final bool? isConfirmed = await ReplaceSpeakersWarningDialog.show(
        context,
        listeningAreaName: selectedListeningArea!.name,
        existingSpeakerName: sameTypeSpeakers.first.name,
        currentSpeakerName: product.modelName,
      );
      if (isConfirmed != true) return false;

      for (final Speaker sp in sameTypeSpeakers) {
        projectViewModel.removeHardware(hardwareId: sp.id);
      }
      projectViewModel.addHardware(hardware: speaker);
      return true;
    } else {
      // Full-range mode: LA holds one speaker model with multiple qty.
      // Same model → add another instance. Different model → replace all.
      if (speakerList.isEmpty || speakerList.first.speakerSKU == speaker.speakerSKU) {
        projectViewModel.addHardware(hardware: speaker);
        return true;
      }

      final bool? isConfirmed = await ReplaceSpeakersWarningDialog.show(
        context,
        listeningAreaName: selectedListeningArea!.name,
        existingSpeakerName: speakerList.first.name,
        currentSpeakerName: product.modelName,
      );
      if (isConfirmed != true) return false;

      projectViewModel.migrateAllSpeakersTo(speaker: speaker, targetListeningAreaId: selectedListeningArea!.id);
      projectViewModel.updateListeningArea(area: selectedListeningArea!.copyWith(autoPlacement: false));
      return true;
    }
  }
}
