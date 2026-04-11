import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/control_tab_bar.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/message/message_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/schedule/schedule_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/settings_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/snapshots_scenes_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/zoneControl/zone_control_panel.dart';

/// Main content panel showing tabs and content for the selected controller.
///
/// Only reads from [ConfigurationControlViewmodel] to determine tab/controller.
/// Each tab panel uses its own dedicated ViewModel.
class ControlContentPanel extends StatelessWidget {
  const ControlContentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          children: <Widget>[
            /// Tab bar
            const ControlTabBar(),

            /// Content based on selected tab
            Expanded(
              child: _buildTabContent(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(ConfigControlLoaded state) {
    switch (state.currentTab) {
      case ConfigControlTab.zoneControl:
        return const ZoneControlPanel();
      case ConfigControlTab.snapshotsScenes:
        return const SnapshotsScenesPanel();
      case ConfigControlTab.schedule:
        return SchedulePanel(controllerName: state.selectedController?.name ?? '');
      case ConfigControlTab.message:
        return const MessagePanel();
      case ConfigControlTab.settings:
        return const SettingsPanel();
    }
  }
}
