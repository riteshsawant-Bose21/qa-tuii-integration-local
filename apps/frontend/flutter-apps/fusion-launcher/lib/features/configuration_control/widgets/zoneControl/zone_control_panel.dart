import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/zoneControl/zones_list_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/zoneControl/virtual_controller_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Panel displaying zone control content with zones and virtual controller
class ZoneControlPanel extends StatelessWidget {
  const ZoneControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          color: context.colorScheme.primaryBlack,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Zones list
              SizedBox(
                width: 280,
                child: ZonesListPanel(
                  zones: state.zones,
                  subZonesInZones: state.subZonesInZones,
                  selectedZoneIds: state.selectedZoneIds,
                  selectedZoneId: state.selectedZoneId,
                  isProController: state.isProController,
                ),
              ),
              const SizedBox(width: 16),

              /// Virtual controller emulator
              const Expanded(
                child: VirtualControllerPanel(),
              ),
            ],
          ),
        );
      },
    );
  }
}
