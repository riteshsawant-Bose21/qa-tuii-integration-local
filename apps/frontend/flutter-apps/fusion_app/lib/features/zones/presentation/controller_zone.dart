import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/core/services/websocket_service.dart';
import 'package:fusion_app/core/utils/audio_utils.dart';
import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/view_model/controlpal_zone_view_model.dart';
import 'package:fusion_app/features/zones/widgets/zone_source_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ControllerZones extends StatefulWidget {
  const ControllerZones({super.key});

  @override
  State<ControllerZones> createState() => _ControllerZonesState();
}

class _ControllerZonesState extends State<ControllerZones> {
  final Map<String, ZoneSourceModel> _cache = {};
  final Map<String, dynamic> _cacheSource = {};

  final _wsService = FusionWebSocketService();
  StreamSubscription? _wsSubscription;
  bool _isInteracting = false;

  @override
  void initState() {
    // TODO: implement initState

    context.read<ControlPalZonesViewModel>().loadZones(serviceLocator<QrScannerViewModel>().getZones);

    // Listen for server-side updates
    _wsSubscription = _wsService.audioUpdateStream.listen((audioSettings) {
      _processAudioUpdate(audioSettings);
    });

    super.initState();
  }

  void _processAudioUpdate(Map<String, dynamic> audioSettings) {
    print("_processAudioUpdate");
   // log(audioSettings.toString());
    if (!mounted) return;

    // Only update from server if user is NOT interacting
    if (!_isInteracting) {
        print(_cache);
        for(var item in _cache.keys.toList()){
          List array = item.split("-");


          for(var entry in audioSettings.entries){
            if(array.last == entry.key) {
              print(entry.key);
              print(entry.value);

             if(entry.value['input']==null){

              ZoneSourceModel sourceModel = _cache[item]!;

              int incomingTsStr = entry.value['timestamp'];
              if (sourceModel.timestamp == null || sourceModel.timestamp! < incomingTsStr) {
                _cache[item] = sourceModel.copyWith(
                    volume: AudioUtils.toUiVolume(entry.value['gain']),
                    timestamp: incomingTsStr,
                    muted: entry.value['mute']);
              }


             // context.read<ControlPalZonesViewModel>().updateVolume(array.first,sourceModel,AudioUtils.toUiVolume(entry.value['gain']));
              setState(() {});
            }else{
                print("Source update for ${entry.value}, ignoring.");
                _cacheSource.addEntries(entry.value);
              }
            }
          }

        }

    }
  }


  Future<ZoneSourceModel> getItem(int zoneIndex,int subzoneIndex,ZoneSourceModel zoneSrcModel,String gainID) async{
    if (!_cache.containsKey("$zoneIndex-$subzoneIndex-$gainID")) {

      ZoneSourceModel sourceModel = await context.read<ControlPalZonesViewModel>().getGain(zoneIndex,subzoneIndex,zoneSrcModel); // only once per item
      FusionWebSocketService().subscribe(gainID);
      _cache["$zoneIndex-$subzoneIndex-$gainID"] = sourceModel;

      return sourceModel;
    }

    return Future.value(_cache["$zoneIndex-$subzoneIndex-$gainID"]);

  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ControlPalZonesViewModel, ControlPalZonesState>(
      buildWhen: (previous, current) {
        return current is ZonesLoaded;
      },
      builder: (context, state) {
        if (state is! ZonesLoaded) return SizedBox();

        final zones = state.zones;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: zones.length,
          itemBuilder: (context, zoneIndex) {
            final ZoneModel zone = zones[zoneIndex];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name.toUpperCase()),
                SizedBox(height: 20,),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: zone.subZones.length,
                  itemBuilder: (context, subzoneIndex) {
                    ZoneSourceModel src = zone.subZones[subzoneIndex];


                    return FutureBuilder(
                      key: Key("$zoneIndex-$subzoneIndex"),
                      future: getItem(zoneIndex,subzoneIndex,src,src.gainID),
                      builder: (context, AsyncSnapshot<ZoneSourceModel> snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(height: 50);
                        }

                        ZoneSourceModel source = snapshot.data!;
                        print(source.gainID);
                        return ZoneSourceCard(
                          onTap: () {
                            context.read<ControlPalZonesViewModel>().selectZone(
                                zone,
                                zoneIndex,
                                currentSubzoneIndex : subzoneIndex,
                                sourceIndex: 0);
                            Navigator.pushNamed(
                              context,
                              Routes.zoneVolumeControlPage,
                            );
                          },
                          title: source.name,
                          icon: source.icon,
                          volume: source.volume,
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
