import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:fusion_lib/product_data/products.dart';

import '../parts/constant_enums.dart';
import '../parts/replace_speaker_warning_dialog.dart';

part 'state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionViewModelState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionViewModelState()) {
    loadProducts();
  }

  final Products productsApi = Products(baseUrl: AppConfig.awsApiBaseUrl, fusionOnly: true);

  // State updates
  void setMode(SpeakerSelectionMode mode) => emit(state.copyWith(mode: mode));

  void toggleMountingType(MountingType type) {
    final Set<MountingType> updated = Set<MountingType>.from(state.selectedMountingTypes);
    updated.contains(type) ? updated.remove(type) : updated.add(type);
    emit(state.copyWith(selectedMountingTypes: updated));
  }

  void toggleLowFrequency(LowFrequency lf) {
    final Set<LowFrequency> updated = Set<LowFrequency>.from(state.selectedLowFrequencies);
    updated.contains(lf) ? updated.remove(lf) : updated.add(lf);
    emit(state.copyWith(selectedLowFrequencies: updated));
  }

  void toggleColor(SpeakerColor color) {
    final Set<SpeakerColor> updated = Set<SpeakerColor>.from(state.selectedColors);
    updated.contains(color) ? updated.remove(color) : updated.add(color);
    emit(state.copyWith(selectedColors: updated));
  }

  void toggleWiring(WiringType wiring) {
    final Set<WiringType> updated = Set<WiringType>.from(state.selectedWirings);
    updated.contains(wiring) ? updated.remove(wiring) : updated.add(wiring);
    emit(state.copyWith(selectedWirings: updated));
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: option));
  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

  void setMountingTypes(Iterable<MountingType> types) => emit(state.copyWith(selectedMountingTypes: Set<MountingType>.from(types)));
  void setLowFrequencies(Iterable<LowFrequency> lfs) => emit(state.copyWith(selectedLowFrequencies: Set<LowFrequency>.from(lfs)));
  void setColors(Iterable<SpeakerColor> colors) => emit(state.copyWith(selectedColors: Set<SpeakerColor>.from(colors)));
  void setWiring(WiringType? wiring) => emit(state.copyWith(selectedWirings: wiring == null ? <WiringType>{} : <WiringType>{wiring}));

  // Data loading
  Future<void> loadProducts() async {
    emit(state.copyWith(isLoading: true));
    try {
      await productsApi.initialize();
      emit(
        state.copyWith(
          isLoading: false,
          speakers: productsApi.speakers,
        ),
      );
    } catch (_) {
      log("Error loading products");
      emit(state.copyWith(isLoading: false, speakers: <SpeakerProduct>[]));
    }
  }

  List<Speaker> getAllPlacedNonPlacedSpeakers() {
    final List<Speaker> placedSpeakers = getPlacedSpeakers();
    final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakers();
    return Set<Speaker>.from(<Speaker>{...placedSpeakers, ...nonPlacedSpeakers}).toList();
  }

  List<Speaker> getPlacedSpeakers() {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? listeningAreaId = projectViewModel.currentSelectedListeningAreaId;
    final List<HardwareComponent> listeningAreaSpeakers = projectViewModel.getAllPlacedHardwareInListeningArea(listeningAreaId: listeningAreaId!);
    return listeningAreaSpeakers.whereType<Speaker>().toList();
  }

  List<Speaker> getNonPlacedSpeakers() {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? listeningAreaId = projectViewModel.currentSelectedListeningAreaId;
    final List<HardwareComponent> listeningAreaSpeakers = projectViewModel.getAllNonPlacedHardwareInListeningArea(listeningAreaId: listeningAreaId!);
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

  List<SpeakerProduct> applyFilters() {
    Iterable<SpeakerProduct> filtered = <SpeakerProduct>[...(state.speakers ?? <SpeakerProduct>[])];

    final String query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final String hay = '${p.modelName} ${p.modelFamily} ${p.description} ${p.shortDescription ?? ''}'.toLowerCase();
        return hay.contains(query);
      });
    }

    if (state.selectedMountingTypes.isNotEmpty) {
      final List<String> keys = state.selectedMountingTypes.map((MountingType e) => e.name.toLowerCase()).toList();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return keys.any((String k) => mt.contains(k));
      });
    }

    final bool filterWiring = state.selectedWirings.isNotEmpty;
    if (filterWiring) {
      final bool wantHiZ = state.selectedWirings.contains(WiringType.highImpedance);
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

    if (state.selectedLowFrequencies.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final FrequencyRange? fr = p.frequencyRange;
        final bool isSub =
            p.isSubwoofer || (p.description.toLowerCase().contains('subwoofer') || (p.shortDescription?.toLowerCase().contains('subwoofer') ?? false));

        bool matches = false;
        for (final LowFrequency sel in state.selectedLowFrequencies) {
          switch (sel) {
            case LowFrequency.subwoofer:
              if (isSub) matches = true;
              break;
            case LowFrequency.extended:
              if (!isSub && fr != null && fr.low > 0 && fr.low <= 40) matches = true;
              break;
            case LowFrequency.fullRange:
              if (!isSub && fr != null && fr.low > 40 && fr.low <= 80) matches = true;
              break;
            case LowFrequency.vocal:
              if (!isSub && fr != null && fr.low > 80) matches = true;
              break;
          }
          if (matches) break;
        }
        return matches;
      });
    }

    // Color filter: include product if it declares any requested color key
    if (state.selectedColors.isNotEmpty) {
      final Set<String> wantedColors = state.selectedColors.map((SpeakerColor c) => c.name.toLowerCase()).toSet();

      filtered = filtered.where((SpeakerProduct p) {
        final Map<String, List<String>> assetMap = p.assets.assets;
        if (assetMap.isEmpty) return false;
        // Only include if the product has a matching color key AND it has at least one asset for that color
        final bool declaresSelectedColor = assetMap.entries.any((MapEntry<String, List<String>> entry) {
          final String key = entry.key.toLowerCase();
          final List<String> urls = entry.value;
          return wantedColors.contains(key) && urls.isNotEmpty;
        });
        return declaresSelectedColor;
      });
    }

    final ListeningArea? currentSelectedListeningArea = serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea();

    if (currentSelectedListeningArea?.venuType != null) {
      final VenueType vt = currentSelectedListeningArea!.venuType!;
      if (vt == VenueType.indoor) {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isIndoorEnv = env.contains('indoor');
          return !p.isWeatherRated || isIndoorEnv;
        });
      } else if (vt == VenueType.outdoor) {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isOutdoorEnv = env.contains('outdoor');
          return p.isWeatherRated || isOutdoorEnv;
        });
      } else if (vt == VenueType.mixed) {
        // Mixed venue: include both indoor and outdoor options (no environment filter)
      }
    }

    return filtered.toList();
  }

  List<SpeakerProduct> sortProducts(List<SpeakerProduct> items) {
    final List<SpeakerProduct> copy = List<SpeakerProduct>.from(items);
    switch (state.sortOption) {
      case SpeakerSortOption.nameAsc:
        copy.sort((SpeakerProduct a, SpeakerProduct b) => a.modelFamily.toLowerCase().compareTo(b.modelFamily.toLowerCase()));
        break;
      case SpeakerSortOption.nameDesc:
        copy.sort((SpeakerProduct a, SpeakerProduct b) => b.modelFamily.toLowerCase().compareTo(a.modelFamily.toLowerCase()));
        break;
    }
    return copy;
  }

  Future<void> addOrReplaceSpeaker({required BuildContext context, required Speaker speaker, required String productName}) async {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? listeningArea = projectViewModel.getCurrentSelectedListeningArea();

    if (listeningArea == null) return;

    List<Speaker> speakerList = getPlacedSpeakers();
    if (speakerList.isEmpty) speakerList = getNonPlacedSpeakers();
    final String newSku = speaker.speakerSKU;

    if (speakerList.isNotEmpty) {
      final String existingSku = speakerList.first.speakerSKU;

      if (existingSku != newSku) {
        final String existingName = speakerList.first.name;
        final bool? confirm = await ReplaceSpeakersWarningDialog.show(
          context,
          listeningAreaName: listeningArea.name,
          existingSpeakerName: existingName,
          currentSpeakerName: productName,
        );
        if (confirm != true) return;
      }
    }

    projectViewModel.addHardware(hardware: speaker);
  }
}
