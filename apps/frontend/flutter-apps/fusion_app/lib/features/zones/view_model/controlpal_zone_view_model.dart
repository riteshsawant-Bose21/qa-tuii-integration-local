// import 'package:bloc/bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:fusion_app/core/models/gain_model.dart';
// import 'package:fusion_app/core/models/source_input.dart';
// import 'package:fusion_app/core/services/websocket_service.dart';
// import 'package:fusion_app/core/utils/audio_utils.dart';
// import 'package:fusion_app/features/zones/models/zone_source_model.dart';
// import 'package:fusion_app/features/zones/view_model/fusion_zone_service.dart';
// import 'package:fusion_lib/fusion_lib.dart' hide Source;
// import '../../../core/models/scheme_model.dart';
//
// part 'controller_view_model_state.dart';
//
//
// class ControlPalZonesViewModel extends Cubit<ControlPalZonesState> {
//
//   double? bassVolume;
//   final FusionZoneService _service;
//   final List<ZoneModel> _zones = [];
//    ZoneModel? activeZone;
//
//   ControlPalZonesViewModel({
//     required FusionZoneService service,
//   }) : _service = service,
//         super(ZonesInitial());
//
//   final _throttler = Throttler(milliseconds: 100);
//   ZonesLoaded get _state => state as ZonesLoaded;
//
//   void loadZones(List<ZoneModel> zones) {
//     _zones.clear();
//     _zones.addAll(zones);
//     emit(ZonesLoaded(
//       zones: zones,
//     ));
//   }
//
//   void selectZone(ZoneModel zone,int zoneIndex,{int currentSubzoneIndex=0,int sourceIndex=0}) {
//     activeZone = zone;
//     emit(ZoneSelected(
//       zone: zone,
//       zoneIndex: zoneIndex,
//       currentSubzoneIndex: currentSubzoneIndex,
//       currentSourceIndex: sourceIndex,
//     ));
//   }
//
//   void selectSource(Source source,String zoneID,String subzoneID,{bool sendToService=false}) {
//     if(sendToService) {
//       FusionWebSocketService().sendSourcePatch(
//           subzoneID, zoneID, source.index ?? 0);
//     }
//     print("selectSource: EMIT ${source.sourceName}");
//     emit(SourceSelected(
//       source: source,
//     ));
//   }
//
//
//
//   // Volume change
//   void updateVolume(ZoneSourceModel sourceModel, double volume,{bool sendToService=false}) {
//
//     // int indexWhere = _zones[zoneIndex].subZones.indexWhere((s) => s.id == sourceModel.id);
//     //
//     // if(indexWhere == -1) return;
//
//     if(bassVolume==volume){
//       return;
//     }
//
//     ZoneSourceModel zoneSourceModel = sourceModel.copyWith(
//       volume: volume,
//       muted: volume == 0,
//     );
//
//     int? foundZoneIndex;
//     int? foundSubZoneIndex;
//
//     for (int i = 0; i < _zones.length; i++) {
//       final subIndex = _zones[i].subZones
//           .indexWhere((s) => s.id == sourceModel.id);
//
//       if (subIndex != -1) {
//         foundZoneIndex = i;
//         foundSubZoneIndex = subIndex;
//         break;
//       }
//     }
//
//     if(foundZoneIndex!=null && foundSubZoneIndex!=null) {
//
//       bassVolume = volume;
//       _zones[foundZoneIndex].subZones[foundSubZoneIndex] = zoneSourceModel;
//
//       var gainID =_zones[foundZoneIndex].subZones[foundSubZoneIndex].gainID;
//
//       if(sendToService) {
//         _throttler.run(() {
//           //throttle with trailing
//           FusionWebSocketService().sendGainPatch(
//               zoneSourceModel.id, gainID, bassVolume!.toDouble());
//         });
//       }
//
//       emit(GainUpdated(zoneSourceModel: zoneSourceModel));
//
//       emit(ZonesLoaded(zones: _zones));
//     } else {
//       print("Could not find zone or subzone for sourceModel id: ${sourceModel.id}");
//       return;
//     }
//
//   }
//
//   Future<ZoneSourceModel> getGain(int zoneIndex,int sourceIndex, ZoneSourceModel sourceModel) async{
//
//
//     var gainID = sourceModel.gainID;
//
//     Map<String,dynamic> pathParams = {
//       "key": "settings.audio.$gainID"
//     };
//     ResponseCallback<GainConfig> model = await  _service.getGain(pathParams);
//     double volume = AudioUtils.toUiVolume( model.data?.value.gain ?? 0);
//
//     ZoneSourceModel zoneSourceModel = sourceModel.copyWith(
//       volume: volume,
//       muted: volume == 0,
//     );
//     _zones[zoneIndex].subZones[sourceIndex] = zoneSourceModel;
//     return zoneSourceModel;
//   }
//
//   Future<ZoneModel> getSelectSource(String zoneID) async{
//     Map<String,dynamic> pathParams = {
//       "key": "settings.audio.$zoneID"
//     };
//     ResponseCallback<InputConfig> model = await  _service.getSourceSelect(pathParams);
//
//     int index = _zones.indexWhere((z)=> z.id == zoneID);
//       ZoneModel zoneModel = _zones[index];
//     if(index!=-1){
//
//     _zones[index].sourceSelected = model.data?.value.input ?? 0;
//     }
//     return zoneModel;
//
//   }
//
//   //  Next source
//   void nextSource(int zoneIndex) {
//
//      int newZoneIndex = zoneIndex;
//
//      newZoneIndex++;
//
//     selectZone(_zones[newZoneIndex], newZoneIndex);
//   }
//
//   //  Previous source
//   void previousSource(int zoneIndex) {
//
//      int newZoneIndex = zoneIndex;
//
//      newZoneIndex--;
//
//     selectZone(_zones[newZoneIndex], newZoneIndex);
//   }
// }