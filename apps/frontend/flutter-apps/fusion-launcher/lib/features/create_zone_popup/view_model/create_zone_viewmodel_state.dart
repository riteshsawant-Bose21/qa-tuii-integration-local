import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CreateZoneViewModelState extends Equatable {
  final String zoneName;
  final String zoneColor;
  final ZoneFunctionsType? zoneFunctionType;
  final List<ListeningArea> zoneListeningAreas;
  final List<AddListeningAreaToSubzoneModel> subzones;

  const CreateZoneViewModelState({
    required this.zoneName,
    required this.zoneColor,
    this.zoneFunctionType,
    required this.zoneListeningAreas,
    this.subzones = const <AddListeningAreaToSubzoneModel>[],
  });

  @override
  List<Object?> get props => <Object?>[
    zoneName,
    zoneColor,
    zoneFunctionType,
    zoneListeningAreas,
    subzones,
  ];

  CreateZoneViewModelState copyWith({
    String? zoneName,
    String? zoneColor,
    ZoneFunctionsType? zoneFunctionType,
    List<ListeningArea>? zoneListeningAreas,
    List<AddListeningAreaToSubzoneModel>? subzones,
  }) {
    return CreateZoneViewModelState(
      zoneName: zoneName ?? this.zoneName,
      zoneColor: zoneColor ?? this.zoneColor,
      zoneFunctionType: zoneFunctionType ?? this.zoneFunctionType,
      zoneListeningAreas: zoneListeningAreas ?? this.zoneListeningAreas,
      subzones: subzones ?? this.subzones,
    );
  }

  CreateZoneViewModelState addOrRemoveListeningAreaToZone(ListeningArea listeningArea, bool isSelected) {
    final List<ListeningArea> updatedZoneListeningArea = List<ListeningArea>.from(zoneListeningAreas);

    // if any of the subzones contain the listening area, do not allow adding/removing in zone
    for (AddListeningAreaToSubzoneModel subzone in subzones) {
      if (subzone.listeningAreas.contains(listeningArea)) {
        return this;
      }
    }

    if (isSelected) {
      updatedZoneListeningArea.removeWhere((ListeningArea area) => area.id == listeningArea.id);
    } else {
      updatedZoneListeningArea.add(listeningArea);
    }

    return copyWith(zoneListeningAreas: updatedZoneListeningArea);
  }

  CreateZoneViewModelState addOrRemoveListeningAreaToSubzone(ListeningArea listeningArea, bool isSelected) {
    final List<AddListeningAreaToSubzoneModel> subzones = List<AddListeningAreaToSubzoneModel>.from(this.subzones);

    for (int i = 0; i < subzones.length; i++) {
      final AddListeningAreaToSubzoneModel subzone = subzones[i];
      final List<ListeningArea> updatedListeningAreas = List<ListeningArea>.from(subzone.listeningAreas);

      if (isSelected) {
        updatedListeningAreas.removeWhere((ListeningArea area) => area.id == listeningArea.id);
      } else {
        updatedListeningAreas.add(listeningArea);
      }

      subzones[i] = subzone.copyWith(listeningAreas: updatedListeningAreas);
    }

    // if zone contains the listening area, remove it from zone
    final List<ListeningArea> updatedZoneListeningArea = List<ListeningArea>.from(zoneListeningAreas);
    updatedZoneListeningArea.removeWhere((ListeningArea area) => area.id == listeningArea.id);

    return copyWith(subzones: subzones, zoneListeningAreas: updatedZoneListeningArea);
  }

  // check LA is already selected in zone or subzone
  AddListeningAreaToSubzoneModel? isListeningAreaSelectedInAnySubzone(String listeningAreaId) {
    for (AddListeningAreaToSubzoneModel subzone in subzones) {
      for (ListeningArea area in subzone.listeningAreas) {
        if (area.id == listeningAreaId) {
          return subzone;
        }
      }
    }
    return null;
  }

  bool canAddListeningAreaToSubzoneModel(String listeningAreaId) {
    for (ListeningArea area in zoneListeningAreas) {
      if (area.id == listeningAreaId) {
        return false;
      }
    }
    return true;
  }
}

class AddListeningAreaToSubzoneModel extends Equatable {
  final String subZoneName;
  final List<ListeningArea> listeningAreas;

  const AddListeningAreaToSubzoneModel({required this.subZoneName, required this.listeningAreas});

  AddListeningAreaToSubzoneModel copyWith({String? subZoneName, List<ListeningArea>? listeningAreas}) {
    return AddListeningAreaToSubzoneModel(
      subZoneName: subZoneName ?? this.subZoneName,
      listeningAreas: listeningAreas ?? this.listeningAreas,
    );
  }

  @override
  List<Object?> get props => <Object?>[subZoneName, listeningAreas];
}
