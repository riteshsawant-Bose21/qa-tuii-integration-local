import 'dart:convert';

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
        super(VirtualZonesInitial());

  final _throttler = Throttler(milliseconds: 100);


  void loadZones(List<WallZone> zones,String address) {
    _zones.clear();
    _zones.addAll(zones);
    vipAddress = address;
    emit(VirtualZonesLoaded(
      zones: zones,
    ));
  }

  void selectZone(WallZone zone,int zoneIndex,gainID,{int currentSubzoneIndex=0,int sourceIndex=1}) {
    activeZone = zone;
    emit(VirtualZoneSelected(
      zone: zone,
      zoneIndex: zoneIndex,
      currentSubzoneIndex: currentSubzoneIndex,
      currentSourceIndex: sourceIndex,
      gainID: gainID,
    ));
  }

  void selectSource(WallZoneSource source,String zoneID,String funcID,{bool sendToService=false}) {
    if(sendToService) {

      final patch = {
        "id": zoneID,
        "version": 1,
        "type": "patch_config",
        "data": {
          "settings": {
            "audio": {
              funcID: {"input": source.index}
            }
          }
        }
      };

      WebSocketService().sendMessage(jsonEncode(patch));
    }
    print("selectSource: EMIT ${source.sourceName}");
    emit(SourceSelected(
      source: source,
    ));
  }



  //  Volume change
  void updateVolume(WallSubZone sourceModel, double volume,{bool sendToService=false ,bool isMuted = false}) {


    // if(bassVolume==volume){
    //   return;
    // }

    WallSubZone zoneSourceModel = sourceModel.copyWith(
      ono: sourceModel.ono.copyWith(gain: volume.toInt(),mute: isMuted ? 1 :0),
    );

    int foundZoneIndex=-1;
    int foundSubZoneIndex=-1;

    for (int i = 0; i < _zones.length; i++) {
      final subIndex = _zones[i].subZones
          .indexWhere((s) => s.id == sourceModel.id);

      if (subIndex != -1) {
        foundZoneIndex = i;
        foundSubZoneIndex = subIndex;
        break;
      }
    }
    print("foundZoneIndex");
    print(foundZoneIndex);
    print("foundSubZoneIndex");
    print(foundSubZoneIndex);

    if(foundZoneIndex!=-1 && foundSubZoneIndex!=-1) {

      bassVolume = volume;
      _zones[foundZoneIndex].subZones[foundSubZoneIndex] = zoneSourceModel;

      var gainID =_zones[foundZoneIndex].subZones[foundSubZoneIndex].gain.gainID;

      if(sendToService) {
        _throttler.run(() {
          //throttle with trailing
          final dbGain =  AudioUtils().percentageToDbfs(bassVolume!);
          final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
          final patch = {
            "id": gainID,
            "version": 1,
            "type": "patch_config",
            "data": {
              "settings": {
                "audio": {
                  gainID: {"gain": dbGain,"mute": isMuted,
                   // "timestamp":timestamp
                  }
                }
              }
            }
          };
          WebSocketService().sendMessage(jsonEncode(patch));
        });
      }

      emit(GainUpdated(zoneSourceModel: zoneSourceModel));

      emit(VirtualZonesLoaded(zones: _zones));
    } else {
      print("Could not find zone or subzone for sourceModel id: ${sourceModel.id}");
      return;
    }

  }

  void updateMute(bool isMuted,gainID,dbGain) {

    final patch = {
      "id": gainID,
      "version": 1,
      "type": "patch_config",
      "data": {
        "settings": {
          "audio": {
            gainID: {"gain": dbGain,"mute": isMuted,
            }
          }
        }
      }
    };
    WebSocketService().sendMessage(jsonEncode(patch));
    emit(MuteUpdated(isMuted: isMuted));
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
    double volume =  AudioUtils().dbfsToPercentage( model.data?.value.gain ?? 0);
    bool mute =   model.data?.value.mute ?? false;

    WallSubZone zoneSourceModel = sourceModel.copyWith(
      ono: sourceModel.ono.copyWith(gain: volume.toInt(),mute: mute ? 1:0),
    );
    _zones[zoneIndex].subZones[sourceIndex] = zoneSourceModel;
    return zoneSourceModel;
  }

  Future<WallZone> getSelectSource(String funcID) async{
    Map<String,dynamic> pathParams = {
      "key": "settings.audio"
    };
    ResponseCallback<InputConfig> model = await  _service.getSourceSelect(pathParams,vipAddress,funcID);
    print("Func ID : ${model.data!.toJson()}");

    int index = _zones.indexWhere((z)=> "${z.functionId!}/selector" == funcID);
    print("found Func ID : $index");
    WallZone zoneModel = _zones[index];
    if(index!=-1){

    _zones[index].sourceSelected = model.data?.value.input ?? 1;
    }
    return zoneModel;

  }

  //  Next source
  void nextSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex++;

    selectZone(_zones[newZoneIndex], newZoneIndex,'');
  }

  //  Previous source
  void previousSource(int zoneIndex) {

     int newZoneIndex = zoneIndex;

     newZoneIndex--;

    selectZone(_zones[newZoneIndex], newZoneIndex,'');
  }
}
