import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart' hide Source;
import 'package:fusion_lib/fusion_utils/audio_utils.dart';
import 'package:fusion_lib/models/virtual_controller/gain_model.dart';
import 'package:fusion_lib/models/virtual_controller/source_input.dart';

part 'controller_view_model_state.dart';


class VirtualControllerViewModel extends Cubit<VirtualControllerState> {

  double? bassVolume;
  final FusionVirtualControllerService _service;
  final List<WallZone> _zones = <WallZone>[];
  WallZone? activeZone;
  String vipAddress="";

  VirtualControllerViewModel({
    required FusionVirtualControllerService service,
  }) : _service = service,
        super(ZonesInitial());

  final _throttler = Throttler(milliseconds: 100);


  void loadZones(List<WallZone> zones,String address) {
    _zones.clear();
    _zones.addAll(zones);
    vipAddress = address;
    emit(ZonesLoaded(
      zones: zones,
    ));
  }

  void selectZone(WallZone zone,int zoneIndex,{int currentSubzoneIndex=0,int sourceIndex=0}) {
    activeZone = zone;
    emit(ZoneSelected(
      zone: zone,
      zoneIndex: zoneIndex,
      currentSubzoneIndex: currentSubzoneIndex,
      currentSourceIndex: sourceIndex,
    ));
  }

  void selectSource(WallZoneSource source,String zoneID,String subzoneID,{bool sendToService=false}) {
    if(sendToService) {

      final patch = {
        "id": zoneID,
        "version": 1,
        "type": "patch_config",
        "data": {
          "settings": {
            "audio": {
              subzoneID: {"input": source.index}
            }
          }
        }
      };

      WebSocketService().sendMessage(patch);
    }
    print("selectSource: EMIT ${source.sourceName}");
    emit(SourceSelected(
      source: source,
    ));
  }



  //  Volume change
  void updateVolume(WallSubZone sourceModel, double volume,{bool sendToService=false}) {

    if(bassVolume==volume){
      return;
    }

    WallSubZone zoneSourceModel = sourceModel.copyWith(
      ono: sourceModel.ono.copyWith(gain: volume.toInt(),mute: volume == 0 ? 0 :1),
    );

    int? foundZoneIndex;
    int? foundSubZoneIndex;

    for (int i = 0; i < _zones.length; i++) {
      final subIndex = _zones[i].subZones
          .indexWhere((s) => s.id == sourceModel.id);

      if (subIndex != -1) {
        foundZoneIndex = i;
        foundSubZoneIndex = subIndex;
        break;
      }
    }

    if(foundZoneIndex!=null && foundSubZoneIndex!=null) {

      bassVolume = volume;
      _zones[foundZoneIndex].subZones[foundSubZoneIndex] = zoneSourceModel;

      var gainID =_zones[foundZoneIndex].subZones[foundSubZoneIndex].gain.gainID;

      if(sendToService) {
        _throttler.run(() {
          //throttle with trailing
          final dbGain = AudioUtils.volumeToDbGain(bassVolume! / 100.0);
          final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
          final patch = {
            "id": gainID,
            "version": 1,
            "type": "patch_config",
            "data": {
              "settings": {
                "audio": {
                  gainID: {"gain": dbGain,"mute": false,"timestamp":timestamp}
                }
              }
            }
          };



          WebSocketService().sendMessage(patch);
        });
      }

      emit(GainUpdated(zoneSourceModel: zoneSourceModel));

      emit(ZonesLoaded(zones: _zones));
    } else {
      print("Could not find zone or subzone for sourceModel id: ${sourceModel.id}");
      return;
    }

  }

  Future<WallSubZone> getGain(int zoneIndex,int sourceIndex, WallSubZone sourceModel) async{


    var gainID = sourceModel.gain.gainID;

    Map<String,dynamic> pathParams = {
      "key": "settings.audio.$gainID"
    };
    ResponseCallback<GainConfig> model = await  _service.getGain(pathParams,vipAddress);

    if(model.data?.exists == false){
      print("getGain: No data received for gainID: $gainID");
      return sourceModel;
    }
    double volume = AudioUtils.toUiVolume( model.data?.value.gain ?? 0);

    WallSubZone zoneSourceModel = sourceModel.copyWith(
      ono: sourceModel.ono.copyWith(gain: volume.toInt(),mute: volume == 0 ? 0 :1),
    );
    _zones[zoneIndex].subZones[sourceIndex] = zoneSourceModel;
    return zoneSourceModel;
  }

  Future<WallZone> getSelectSource(String zoneID) async{
    Map<String,dynamic> pathParams = {
      "key": "settings.audio.$zoneID"
    };
    ResponseCallback<InputConfig> model = await  _service.getSourceSelect(pathParams,vipAddress);

    int index = _zones.indexWhere((z)=> z.id == zoneID);
    WallZone zoneModel = _zones[index];
    if(index!=-1){

    _zones[index].sourceSelected = model.data?.value.input ?? 0;
    }
    return zoneModel;

  }

  //  Next source
  void nextSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex++;

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }

  //  Previous source
  void previousSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex--;

    selectZone(_zones[newZoneIndex], newZoneIndex);
  }
}
