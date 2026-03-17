import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../control_dashboard/presentation/widgets/zones/dashboard_circuit_widget.dart';
import 'config_audio_meter.dart';
import 'config_circuit_exandable_section.dart';
import 'config_control_mode_subzone_listing.dart';
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
            /// Zone header with name and mute control
            ConfigZoneControlHeader(zone: zone),

            /// Zone audio meter showing current audio levels and mute status
            ConfigAudioMeter(
              muted: zone.muted,
            ),

            if (subZones.isEmpty) ...<Widget>[
              if (circuits.isNotEmpty) ...<Widget>[
                ConfigCircuitExpandableSection(
                  title: 'Circuits',
                  children:
                      circuits
                          .map(
                            (CircuitModel circuit) => DashboardCircuitWidget(
                              circuit: circuit,
                            ),
                          )
                          .toList(),
                ),
              ],
            ] else ...<Widget>[
              ConfigControlModeSubzoneListing(
                subZones: subZones,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
