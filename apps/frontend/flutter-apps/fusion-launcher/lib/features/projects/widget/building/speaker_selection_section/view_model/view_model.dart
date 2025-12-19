import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:fusion_lib/product_data/products.dart';

import '../constant_enums.dart';

class SpeakerSelectionViewModelState extends Equatable {
  const SpeakerSelectionViewModelState({
    this.mode = SpeakerSelectionMode.select,
    this.selectedMountingTypes = const <SpeakerMountingType>{},
    this.selectedLowFrequencies = const <SpeakerLowFrequency>{},
    this.selectedColors = const <SpeakerColor>{},
    this.selectedWirings = const <SpeakerWiring>{},
    this.sortOption = SpeakerSortOption.nameAsc,
    this.searchQuery = '',
    this.isLoading = false,
    this.speakers,
  });

  final SpeakerSelectionMode mode;
  final Set<SpeakerMountingType> selectedMountingTypes;
  final Set<SpeakerLowFrequency> selectedLowFrequencies;
  final Set<SpeakerColor> selectedColors;
  final Set<SpeakerWiring> selectedWirings;
  final SpeakerSortOption sortOption;
  final String searchQuery;
  final bool isLoading;
  final List<SpeakerProduct>? speakers;

  SpeakerSelectionViewModelState copyWith({
    SpeakerSelectionMode? mode,
    Set<SpeakerMountingType>? selectedMountingTypes,
    Set<SpeakerLowFrequency>? selectedLowFrequencies,
    Set<SpeakerColor>? selectedColors,
    Set<SpeakerWiring>? selectedWirings,
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

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionViewModelState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionViewModelState());

  String? get currentSelectedListeningAreaId => serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId;
  ListeningArea? get currentSelectedListeningArea => serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea();

  // State updates
  void setMode(SpeakerSelectionMode mode) => emit(state.copyWith(mode: mode));

  void toggleMountingType(SpeakerMountingType type) {
    final Set<SpeakerMountingType> updated = Set<SpeakerMountingType>.from(state.selectedMountingTypes);
    updated.contains(type) ? updated.remove(type) : updated.add(type);
    emit(state.copyWith(selectedMountingTypes: updated));
  }

  void toggleLowFrequency(SpeakerLowFrequency lf) {
    final Set<SpeakerLowFrequency> updated = Set<SpeakerLowFrequency>.from(state.selectedLowFrequencies);
    updated.contains(lf) ? updated.remove(lf) : updated.add(lf);
    emit(state.copyWith(selectedLowFrequencies: updated));
  }

  void toggleColor(SpeakerColor color) {
    final Set<SpeakerColor> updated = Set<SpeakerColor>.from(state.selectedColors);
    updated.contains(color) ? updated.remove(color) : updated.add(color);
    emit(state.copyWith(selectedColors: updated));
  }

  void toggleWiring(SpeakerWiring wiring) {
    final Set<SpeakerWiring> updated = Set<SpeakerWiring>.from(state.selectedWirings);
    updated.contains(wiring) ? updated.remove(wiring) : updated.add(wiring);
    emit(state.copyWith(selectedWirings: updated));
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: option));
  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

  void setMountingTypes(Iterable<SpeakerMountingType> types) => emit(state.copyWith(selectedMountingTypes: Set<SpeakerMountingType>.from(types)));
  void setLowFrequencies(Iterable<SpeakerLowFrequency> lfs) => emit(state.copyWith(selectedLowFrequencies: Set<SpeakerLowFrequency>.from(lfs)));
  void setColors(Iterable<SpeakerColor> colors) => emit(state.copyWith(selectedColors: Set<SpeakerColor>.from(colors)));
  void setWiring(SpeakerWiring? wiring) => emit(state.copyWith(selectedWirings: wiring == null ? <SpeakerWiring>{} : <SpeakerWiring>{wiring}));

  // Data loading
  Future<void> loadProducts(Products productsApi) async {
    emit(state.copyWith(isLoading: true));
    try {
      await productsApi.initialize();
      emit(state.copyWith(isLoading: false, speakers: productsApi.speakers));
    } catch (_) {
      emit(state.copyWith(isLoading: false, speakers: <SpeakerProduct>[]));
    }
  }

  List<Speaker> getSpeakersForListeningArea() {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? currentSelectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();
    final List<HardwareComponent> listeningAreaSpeakers = projectViewModel.getHardwareForListeningArea(listeningAreaId: currentSelectedListeningArea!.id);
    return listeningAreaSpeakers.whereType<Speaker>().where((Speaker element) => element.pos == null).toList();
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
      final List<String> keys = state.selectedMountingTypes.map((SpeakerMountingType e) => e.displayName.toLowerCase()).toList();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return keys.any((String k) => mt.contains(k));
      });
    }

    final bool filterWiring = state.selectedWirings.isNotEmpty;
    if (filterWiring) {
      final bool wantHiZ = state.selectedWirings.contains(SpeakerWiring.hiZ);
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
        for (final SpeakerLowFrequency sel in state.selectedLowFrequencies) {
          switch (sel) {
            case SpeakerLowFrequency.subwoofer:
              if (isSub) matches = true;
              break;
            case SpeakerLowFrequency.extended:
              if (!isSub && fr != null && fr.low > 0 && fr.low <= 40) matches = true;
              break;
            case SpeakerLowFrequency.fullRange:
              if (!isSub && fr != null && fr.low > 40 && fr.low <= 80) matches = true;
              break;
            case SpeakerLowFrequency.vocal:
              if (!isSub && fr != null && fr.low > 80) matches = true;
              break;
          }
          if (matches) break;
        }
        return matches;
      });
    }

    if (state.selectedColors.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        bool match = false;
        for (final SpeakerColor c in state.selectedColors) {
          if (p.assets.getAssetsFor(c.jsonAssetKey).isNotEmpty) {
            match = true;
            break;
          }
        }
        return match;
      });
    }

    if (currentSelectedListeningArea != null) {
      final String vt = currentSelectedListeningArea!.venuType.trim().toLowerCase();
      if (vt == 'indoor') {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isIndoorEnv = env.contains('indoor');
          return !p.isWeatherRated || isIndoorEnv;
        });
      } else if (vt == 'indoor + outdoor') {
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isOutdoorEnv = env.contains('outdoor');
          return p.isWeatherRated || isOutdoorEnv;
        });
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

  List<SpeakerColorVarientModel> buildColorVariantModels(List<SpeakerProduct> sorted, Products productsApi) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? la = currentSelectedListeningArea;
    final FloorModel currentFloor = projectViewModel.currentFloor;

    final List<SpeakerColorVarientModel> variants = <SpeakerColorVarientModel>[];
    for (final SpeakerProduct speakerProduct in sorted) {
      final Set<SpeakerColor> available = <SpeakerColor>{
        for (final SpeakerColor c in SpeakerColor.values)
          if (speakerProduct.assets.getAssetsFor(c.jsonAssetKey).isNotEmpty) c,
      };

      Iterable<SpeakerColor?> targetColors;
      if (state.selectedColors.isNotEmpty) {
        targetColors = state.selectedColors.where((SpeakerColor c) => available.contains(c));
      } else {
        targetColors = available.isNotEmpty ? available : <SpeakerColor?>[null];
      }

      for (final SpeakerColor? variantColor in targetColors) {
        String? assetImagePath;
        if (variantColor != null) {
          final List<String> urls = speakerProduct.assets.getAssetsFor(variantColor.jsonAssetKey);
          assetImagePath = urls.isNotEmpty ? productsApi.getImagePath(urls.first) : null;
        } else if (speakerProduct.assets.firstAssetUrl != null) {
          assetImagePath = productsApi.getImagePath(speakerProduct.assets.firstAssetUrl!);
        }

        final Speaker speaker = projectViewModel.fromSpeakerProductModel(
          assetImagePath ?? '',
          speakerProduct,
          LocationModel(floorId: currentFloor.id, listeningAreaId: la!.id),
          true,
        );

        variants.add(
          SpeakerColorVarientModel(
            product: speakerProduct,
            speaker: speaker,
            variantColor: variantColor,
            assetImagePath: assetImagePath,
          ),
        );
      }
    }
    return variants;
  }
}

class SpeakerColorVarientModel {
  const SpeakerColorVarientModel({
    required this.product,
    required this.speaker,
    required this.variantColor,
    required this.assetImagePath,
  });

  final SpeakerProduct product;
  final Speaker speaker;
  final SpeakerColor? variantColor;
  final String? assetImagePath;
}
