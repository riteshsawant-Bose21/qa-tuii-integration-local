
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Panel displaying the virtual controller emulator
class VirtualControllerPanel extends StatefulWidget {
  final String controllerID;
  final String vipAddress;
  final bool isDesignMode;
  final WallControllerConfig config;
  const VirtualControllerPanel({super.key, this.isDesignMode = true, required this.controllerID, required this.vipAddress, required this.config});

  @override
  State<VirtualControllerPanel> createState() => _VirtualControllerPanelState();
}

class _VirtualControllerPanelState extends State<VirtualControllerPanel> {

  bool selectedController = false;

  @override
  void initState() {
    context.read<VirtualControllerViewModel>().loadZones(getZones(), widget.vipAddress);
    WebSocketService().connect('ws://${widget.vipAddress}:8080/ws');
    super.initState();
  }
  @override
  void didUpdateWidget(covariant VirtualControllerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    selectedController=false;
    context.read<VirtualControllerViewModel>().loadZones(getZones(), widget.vipAddress);
    WebSocketService().connect('ws://${widget.vipAddress}:8080/ws');
  }
  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Header
          PanelSectionHeader(semanticId: FusionTestKeys.instance.zoneControlTabVirtualControllerHeader, title: 'VIRTUAL CONTROLLER'),

          /// Content
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  getZones() {
  //  print("WallControllerConfig");
    final WallControllerConfig config = widget.config!;
    // print(config.toJson());
    // print("controllerID : " + widget.controllerID);
    final List<WallZone> _zones = <WallZone>[];
    final List<String> zoneIds = <String>[];
    final WallController? controller = config.controllers.firstWhere((WallController ctrl) => ctrl.id == widget.controllerID);

    if (controller != null) {
      zoneIds.addAll(controller.zoneIds ?? <String>[]);
    }
    // print("zones : " +  config.zones.length.toString());
    // print("zoneIds : " + zoneIds.length.toString());
    //

    if(zoneIds.isEmpty){
      return _zones;
    }

    for (WallZone item in config.zones) {
      WallZone? zone;

      for (String id in zoneIds) {

          //if (id == item.id) {
          //  print("Matching ZONEID with zone $id Sucess: " + item.id);
            zone = WallZone(
              functionId: item.functionId,
              id: id,
              name: item.name,
              subZones: <WallSubZone>[],
              sources: item.sources ?? <WallZoneSource>[],
              gain: item.gain,
              ono: item.ono,
            );
         // }


          if (item.subZones.isNotEmpty) {
            print("Subzones found, adding sources directly to parent zone : ${item.subZones.length}");

            for (WallSubZone subZone in item.subZones) {
              if (id == subZone.id) {
                print("Matching ZONEID with subzone $id Sucess: " + item.id);
                zone = zone!.copyWith(name:subZone.name );

                zone.subZones.add(
                  WallSubZone(
                    id: subZone.id,
                    name: subZone.name,
                    gain: subZone.gain,
                    ono: subZone.ono,
                  ),
                );
                _zones.add(zone!);
              }
            }

          } else {
            print(
                "Subzones empty, adding sources directly to parent zone : ${item
                    .subZones.length}");
           if (id == item.id) {
            zone!.subZones.add(
              WallSubZone(
                id: item.id,
                name: item.name,
                gain: item.gain,
                ono: WallSubZoneOno.fromJson(<String, dynamic>{
                  'subZone': item.ono.zone,
                  'gain': item.ono.gain,
                  'mute': item.ono.mute,
                }),
              ),
            );
            _zones.add(zone!);
          }
          }
      }
    }
    return _zones;
  }

  Widget _buildContent(BuildContext context) {


    return AspectRatio(
      aspectRatio: 16/9,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 24),
            decoration: BoxDecoration(
              color: context.colorScheme.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colorScheme.strokeLight,
                width: 1,
              ),
            ),
            child:selectedController ?
            Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return CupertinoPageRoute(
                  builder: (BuildContext _) => VirtualControllerVolumeControl(
                    isArc: true,
                    isDesignMode: widget.isDesignMode
                  ),
                  settings: const RouteSettings(name: 'volume_controller'),
                );
              },
            )

             :  VirtualController(isDesignMode: widget.isDesignMode, onSelected: () {
              setState(() {
                selectedController = true;
              });

            }),
          ),
        ),
      ),
    );
  }
}
