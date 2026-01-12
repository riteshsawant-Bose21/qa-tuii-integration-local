import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../parts/constant_enums.dart';
import '../parts/replace_speaker_warning_dialog.dart';

part 'state.dart';

class SpeakerSelectionViewModel extends Cubit<SpeakerSelectionViewModelState> {
  SpeakerSelectionViewModel() : super(const SpeakerSelectionViewModelState());

  ProjectViewModel get projectViewModel => serviceLocator<ProjectViewModel>();

  // THESE ARE FOR SCHEMATIC PAGE
  bool isFromBuildingPage = false;
  String? zoneOrSubzoneId;

  void init({required bool isFromBuilding, String? zoneOrSubzoneId}) {
    isFromBuildingPage = isFromBuilding;
    this.zoneOrSubzoneId = zoneOrSubzoneId;
  }

  ListeningArea? get selectedListeningArea {
    final ListeningArea? listeningArea = projectViewModel.getCurrentSelectedListeningArea();
    if (listeningArea != null) return listeningArea;

    List<ListeningArea> allListeningAreas = <ListeningArea>[];

    if (zoneOrSubzoneId != null) {
      allListeningAreas = projectViewModel.getListeningAreasForZone(zoneId: zoneOrSubzoneId!);
      if (allListeningAreas.isEmpty) {
        allListeningAreas = projectViewModel.getListeningAreasInSubZone(subZoneId: zoneOrSubzoneId!);
      }
    }

    for (final ListeningArea la in allListeningAreas) {
      if (la.id == state.selectedListeningAreaForDropDown?.id) {
        return la;
      }
    }

    return state.selectedListeningAreaForDropDown;
  }

  void setListeningAreaForDropDown(ListeningArea? listeningArea) => emit(state.copyWith(selectedListeningAreaForDropDown: listeningArea));

  // State updates
  void setMode(SpeakerSelectionMode mode) => emit(state.copyWith(mode: mode));

  void setMountingTypes(List<MountingType> types) {
    if (selectedListeningArea == null) return;
    final Set<MountingType> updated = Set<MountingType>.from(types);
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(mountingTypes: updated);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setLowFrequencies(List<LowFrequency> lfs) {
    if (selectedListeningArea == null) return;
    final Set<LowFrequency> updated = Set<LowFrequency>.from(lfs);
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(lowFrequencies: updated);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setWiringType(WiringType? wiringType) {
    if (selectedListeningArea == null) return;
    final ListeningArea updatedLA = selectedListeningArea!.copyWith(wiringType: wiringType);
    projectViewModel.updateListeningArea(area: updatedLA);
  }

  void setSortOption(SpeakerSortOption option) => emit(state.copyWith(sortOption: option));
  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

  void setColors(Iterable<SpeakerColor> colors) => emit(state.copyWith(selectedColors: Set<SpeakerColor>.from(colors)));

  List<Speaker> getAllPlacedNonPlacedSpeakers() {
    if (selectedListeningArea == null) return <Speaker>[];

    final List<Speaker> placedSpeakers = getPlacedSpeakers();
    final List<Speaker> nonPlacedSpeakers = getNonPlacedSpeakers();
    return Set<Speaker>.from(<Speaker>{...placedSpeakers, ...nonPlacedSpeakers}).toList();
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
    Iterable<SpeakerProduct> filtered = <SpeakerProduct>[...speakers];

    final String query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final String hay = '${p.modelName} ${p.modelName} ${p.description} ${p.shortDescription ?? ''}'.toLowerCase();
        return hay.contains(query);
      });
    }

    final Set<MountingType> mountingTypes = selectedListeningArea?.mountingTypes ?? <MountingType>{};
    final Set<LowFrequency> lowFrequencies = selectedListeningArea?.lowFrequencies ?? <LowFrequency>{};

    if (mountingTypes.isNotEmpty) {
      final List<String> keys = mountingTypes.map((MountingType e) => e.name.toLowerCase()).toList();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return keys.any((String k) => mt.contains(k));
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

    if (lowFrequencies.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final FrequencyRange? fr = p.frequencyRange;
        final bool isSub =
            p.isSubwoofer || (p.description.toLowerCase().contains('subwoofer') || (p.shortDescription?.toLowerCase().contains('subwoofer') ?? false));

        bool matches = false;
        for (final LowFrequency sel in lowFrequencies) {
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

    return _sortProducts(filtered.toList());
  }

  List<SpeakerProduct> _sortProducts(List<SpeakerProduct> items) {
    final List<SpeakerProduct> copy = List<SpeakerProduct>.from(items);
    switch (state.sortOption) {
      case SpeakerSortOption.nameAsc:
        copy.sort((SpeakerProduct a, SpeakerProduct b) => a.modelName.toLowerCase().compareTo(b.modelName.toLowerCase()));
        break;
      case SpeakerSortOption.nameDesc:
        copy.sort((SpeakerProduct a, SpeakerProduct b) => b.modelName.toLowerCase().compareTo(a.modelName.toLowerCase()));
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
