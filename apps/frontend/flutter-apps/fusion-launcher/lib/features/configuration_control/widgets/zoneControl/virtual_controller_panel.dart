import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
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
  @override
  Widget build(BuildContext context) {
    context.read<VirtualControllerViewModel>().loadZones(getZones(), widget.vipAddress);

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
          const PanelSectionHeader(title: 'VIRTUAL CONTROLLER'),

          /// Content
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  getZones() {
    print("WallControllerConfig");
    final WallControllerConfig config = widget.config!;
    print(config.toJson());
    print("controllerID : " + widget.controllerID);
    final List<WallZone> _zones = <WallZone>[];
    final List<String> zoneIds = <String>[];
    final WallController? controller = config.controllers.firstWhere((WallController ctrl) => ctrl.id == widget.controllerID);

    if (controller != null) {
      zoneIds.addAll(controller.zoneIds ?? <String>[]);
    }
    print("zoneIds : " + zoneIds.length.toString());

    for (WallZone item in config.zones ?? <WallZone>[]) {
      WallZone? zone;
      for (String id in zoneIds) {
        if (id == item.id) {
          zone = WallZone(
            id: id,
            name: item.name,
            subZones: <WallSubZone>[],
            sources: item.sources ?? <WallZoneSource>[],
            gain: item.gain,
            ono: item.ono,
          );
        }
      }

      if (item.subZones.isNotEmpty) {
        print("Subzones found, adding sources directly to parent zone : ${item.subZones.length}");

        for (WallSubZone subZone in item.subZones) {
          zone!.subZones.add(
            WallSubZone(
              id: subZone.id,
              name: subZone.name,
              gain: subZone.gain,
              ono: subZone.ono,
            ),
          );
        }
        _zones.add(zone!);
      } else {
        print("Subzones empty, adding sources directly to parent zone : ${item.subZones.length}");

        zone!.subZones.add(
          WallSubZone(
            id: item.id,
            name: item.name,
            gain: item.gain,
            ono: WallSubZoneOno.fromJson(<String, dynamic>{
              'subZone': 0,
              'gain': 0,
              'mute': 0,
            }),
          ),
        );
        _zones.add(zone);
      }

      return _zones;
    }
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colorScheme.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: VirtualController(isDesignMode: widget.isDesignMode, onSelected: () {}),
        ),
      ),
    );
  }
}
