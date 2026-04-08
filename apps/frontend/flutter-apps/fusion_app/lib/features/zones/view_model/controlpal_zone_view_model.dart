import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/core/models/gain_model.dart';
import 'package:fusion_app/core/services/websocket_service.dart';
import 'package:fusion_app/core/utils/audio_utils.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/view_model/fusion_zone_service.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../../core/models/scheme_model.dart';

part 'controlpal_zone_view_model_state.dart';


class ControlPalZonesViewModel extends Cubit<ControlPalZonesState> {

  double? bassVolume=null;
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
  final _throttler = Throttler(milliseconds: 100);
  ZonesLoaded get _state => state as ZonesLoaded;

  // 🔥 Volume change
  void updateVolume(int zoneIndex, ZoneSourceModel sourceModel, double volume) {

    int indexWhere = _zones[zoneIndex].sources.indexWhere((s) => s.id == sourceModel.id);

    if(indexWhere == -1) return;

    if(bassVolume==volume){
      return;
    }

    print(volume);
    ZoneSourceModel zoneSourceModel = sourceModel.copyWith(
      volume: volume,
      muted: volume == 0,
    );


    bassVolume = volume;
    _zones[zoneIndex].sources[indexWhere] = zoneSourceModel;

    var gainID =_zones[zoneIndex].gainID;
    // Map<String,dynamic> data = {
    //   "id": zoneSourceModel.id,
    //   "version": 1,
    //   "type": "patch_config",
    //   "settings": {
    //     "audio": {
    //       gainID: {
    //         "gain": bassVolume,
    //         "mute": bassVolume == 0
    //       }
    //     }
    //   }
    // };
    _throttler.run(() {
      //throttle with trailing
      FusionWebSocketService().sendGainPatch(zoneSourceModel.id, gainID, bassVolume!.toDouble());
      //_service.updateGain(data);
    });

   emit(GainUpdated(zoneSourceModel: zoneSourceModel));

    emit(ZonesLoaded(zones: _zones));
  }

  Future<ZoneSourceModel> getGain(int zoneIndex,int sourceIndex, ZoneSourceModel sourceModel) async{


    var gainID =_zones[zoneIndex].gainID;

    Map<String,dynamic> pathParams = {
      "key": "settings.audio."+gainID
    };
    ResponseCallback<GainConfig> model = await  _service.getGain(pathParams);
    double volume = model.data?.value.gain.toDouble() ?? 0;

    ZoneSourceModel zoneSourceModel = sourceModel.copyWith(
      volume: volume,
      muted: volume == 0,
    );
    _zones[zoneIndex].sources[sourceIndex] = zoneSourceModel;
    return zoneSourceModel;
    // emit(GainUpdated(zoneSourceModel: zoneSourceModel));
    //
    // emit(ZonesLoaded(zones: _zones));
  }

  // 🔥 Next source
  void nextSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex++;

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }

  // 🔥 Previous source
  void previousSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex--;

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }
}