import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/exandable_section.dart';
import 'package:fusion_launcher/features/control_dashboard/view_models/zone_control_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'audio_meter_widget.dart';
import 'dashboard_circuit_widget.dart';
import 'subzone_dashboard_content.dart';
import 'zone_control_header.dart';

class ZoneControlCard extends StatelessWidget {
  final Zone zone;

  const ZoneControlCard({
    super.key,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ZoneControlViewModel>(
      key: ValueKey<String>('zone_ctrl_${zone.id}'),
      create: (_) => ZoneControlViewModel(zoneId: zone.id),
      child: Builder(
        builder: (BuildContext context) {
          final ZoneControlViewModel vm = context.read<ZoneControlViewModel>();

          return ClipRect(
            clipBehavior: Clip.antiAlias,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              decoration: ShapeDecoration(
                color: context.colorScheme.primaryBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    width: 1,
                    color: context.colorScheme.strokeDark,
                  ),
                ),
              ),
              child: Column(
                children: <Widget>[
                  ZoneControlHeader(zone: zone),

                  AudioMeterContainer(
                    meterId: vm.processingBlock?.id,
                  ),

                  if (vm.subZones.isEmpty) ...<Widget>[
                    if (vm.circuits.isNotEmpty) ...<Widget>[
                      CircuitExpandableSection(
                        title: 'Circuits',
                        children:
                            vm.circuits
                                .map(
                                  (CircuitModel circuit) => DashboardCircuitWidget(
                                    circuit: circuit,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ] else ...<Widget>[
                    SubZonesListing(
                      subZones: vm.subZones,
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
