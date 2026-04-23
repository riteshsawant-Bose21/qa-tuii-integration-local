import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_utils/audio_utils.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/view_model/controller_zone_view_model.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/zone_source_card.dart';
import 'package:fusion_lib/models/controller_config/controller_config.dart';
import 'package:fusion_lib/service/websocket/websocket_service.dart';

class VirtualController extends StatefulWidget {
  final Function? onSelected;
  final bool isDesignMode;
  const VirtualController({super.key,this.onSelected,required this.isDesignMode});

  @override
  State<VirtualController> createState() => _VirtualControllerState();
}

class _VirtualControllerState extends State<VirtualController> {
  final Map<String, WallSubZone> _cache = {};
  final Map<String, WallZone> _cacheZone = {};

  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  bool _isInteracting = false;

  @override
  void initState() {

    if(!widget.isDesignMode) {
      _wsSubscription = _wsService.stream.listen((encoded) {
        final Map<String, dynamic> data = jsonDecode(encoded);

        if (data['type'] == "error") {
          log(data.toString());
        }
        log(data['type'].toString());
        log(data['data']['settings'].toString());
        if (data['type'] == 'config_update') {
          final audioSettings =
          data['data']?['settings']?['audio'];

          if (audioSettings != null) {
            _processAudioUpdate(audioSettings);
          }
        }
      });
    }

    super.initState();
  }

  void _processAudioUpdate(Map<String, dynamic> audioSettings) {
    print("_processAudioUpdate");
    print(audioSettings);
    if (!mounted) return;

    // Only update from server if user is NOT interacting
    if (!_isInteracting) {


      for(var zone in _cacheZone.keys.toList()){
        print("Zone-key : $zone");
        if(_cacheZone.containsKey(zone)) {
          print("ZONE Key exists");
          for (var entry in audioSettings.entries) {
            if (zone == entry.key) {
              WallZone zoneModel = _cacheZone[zone]!;

              print(
                'incoming entry for source select ${entry
                    .value} is newer. Updating cacheZone.',
              );
              zoneModel.sourceSelected = entry.value['input'];
              _cacheZone[zone] = zoneModel;

              context
                  .read<
                  VirtualControllerViewModel>()
                  .selectSource(
                  zoneModel.sources[zoneModel.sourceSelected - 1],
                  "", // not needed since sendToService is false
                  "", // not needed since sendToService is false
                  sendToService: false
              );


              setState(() {});

            }
          }
        }else{
          print("NO ZONE Key exists");
        }
      }


      for(var item in _cache.keys.toList()){

        for(var entry in audioSettings.entries){
          if(item == entry.key) {
            WallSubZone sourceModel = _cache[item]!;

          //  int incomingTsStr = entry.value['timestamp']??0;
          //  if (sourceModel.timestamp == null || sourceModel.timestamp! < incomingTsStr) {
              print(
                'incoming entry for ${entry.value['gain']} is newer. Updating cache.',
              );

              double volume = AudioUtils().dbfsToPercentage(double.parse(entry.value['gain'].toString()));
              //double volume = double.parse(entry.value['gain'].toString()),
              // _cache[item] = sourceModel.copyWith(
              //     volume: volume,
              //     timestamp: incomingTsStr,
              //     muted: entry.value['mute']);

            bool muted = entry.value['mute'];

              _cache[item] = sourceModel.copyWith(
                ono: sourceModel.ono.copyWith(gain: volume.toInt(),mute: muted  ? 1 :0),
              );

              context
                  .read<
                  VirtualControllerViewModel>()
                  .updateVolume(_cache[item]!,
                  volume,
                  sendToService: false,
                  isMuted: muted);



              // context.read<VirtualControllerViewModel>().updateVolume(array.first,sourceModel,AudioUtils.toUiVolume(entry.value['gain']));
              setState(() {});
           // }
          }
        }

      }

    }
  }

  Future<WallZone> getSelectSource(String funcID) async{
    if (!_cacheZone.containsKey(funcID)) {

      WallZone sourceModel = await context.read<VirtualControllerViewModel>().getSelectSource(funcID); // only once per item
      WebSocketService().subscribe(funcID);
      _cacheZone[funcID] = sourceModel;

      return sourceModel;
    }

    return Future.value(_cacheZone[funcID]);

  }


  Future<WallSubZone> getItem(int zoneIndex,int subzoneIndex,WallSubZone src) async{
    String gainId = src.gain.gainID;
    if (!_cache.containsKey(gainId)) {

      WallSubZone sourceModel = await context.read<VirtualControllerViewModel>().getGain(zoneIndex,subzoneIndex,src);
      try {
        WebSocketService().subscribe(gainId);
      }catch(e){
        log("Error subscribing to gainId $gainId: $e");
      }

      _cache[gainId] = sourceModel;

      return sourceModel;
    }
    print("sourceModel.ono.gain");
    print(_cache[gainId]!.ono.gain.toString());
    return Future.value(_cache[gainId]);

  }
  @override
  void dispose() {

    _wsSubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VirtualControllerViewModel, VirtualControllerState>(
      buildWhen: (previous, current) {
        return current is VirtualZonesLoaded;
      },
      builder: (context, state) {
        if (state is! VirtualZonesLoaded) return SizedBox();

        final zones = state.zones;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: zones.length,
          itemBuilder: (context, zoneIndex) {
            WallZone zone = zones[zoneIndex];
     

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name.toUpperCase()),
                SizedBox(height: 8,),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: zone.subZones.length,
                  itemBuilder: (context, subzoneIndex) {
                    WallSubZone src = zone.subZones[subzoneIndex];


                    return FutureBuilder(
                    //  key: Key("$zoneIndex-$subzoneIndex"),
                      future: getItem(zoneIndex,subzoneIndex,src),
                      builder: (context, AsyncSnapshot<WallSubZone> snapshot) {
                        if (!snapshot.hasData) {

                          return Container(height: 50,width: 100);
                        }
                        WallSubZone subzone = snapshot.data!;


                        return  FutureBuilder(
                            key: Key(zone.id),
                            future: getSelectSource("${zone.functionId ?? ""}/selector"),
                            builder: (context, AsyncSnapshot<WallZone> snapshot) {

                              zone.sourceSelected = snapshot.data?.sourceSelected ?? 1;
                              return ZoneSourceCard(
                                onTap: () {
                                  context.read<VirtualControllerViewModel>().selectZone(
                                      zone,
                                      zoneIndex,
                                      src.gain.gainID,
                                      subZone: subzone,
                                      currentSubzoneIndex : subzoneIndex,
                                      sourceIndex:  zone.sourceSelected);
                                  widget.onSelected!();

                                },
                                title: subzone.name,
                                icon: Icons.eighteen_up_rating_outlined,
                                volume: subzone.ono.gain.toDouble(),
                              );
                            }
                        );
                      },
                    );


                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

}