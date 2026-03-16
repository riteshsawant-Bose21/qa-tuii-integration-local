import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/exandable_section.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../control_dashboard/presentation/widgets/zones/audio_meter_widget.dart';
import '../../../control_dashboard/presentation/widgets/zones/dashboard_circuit_widget.dart';
import '../../../control_dashboard/presentation/widgets/zones/subzone_dashboard_content.dart';
import 'config_zone_control_header.dart';

class ConfigZoneControlModePanel extends StatelessWidget {
  final Zone zone;

  const ConfigZoneControlModePanel({
    super.key,
    required this.zone,
  });

  List<SubZone> get subZones {
    return serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
  }

  List<CircuitModel> get circuits {
    return serviceLocator<ProjectViewModel>().getCircuitsInZone(zone.id);
  }

  @override
  Widget build(BuildContext context) {
    print("Zone ${zone.name} has  muted state: ${zone.muted}");
    return SingleChildScrollView(
      child: Container(
        color: context.colorScheme.elevation2,
        child: Column(
          children: <Widget>[
            ConfigZoneControlHeader(zone: zone),

            AudioMeterContainer(
              muted: zone.muted,
            ),

            if (subZones.isEmpty) ...<Widget>[
              if (circuits.isNotEmpty) ...<Widget>[
                CircuitExpandableSection(
                  title: 'Circuits',
                  children:
                      circuits
                          .map(
                            (CircuitModel circuit) => DashboardCircuitWidget(
                              circuit: circuit,
                              isZoneMuted: zone.muted,
                            ),
                          )
                          .toList(),
                ),
              ],
            ] else ...<Widget>[
              SubZonesListing(
                subZones: subZones,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SubZonesListing extends StatelessWidget {
  final List<SubZone> subZones;

  const SubZonesListing({
    super.key,
    required this.subZones,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        ),
      ),
      child: Column(
        children: <Widget>[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subZones.length,
            itemBuilder: (BuildContext context, int index) {
              final SubZone subZone = subZones[index];
              final bool isLastItem = index == subZones.length - 1;
              return SubzoneDashboardContent(
                subZone: subZone,
                isLast: isLastItem,
              );
            },
          ),
        ],
      ),
    );
  }
}
