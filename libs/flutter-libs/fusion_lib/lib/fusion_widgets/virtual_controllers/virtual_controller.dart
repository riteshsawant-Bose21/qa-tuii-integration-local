import 'dart:async';

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
  const VirtualController({super.key, this.onSelected, required this.isDesignMode});

  @override
  State<VirtualController> createState() => _VirtualControllerState();
}

class _VirtualControllerState extends State<VirtualController> {
  final Map<String, WallSubZone> _cache = {};
  final Map<String, WallZone> _cacheZone = {};

  final _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  bool _isInteracting = false;

  @override
  void initState() {
    // TODO: implement initState

    // Listen for server-side updates
    _wsSubscription = _wsService.stream.listen((audioSettings) {
      _processAudioUpdate(audioSettings);
    });

    super.initState();
  }

  void _processAudioUpdate(Map<String, dynamic> audioSettings) {
    print("_processAudioUpdate");
    if (!mounted) return;

    // Only update from server if user is NOT interacting
    if (!_isInteracting) {
      for (var zone in _cacheZone.keys.toList()) {
        print("Zone-key : " + zone);
        if (_cacheZone.containsKey(zone)) {
          print("ZONE Key exists");
          for (var entry in audioSettings.entries) {
            if (zone == entry.key) {
              WallZone zoneModel = _cacheZone[zone]!;

              print(
                'incoming entry for source select ${entry.value} is newer. Updating cacheZone.',
              );
              zoneModel.sourceSelected = entry.value['input'];
              _cacheZone[zone] = zoneModel;

              context.read<VirtualControllerViewModel>().selectSource(
                zoneModel.sources[zoneModel.sourceSelected - 1],
                "", // not needed since sendToService is false
                "", // not needed since sendToService is false
                sendToService: false,
              );

              setState(() {});
            }
          }
        } else {
          print("NO ZONE Key exists");
        }
      }

      for (var item in _cache.keys.toList()) {
        for (var entry in audioSettings.entries) {
          if (item == entry.key) {
            WallSubZone sourceModel = _cache[item]!;

            //  int incomingTsStr = entry.value['timestamp']??0;
            //  if (sourceModel.timestamp == null || sourceModel.timestamp! < incomingTsStr) {
            print(
              'incoming entry for ${entry.value['gain']} is newer. Updating cache.',
            );

            double volume = AudioUtils.toUiVolume(double.parse(entry.value['gain'].toString()));
            //double volume = double.parse(entry.value['gain'].toString()),
            // _cache[item] = sourceModel.copyWith(
            //     volume: volume,
            //     timestamp: incomingTsStr,
            //     muted: entry.value['mute']);

            _cache[item] = sourceModel.copyWith(
              ono: sourceModel.ono.copyWith(gain: volume.toInt(), mute: volume == 0 ? 0 : 1),
            );

            context.read<VirtualControllerViewModel>().updateVolume(_cache[item]!, volume, sendToService: false);

            // context.read<VirtualControllerViewModel>().updateVolume(array.first,sourceModel,AudioUtils.toUiVolume(entry.value['gain']));
            setState(() {});
            // }
          }
        }
      }
    }
  }

  Future<WallZone> getSelectSource(String zoneID) async {
    if (!_cacheZone.containsKey(zoneID)) {
      WallZone sourceModel = await context.read<VirtualControllerViewModel>().getSelectSource(zoneID); // only once per item
      // WebSocketService().subscribe(zoneID);
      _cacheZone[zoneID] = sourceModel;

      return sourceModel;
    }

    return Future.value(_cacheZone[zoneID]);
  }

  Future<WallSubZone> getItem(int zoneIndex, int subzoneIndex, WallSubZone src) async {
    String gainId = src.gain.gainID;
    if (!_cache.containsKey(gainId)) {
      WallSubZone sourceModel = await context.read<VirtualControllerViewModel>().getGain(zoneIndex, subzoneIndex, src);
      // WebSocketService().subscribe(gainId);
      _cache[gainId] = sourceModel;

      return sourceModel;
    }

    return Future.value(_cache[gainId]);
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
            // _cacheZone.addEntries({zone.id: zone.});

            return FutureBuilder(
              key: Key(zone.id),
              future: getSelectSource(zone.id),
              builder: (context, AsyncSnapshot<WallZone> snapshot) {
                zone.sourceSelected = snapshot.data?.sourceSelected ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name.toUpperCase()),
                    SizedBox(
                      height: 20,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: zone.subZones.length,
                      itemBuilder: (context, subzoneIndex) {
                        WallSubZone src = zone.subZones[subzoneIndex];

                        return FutureBuilder(
                          key: Key("$zoneIndex-$subzoneIndex"),
                          future: getItem(zoneIndex, subzoneIndex, src),
                          builder: (context, AsyncSnapshot<WallSubZone> snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                height: 50,
                                width: 100,
                                color: Colors.green,
                              );
                            }
                            WallSubZone source = snapshot.data!;
                            print(source.gain.gainID);
                            return ZoneSourceCard(
                              onTap: () {
                                context.read<VirtualControllerViewModel>().selectZone(zone, zoneIndex, currentSubzoneIndex: subzoneIndex, sourceIndex: 0);
                                widget.onSelected!();
                              },
                              title: source.name,
                              icon: Icons.eighteen_up_rating_outlined,
                              volume: source.ono.gain.toDouble(),
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
      },
    );
  }
}
