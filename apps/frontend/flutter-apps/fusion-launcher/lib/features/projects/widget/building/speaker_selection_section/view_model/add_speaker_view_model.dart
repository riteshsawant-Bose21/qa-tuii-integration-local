import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../parts/constant_enums.dart';
import '../parts/replace_speaker_warning_dialog.dart';
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
  }

  void setSignalType(SignalType? signalType) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(signalType: signalType);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setLowFrequency(LowFrequency? lf) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(lowFrequency: lf);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setWiringType(WiringType? wiringType) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(wiringType: wiringType);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setSpeakerSelectionMode(SpeakerSelectionMode mode) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(speakerSelectionMode: mode);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: option));
  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

  void setColor(SpeakerColor? color) => emit(state.copyWith(selectedColor: color));

  List<Speaker> getAllPlacedNonPlacedSpeakers() {
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
    final Iterable<SpeakerProduct> filtered = <SpeakerProduct>[...speakers];

    // final String query = state.searchQuery.trim().toLowerCase();
    // if (query.isNotEmpty) {
    //   filtered = filtered.where((SpeakerProduct p) {
    //     final String hay = '${p.modelName} ${p.modelName} ${p.description} ${p.shortDescription ?? ''}'.toLowerCase();
    //     return hay.contains(query);
    //   });
    // }

    // final Set<MountingType> mountingTypes = selectedListeningArea?.mountingTypes ?? <MountingType>{};
    // final Set<LowFrequency> lowFrequencies = selectedListeningArea?.lowFrequencies ?? <LowFrequency>{};

    // if (mountingTypes.isNotEmpty) {
    //   final List<String> keys = mountingTypes.map((MountingType e) => e.name.toLowerCase()).toList();
    //   filtered = filtered.where((SpeakerProduct p) {
    //     final String mt = (p.mountType ?? '').toLowerCase();
    //     return keys.any((String k) => mt.contains(k));
    //   });
    // }

    // final WiringType? wiringType = selectedListeningArea?.wiringType;

    // if (wiringType != null) {
    //   final bool wantHiZ = wiringType == WiringType.highImpedance;
    //   filtered = filtered.where((SpeakerProduct p) {
    //     final bool hasHiZ =
    //         p.isHighImpedanceRated ||
    //         (p.availableTaps?.taps70V.isNotEmpty == true) ||
    //         (p.availableTaps?.taps100V.isNotEmpty == true) ||
    //         p.highImpedanceTaps.isNotEmpty;
    //     final bool hasLoZ = (p.nominalImpedance != null) || (p.impedance != null);
    //     return wantHiZ ? hasHiZ : hasLoZ;
    //   });
    // }

    // if (lowFrequencies.isNotEmpty) {
    //   filtered = filtered.where((SpeakerProduct p) {
    //     final FrequencyRange? fr = p.frequencyRange;
    //     final bool isSub =
    //         p.isSubwoofer || (p.description.toLowerCase().contains('subwoofer') || (p.shortDescription?.toLowerCase().contains('subwoofer') ?? false));

    //     bool matches = false;
    //     for (final LowFrequency sel in lowFrequencies) {
    //       switch (sel) {
    //         case LowFrequency.withSubwoofer:
    //           if (isSub) matches = true;
    //           break;
    //         case LowFrequency.extended:
    //           if (!isSub && fr != null && fr.low > 0 && fr.low <= 40) matches = true;
    //           break;
    //         case LowFrequency.fullRange:
    //           if (!isSub && fr != null && fr.low > 40 && fr.low <= 80) matches = true;
    //           break;
    //         case LowFrequency.vocal:
    //           if (!isSub && fr != null && fr.low > 80) matches = true;
    //           break;
    //       }
    //       if (matches) break;
    //     }
    //     return matches;
    //   });
    // }

    // // Color filter: include product if it declares any requested color key
    // if (state.selectedColors.isNotEmpty) {
    //   final Set<String> wantedColors = state.selectedColors.map((SpeakerColor c) => c.name.toLowerCase()).toSet();

    //   filtered = filtered.where((SpeakerProduct p) {
    //     final Map<String, List<String>> assetMap = p.assets.assets;
    //     if (assetMap.isEmpty) return false;
    //     // Only include if the product has a matching color key AND it has at least one asset for that color
    //     final bool declaresSelectedColor = assetMap.entries.any((MapEntry<String, List<String>> entry) {
    //       final String key = entry.key.toLowerCase();
    //       final List<String> urls = entry.value;
    //       return wantedColors.contains(key) && urls.isNotEmpty;
    //     });
    //     return declaresSelectedColor;
    //   });
    // }

    // final ListeningArea? currentSelectedListeningArea = serviceLocator<ProjectViewModel>().getCurrentSelectedListeningArea();

    // if (currentSelectedListeningArea?.environmentType != null) {
    //   final SpeakerEnvironmentType et = currentSelectedListeningArea!.environmentType!;
    //   if (et == SpeakerEnvironmentType.indoor) {
    //     filtered = filtered.where((SpeakerProduct p) {
    //       final String env = (p.environment ?? '').toLowerCase();
    //       final bool isIndoorEnv = env.contains('indoor');
    //       return !p.isWeatherRated || isIndoorEnv;
    //     });
    //   } else if (et == SpeakerEnvironmentType.outdoor) {
    //     filtered = filtered.where((SpeakerProduct p) {
    //       final String env = (p.environment ?? '').toLowerCase();
    //       final bool isOutdoorEnv = env.contains('outdoor');
    //       return p.isWeatherRated || isOutdoorEnv;
    //     });
    //   }
    // }

    return _sortProducts(filtered.toList());
  }

  List<SpeakerProduct> _sortProducts(List<SpeakerProduct> items) {
    final List<SpeakerProduct> copy = List<SpeakerProduct>.from(items);

    // Bring currently selected/placed speaker products to the top (if any)
    final Set<int> selectedProductIds = getAllPlacedNonPlacedSpeakers().map((Speaker sp) => sp.productId).whereType<int>().toSet();

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
          final double ap = pq.getPrice(a.productId);
          final double bp = pq.getPrice(b.productId);
          return ap.compareTo(bp);
        case SpeakerSortOption.priceHighToLow:
          final double ap = pq.getPrice(a.productId);
          final double bp = pq.getPrice(b.productId);
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

    copy.sort((SpeakerProduct a, SpeakerProduct b) {
      final bool aSelected = selectedProductIds.contains(a.productId);
      final bool bSelected = selectedProductIds.contains(b.productId);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return compareByOption(a, b);
    });

    return copy;
  }

  Future<void> addOrReplaceSpeaker({required BuildContext context, String? cachedImagePath, required SpeakerProduct product}) async {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? listeningAreaId = context.read<SpeakerSelectionViewModel>().selectedListeningArea?.id;
    final FloorModel currentFloor = projectViewModel.currentFloor;

    final LocationModel location = LocationModel(floorId: currentFloor.id, listeningAreaId: listeningAreaId);

    final Speaker speaker = projectViewModel.fromSpeakerProductModel(cachedImagePath ?? '', product, location, isFromBuildingPage);
    if (selectedListeningArea == null) return;

    List<Speaker> speakerList = getPlacedSpeakers();
    if (speakerList.isEmpty) speakerList = getNonPlacedSpeakers();

    bool shouldReplace = false;

    if (speakerList.isNotEmpty) {
      final String newSku = speaker.speakerSKU;
      final String existingSku = speakerList.first.speakerSKU;

      if (existingSku != newSku) {
        final String existingName = speakerList.first.name;
        final bool? isConfirmed = await ReplaceSpeakersWarningDialog.show(
          context,
          listeningAreaName: selectedListeningArea!.name,
          existingSpeakerName: existingName,
          currentSpeakerName: product.modelName,
        );
        if (isConfirmed != true) return;
        shouldReplace = true;
      }
    }

    if (shouldReplace) {
      projectViewModel.migrateAllSpeakersTo(speaker: speaker, targetListeningAreaId: selectedListeningArea!.id);
      if (context.mounted) Navigator.of(context).pop();
    } else {
      projectViewModel.addHardware(hardware: speaker);
    }
  }
}
