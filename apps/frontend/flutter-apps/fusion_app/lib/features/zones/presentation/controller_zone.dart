import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/view_model/controlpal_zone_view_model.dart';
import 'package:fusion_app/features/zones/widgets/zone_source_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ControllerZones extends StatefulWidget {
  const ControllerZones({super.key});

  @override
  State<ControllerZones> createState() => _ControllerZonesState();
}

class _ControllerZonesState extends State<ControllerZones> {

  // final List<ZoneModel> zones = [
  //   ZoneModel(
  //     id: "1",
  //     name: "RECEPTION",
  //     sources: [
  //       ZoneSourceModel(
  //         id: "spotify",
  //         name: "Spotify",
  //         icon: Icons.wifi,
  //         volume: 37,
  //       ),
  //     ],
  //   ),
  //
  //   ZoneModel(
  //     id: "2",
  //     name: "GYM WEIGHTS",
  //     sources: [
  //       ZoneSourceModel(
  //         id: "phone",
  //         name: "Namith's Phone",
  //         icon: Icons.smartphone,
  //         volume: 82,
  //       ),
  //       ZoneSourceModel(
  //         id: "laptop",
  //         name: "Namith's Laptop",
  //         icon: Icons.laptop,
  //         volume: 64,
  //       ),
  //     ],
  //   ),
  //
  //   ZoneModel(
  //     id: "3",
  //     name: "GYM CARDIO",
  //     sources: [
  //       ZoneSourceModel(
  //         id: "mic",
  //         name: "Wireless Mics",
  //         icon: Icons.mic,
  //         volume: 0,
  //         muted: true,
  //       ),
  //     ],
  //   ),
  //
  //   ZoneModel(
  //     id: "4",
  //     name: "STUDIO PLATINUM",
  //     sources: [
  //       ZoneSourceModel(
  //         id: "youtube",
  //         name: "YouTube",
  //         icon: Icons.play_circle_outline,
  //         volume: 28,
  //       ),
  //     ],
  //   ),
  // ];
  @override
  void initState() {
    // TODO: implement initState

    context.read<ControlPalZonesViewModel>().loadZones(serviceLocator<QrScannerViewModel>().getZones);

    super.initState();
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
                    final source = zone.sources[sourceIndex];



                    return ZoneSourceCard(
                      onTap: () {
                        context.read<ControlPalZonesViewModel>().selectZone(zone,zoneIndex,sourceIndex: sourceIndex);
                        Navigator.pushNamed(
                          context,
                          Routes.zoneVolumeControlPage,
                          // arguments: {
                          //   'zoneIndex': zoneIndex,
                          //   'sourceIndex': sourceIndex,
                          // },
                        );
                      },
                      title: source.name,
                      icon: source.icon,
                      volume: source.volume,
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
