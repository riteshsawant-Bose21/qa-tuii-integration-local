// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:fusion_app/core/router/routes.dart';
// import 'package:fusion_app/core/service_locator.dart';
// import 'package:fusion_app/core/services/websocket_service.dart';
// import 'package:fusion_app/core/utils/audio_utils.dart';
// import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
// import 'package:fusion_app/features/zones/models/zone_source_model.dart';
// import 'package:fusion_app/features/zones/widgets/zone_source_card.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// class ControllerZones extends StatefulWidget {
//   const ControllerZones({super.key});
//
//   @override
//   State<ControllerZones> createState() => _ControllerZonesState();
// }
//
// class _ControllerZonesState extends State<ControllerZones> {
//   final Map<String, ZoneSourceModel> _cache = {};
//   final Map<String, ZoneModel> _cacheZone = {};
//
//   final _wsService = FusionWebSocketService();
//   StreamSubscription? _wsSubscription;
//   bool _isInteracting = false;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//
//     context.read<ControlPalZonesViewModel>().loadZones(serviceLocator<QrScannerViewModel>().getZones);
//
//     // Listen for server-side updates
//     _wsSubscription = _wsService.audioUpdateStream.listen((audioSettings) {
//       _processAudioUpdate(audioSettings);
//     });
//
//     super.initState();
//   }
//
//   void _processAudioUpdate(Map<String, dynamic> audioSettings) {
//     print("_processAudioUpdate");
//     if (!mounted) return;
//
//     // Only update from server if user is NOT interacting
//     if (!_isInteracting) {
//
//
//         for(var zone in _cacheZone.keys.toList()){
//           print("Zone-key : "+zone);
//           if(_cacheZone.containsKey(zone)) {
//             print("ZONE Key exists");
//             for (var entry in audioSettings.entries) {
//               if (zone == entry.key) {
//                 ZoneModel zoneModel = _cacheZone[zone]!;
//
//                 print(
//                   'incoming entry for source select ${entry
//                       .value} is newer. Updating cacheZone.',
//                 );
//                 zoneModel.sourceSelected = entry.value['input'];
//                 _cacheZone[zone] = zoneModel;
//
//                 context
//                     .read<
//                     ControlPalZonesViewModel>()
//                     .selectSource(
//                     zoneModel.sources[zoneModel.sourceSelected - 1],
//                     "", // not needed since sendToService is false
//                     "", // not needed since sendToService is false
//                     sendToService: false
//                 );
//
//
//                 setState(() {});
//
//               }
//             }
//           }else{
//             print("NO ZONE Key exists");
//           }
//         }
//
//
//         for(var item in _cache.keys.toList()){
//
//           for(var entry in audioSettings.entries){
//             if(item == entry.key) {
//               ZoneSourceModel sourceModel = _cache[item]!;
//
//               int incomingTsStr = entry.value['timestamp']??0;
//               if (sourceModel.timestamp == null || sourceModel.timestamp! < incomingTsStr) {
//                 print(
//                   'incoming entry for ${entry.value['gain']} is newer. Updating cache.',
//                 );
//
//                 double volume = AudioUtils.toUiVolume(double.parse(entry.value['gain'].toString()));
//                 //double volume = double.parse(entry.value['gain'].toString()),
//                 _cache[item] = sourceModel.copyWith(
//                     volume: volume,
//                     timestamp: incomingTsStr,
//                     muted: entry.value['mute']);
//
//                 context
//                     .read<
//                     ControlPalZonesViewModel>()
//                     .updateVolume(_cache[item]!,volume, sendToService: false);
//
//
//
//              // context.read<ControlPalZonesViewModel>().updateVolume(array.first,sourceModel,AudioUtils.toUiVolume(entry.value['gain']));
//               setState(() {});
//             }
//             }
//           }
//
//         }
//
//     }
//   }
//
//   Future<ZoneModel> getSelectSource(String zoneID) async{
//     if (!_cacheZone.containsKey("$zoneID")) {
//
//       ZoneModel sourceModel = await context.read<ControlPalZonesViewModel>().getSelectSource(zoneID); // only once per item
//        FusionWebSocketService().subscribe(zoneID);
//       _cacheZone["$zoneID"] = sourceModel;
//
//       return sourceModel;
//     }
//
//     return Future.value(_cacheZone["$zoneID"]);
//
//   }
//
//
//   Future<ZoneSourceModel> getItem(int zoneIndex,int subzoneIndex,ZoneSourceModel zoneSrcModel,String gainID) async{
//     if (!_cache.containsKey("$gainID")) {
//
//       ZoneSourceModel sourceModel = await context.read<ControlPalZonesViewModel>().getGain(zoneIndex,subzoneIndex,zoneSrcModel); // only once per item
//       FusionWebSocketService().subscribe(gainID);
//       _cache["$gainID"] = sourceModel;
//
//       return sourceModel;
//     }
//
//     return Future.value(_cache["$gainID"]);
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ControlPalZonesViewModel, ControlPalZonesState>(
//       buildWhen: (previous, current) {
//         return current is ZonesLoaded;
//       },
//       builder: (context, state) {
//         if (state is! ZonesLoaded) return SizedBox();
//
//         final zones = state.zones;
//
//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           itemCount: zones.length,
//           itemBuilder: (context, zoneIndex) {
//              ZoneModel zone = zones[zoneIndex];
//            // _cacheZone.addEntries({zone.id: zone.});
//
//             return FutureBuilder(
//                 key: Key("${zone.id}"),
//                 future: getSelectSource(zone.id),
//                 builder: (context, AsyncSnapshot<ZoneModel> snapshot) {
//
//                   print("zone.sources.length");
//                   print(zone.sources.length);
//
//                  zone.sourceSelected = snapshot.data?.sourceSelected ?? 0;
//
//                 //final ZoneModel zone =  snapshot.data!;
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(zone.name.toUpperCase()),
//                     SizedBox(height: 20,),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: zone.subZones.length,
//                       itemBuilder: (context, subzoneIndex) {
//                         ZoneSourceModel src = zone.subZones[subzoneIndex];
//
//
//                         return FutureBuilder(
//                           key: Key("$zoneIndex-$subzoneIndex"),
//                           future: getItem(zoneIndex,subzoneIndex,src,src.gainID),
//                           builder: (context, AsyncSnapshot<ZoneSourceModel> snapshot) {
//                             if (!snapshot.hasData) {
//                               return SizedBox(height: 50);
//                             }
//                             ZoneSourceModel source = snapshot.data!;
//                             print(source.gainID);
//                             return ZoneSourceCard(
//                               onTap: () {
//                                 context.read<ControlPalZonesViewModel>().selectZone(
//                                     zone,
//                                     zoneIndex,
//                                     currentSubzoneIndex : subzoneIndex,
//                                     sourceIndex: 0);
//                                 Navigator.pushNamed(
//                                   context,
//                                   Routes.zoneVolumeControlPage,
//                                 );
//                               },
//                               title: source.name,
//                               icon: source.icon,
//                               volume: source.volume,
//                             );
//                           },
//                         );
//
//
//                       },
//                     ),
//                   ],
//                 );
//               }
//             );
//           },
//         );
//       },
//     );
//   }
// }
