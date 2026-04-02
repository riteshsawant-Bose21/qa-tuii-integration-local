import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/view_model/fusion_zone_service.dart';

part 'controlpal_zone_view_model_state.dart';


class ControlPalZonesViewModel extends Cubit<ControlPalZonesState> {


  final FusionZoneService _service;
  List<ZoneModel> _zones = [];
  ControlPalZonesViewModel({
    required FusionZoneService service,
  }) : _service = service,
        super(ZonesInitial());

  void loadZones(List<ZoneModel> zones) {
    _zones.clear();
    _zones.addAll(zones);
    emit(ZonesLoaded(
      zones: zones,
    ));
  }

  void selectZone(ZoneModel zone,int zoneIndex,{int sourceIndex=0}) {
    emit(ZoneSelected(
      zone: zone,
      zoneIndex: zoneIndex,
      currentSourceIndex: sourceIndex,
    ));
  }
  void selectSource(ZoneSourceModel zoneSourceModel) {
    emit(SourceSelected(
      zoneSourceModel: zoneSourceModel,
    ));
  }

  ZonesLoaded get _state => state as ZonesLoaded;

  // 🔥 Volume change
  void updateVolume(int zoneIndex, ZoneSourceModel sourceModel, int volume) {

   // final zones = [..._zones];

    //ZoneSourceModel source = zones[zoneIndex].sources.firstWhere((s) => s.id == sourceModel.id);

    int indexWhere = _zones[zoneIndex].sources.indexWhere((s) => s.id == sourceModel.id);

    if(indexWhere == -1) return;
    print(volume);
    ZoneSourceModel zoneSourceModel = sourceModel.copyWith(
      volume: volume,
      muted: volume == 0,
    );
    _zones[zoneIndex].sources[indexWhere] = zoneSourceModel;


    emit(GainUpdated(zoneSourceModel: zoneSourceModel));

    emit(ZonesLoaded(zones: _zones));
  }

  // 🔥 Next source
  void nextSource(int zoneIndex) {
    //final s = _state;

    // int newSourceIndex = s.currentSourceIndex + 1;
     int newZoneIndex = zoneIndex;

    // if (newSourceIndex >= s.zones[newZoneIndex].sources.length) {
    //   newSourceIndex = 0;
       newZoneIndex++;
    //
    //   if (newZoneIndex >= s.zones.length) {
    //     newZoneIndex = 0;
    //   }
    // }

     print(newZoneIndex);
     print(_zones.length);

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }

  // 🔥 Previous source
  void previousSource(int zoneIndex) {
  //  final s = _state;

    // int newSourceIndex = s.currentSourceIndex - 1;
     int newZoneIndex = zoneIndex;
    //
    // if (newSourceIndex < 0) {
     newZoneIndex--;
    //
    //   if (newZoneIndex < 0) {
    //     newZoneIndex = s.zones.length - 1;
    //   }
    //
    //   newSourceIndex =
    //       s.zones[newZoneIndex].sources.length - 1;
    // }

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }
}