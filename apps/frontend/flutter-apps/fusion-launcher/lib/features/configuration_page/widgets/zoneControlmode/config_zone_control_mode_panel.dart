import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/view_models/zone_control_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../control_dashboard/presentation/widgets/zones/audio_meter_widget.dart';
import '../../../control_dashboard/presentation/widgets/zones/dashboard_circuit_widget.dart';

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
    return BlocProvider<ZoneControlViewModel>(
      key: ValueKey<String>('config_zone_ctrl_${zone.id}'),
      create: (_) => ZoneControlViewModel(zoneId: zone.id),
      child: Builder(
        builder: (BuildContext context) {
          final ZoneControlViewModel vm = context.read<ZoneControlViewModel>();

          return SingleChildScrollView(
            child: Container(
              color: context.colorScheme.elevation2,
              child: Column(
                children: <Widget>[
                  /// Zone header with name and mute control
                  ConfigZoneControlHeader(zone: zone),

                  /// Zone audio meter showing current audio levels and mute status
                  AudioMeterContainer(
                    meterId: vm.processingBlock?.id,
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
                                    fromConfiguration: true,
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
        },
      ),
    );
  }
}
