import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/widgets/zone_source_card.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ControllerZones extends StatefulWidget {
  const ControllerZones({super.key});

  @override
  State<ControllerZones> createState() => _ControllerZonesState();
}

class _ControllerZonesState extends State<ControllerZones> {

  final List<ZoneModel> zones = [
    ZoneModel(
      id: "1",
      name: "RECEPTION",
      sources: [
        ZoneSourceModel(
          id: "spotify",
          name: "Spotify",
          icon: Icons.wifi,
          volume: 37,
        ),
      ],
    ),

    ZoneModel(
      id: "2",
      name: "GYM WEIGHTS",
      sources: [
        ZoneSourceModel(
          id: "phone",
          name: "Namith's Phone",
          icon: Icons.smartphone,
          volume: 82,
        ),
        ZoneSourceModel(
          id: "laptop",
          name: "Namith's Laptop",
          icon: Icons.laptop,
          volume: 64,
        ),
      ],
    ),

    ZoneModel(
      id: "3",
      name: "GYM CARDIO",
      sources: [
        ZoneSourceModel(
          id: "mic",
          name: "Wireless Mics",
          icon: Icons.mic,
          volume: 0,
          muted: true,
        ),
      ],
    ),

    ZoneModel(
      id: "4",
      name: "STUDIO PLATINUM",
      sources: [
        ZoneSourceModel(
          id: "youtube",
          name: "YouTube",
          icon: Icons.play_circle_outline,
          volume: 28,
        ),
      ],
    ),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
      itemCount: zones.length,
      itemBuilder: (context, zoneIndex) {
        final zone = zones[zoneIndex];
        final sources = zone.sources;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              zone.name.toUpperCase(),
              style: Theme.of(context).textTheme.b3Regular.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.textBody,
              ),
            ),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: sources.length,
                itemBuilder: (context,sourceIndex){
                  final source = sources[sourceIndex];

              return ZoneSourceCard(
                  onTap: (){
                    Navigator.pushNamed(context, Routes.zoneVolumeControlPage,arguments: {
                      'zones': zones,
                      'zoneIndex': zoneIndex,
                      'sourceId': source.id,
                      'onNext':(){

                      },
                      'onPrevious':(){

                      },
                      'onVolumeChanged':(volume){

                        zones[zoneIndex].sources[sourceIndex] = source.copyWith(volume: volume,muted: volume > 0 ? false : true);

                        setState(() {

                        });
                      },
                    });
                  },
                  title: source.name,
                  icon: source.icon,
                  volume: source.volume
              );
            }),

            const SizedBox(height: 8),
          ]
        );
      },
    );
  }
}
