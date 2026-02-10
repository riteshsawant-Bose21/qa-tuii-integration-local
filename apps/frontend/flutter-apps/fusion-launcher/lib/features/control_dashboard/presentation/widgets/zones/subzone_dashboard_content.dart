import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'audio_meter_widget.dart';
import 'dashboard_circuit_widget.dart';
import 'exandable_section.dart';
import 'volume_control_buttons.dart';

class SubzoneDashboardContent extends StatelessWidget {
  final SubZone subZone;
  final bool isLast;

  const SubzoneDashboardContent({
    super.key,
    required this.subZone,
    this.isLast = false,
  });

  List<CircuitModel> get circuits {
    return serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZone.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius:
            isLast
                ? const BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                )
                : null,
      ),
      // padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: subZone.name,
                    style: context.textTheme.labelMedium,
                  ),
                ),

                VolumeControlButtons(
                  onVolumeChanged: (double newVolume) {
                    // Handle volume change logic here
                  },
                  onIncrement: () {
                    // Handle increment logic here
                  },
                  onDecrement: () {
                    // Handle decrement logic here
                  },
                ),

                // Fix 1: Volume Icon
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero, // Removes internal padding
                  constraints: const BoxConstraints(), // Removes 48px limit
                  icon: Icon(
                    Icons.volume_up_outlined,
                    size: 16,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ],
            ),
          ),

          const AudioMeterContainer(),

          if (circuits.isNotEmpty) ...<Widget>[
            CircuitExpandableSection(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

          SizedBox(
            height: isLast ? 10 : 5,
          ),

          if (!isLast)
            Divider(
              color: context.colorScheme.elevation2,
              thickness: 1,
            ),
        ],
      ),
    );
  }
}
