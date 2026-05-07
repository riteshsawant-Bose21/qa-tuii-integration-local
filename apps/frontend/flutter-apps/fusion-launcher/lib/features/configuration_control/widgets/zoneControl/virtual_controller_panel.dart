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
  WallController? controller;

  @override
  void initState() {
    final List<WallZone> zones = getZones();
    context.read<VirtualControllerViewModel>().loadZones(zones, widget.vipAddress);

    if (controller!.type == 'lt') {
      context.read<VirtualControllerViewModel>().selectZone(
        zones.first,
        0,
        "",
        subZone: zones.first.subZones.first.copyWith(ono: zones.first.subZones.first.ono.copyWith(gain: 60, mute: 0)),
        currentSubzoneIndex: 0,
        sourceIndex: 1,
      );
      print("Zone Loaded By Default for LT Controller : " + zones.first.name);
    }

    if (!widget.isDesignMode) {
      WebSocketService().connect('ws://${widget.vipAddress}:8080/ws');
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VirtualControllerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    selectedController = false;
    final List<WallZone> zones = getZones();
    context.read<VirtualControllerViewModel>().loadZones(zones, widget.vipAddress);
    if (controller!.type == 'lt') {
      context.read<VirtualControllerViewModel>().selectZone(
        zones.first,
        0,
        "",
        subZone: zones.first.subZones.first.copyWith(ono: zones.first.subZones.first.ono.copyWith(gain: 60, mute: 0)),
        currentSubzoneIndex: 0,
        sourceIndex: 1,
      );
      print("Zone Loaded By Default for LT Controller : " + zones.first.name);
    }

    if (!widget.isDesignMode) {
      WebSocketService().connect('ws://${widget.vipAddress}:8080/ws');
    }
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

  List<WallZone> getZones() {
    //  print("WallControllerConfig");
    final WallControllerConfig config = widget.config!;
    // print(config.toJson());
    // print("controllerID : " + widget.controllerID);
    final List<WallZone> _zones = <WallZone>[];
    final List<String> zoneIds = <String>[];
    controller = config.controllers.firstWhere((WallController ctrl) => ctrl.id == widget.controllerID);

    if (controller != null) {
      zoneIds.addAll(controller!.zoneIds ?? <String>[]);
    }
    print("zones : " + config.zones.length.toString());
    print("zoneIds : " + zoneIds.length.toString());

    if (zoneIds.isEmpty) {
      return _zones;
    }
    for (String id in zoneIds) {
      for (WallZone item in config.zones) {
        final WallZone? zone = WallZone(
          functionId: item.functionId,
          id: item.id,
          name: item.name,
          subZones: <WallSubZone>[],
          sources: item.sources ?? <WallZoneSource>[],
          gain: item.gain,
          ono: item.ono,
        );

        //if (id == item.id) {
        //  print("Matching ZONEID with zone $id Sucess: " + item.id);

        // }

        if (item.subZones.isNotEmpty) {
          print("Subzones found, adding sources directly to parent zone : ${item.subZones.length}");

          for (WallSubZone subZone in item.subZones) {
            if (id == subZone.id) {
              print("Matching ZONEID with subzone $id Sucess: " + item.id);
              zone!.subZones.add(
                WallSubZone(
                  id: subZone.id,
                  name: subZone.name,
                  gain: subZone.gain,
                  ono: subZone.ono,
                ),
              );
              _zones.add(zone);
            }
          }
          print(_zones.length.toString() + " zones added with subzones $id");
        } else {
          print("Subzones empty, adding sources directly to parent zone : ${item.subZones.length}");
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

    print("_zones.length");
    print(_zones.length);
    final List<WallZone> uniqueZones = mergeDuplicateWallZones(_zones);

    return uniqueZones;
  }

  List<WallZone> mergeDuplicateWallZones(
    List<WallZone> zones,
  ) {
    final Map<String, WallZone> map = <String, WallZone>{};

    for (final WallZone zone in zones) {
      final String key = zone.id;

      /// First time add zone
      if (!map.containsKey(key)) {
        map[key] = zone.copyWith(
          subZones: List<WallSubZone>.from(
            zone.subZones,
          ),
        );
        continue;
      }

      /// Duplicate found
      final WallZone existing = map[key]!;

      for (final WallSubZone subZone in zone.subZones) {
        final bool alreadyExists = existing.subZones.any(
          (WallSubZone e) => e.id == subZone.id,
        );

        if (!alreadyExists) {
          existing.subZones.add(
            subZone,
          );
        }
      }
    }

    return map.values.toList();
  }

  Widget _buildContent(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            decoration: BoxDecoration(
              color: context.colorScheme.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colorScheme.strokeLight,
                width: 1,
              ),
            ),
            child:
                (controller!.type == 'lt')
                    ? Navigator(
                      onGenerateRoute: (RouteSettings settings) {
                        return CupertinoPageRoute<dynamic>(
                          builder: (BuildContext _) => VirtualControllerVolumeControl(isArc: true, isDesignMode: widget.isDesignMode),
                          settings: const RouteSettings(name: 'volume_controller'),
                        );
                      },
                    )
                    : VirtualController(
                      isDesignMode: widget.isDesignMode,
                      onSelected: () {
                        setState(() {
                          selectedController = true;
                        });
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
