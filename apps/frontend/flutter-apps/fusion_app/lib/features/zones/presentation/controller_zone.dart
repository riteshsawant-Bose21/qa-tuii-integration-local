import 'dart:async';

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
    if (!mounted) return;

    // Only update from server if user is NOT interacting
    if (!_isInteracting) {

        for(var item in _cache.keys.toList()){
          List array = item.split("-");


          for(var entry in audioSettings.entries){
            if(array.last == entry.key) {
              ZoneSourceModel sourceModel = _cache[item]!;

              int incomingTsStr = entry.value['timestamp'];
              if (sourceModel.timestamp == null || sourceModel.timestamp! < incomingTsStr) {


              _cache[item] = sourceModel.copyWith(
                  volume: AudioUtils.toUiVolume(entry.value['gain']),
                  timestamp: incomingTsStr,
                  muted: entry.value['mute']);
              setState(() {});
            }
            }
          }

        }

    }
  }


  Future<ZoneSourceModel> getItem(int zoneIndex,int sourceIndex,ZoneSourceModel zoneSrcModel,String gainID) async{
    if (!_cache.containsKey("$zoneIndex-$sourceIndex-$gainID")) {

      ZoneSourceModel sourceModel = await context.read<ControlPalZonesViewModel>().getGain(zoneIndex,sourceIndex,zoneSrcModel); // only once per item
      FusionWebSocketService().subscribe(sourceModel.id);
      _cache["$zoneIndex-$sourceIndex-$gainID"] = sourceModel;

      return sourceModel;
    }

    return Future.value(_cache["$zoneIndex-$sourceIndex-$gainID"]);

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
                  itemCount: zone.sources.length,
                  itemBuilder: (context, sourceIndex) {
                    ZoneSourceModel src = zone.sources[sourceIndex];


                    return FutureBuilder(
                      key: Key("$zoneIndex-$sourceIndex"),
                      future: getItem(zoneIndex,sourceIndex,src,zone.gainID),
                      builder: (context, AsyncSnapshot<ZoneSourceModel> snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(height: 50);
                        }
                        ZoneSourceModel source = snapshot.data!;
                        return ZoneSourceCard(
                          onTap: () {
                            context.read<ControlPalZonesViewModel>().selectZone(zone,zoneIndex,sourceIndex: sourceIndex);
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
