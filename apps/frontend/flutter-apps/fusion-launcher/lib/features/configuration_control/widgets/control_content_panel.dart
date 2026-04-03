import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/control_tab_bar.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/settings_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/snapshotsAndScenes/snapshots_scenes_panel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/zoneControl/zone_control_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main content panel showing tabs and content for the selected controller
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
              child: _buildTabContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(BuildContext context, ConfigControlLoaded state) {
    switch (state.currentTab) {
      case ConfigControlTab.zoneControl:
        return const ZoneControlPanel();
      case ConfigControlTab.snapshotsScenes:
        return const SnapshotsScenesPanel();
      case ConfigControlTab.schedule:
        return _buildPlaceholderContent(context, 'Schedule');
      case ConfigControlTab.message:
        return _buildPlaceholderContent(context, 'Message');
      case ConfigControlTab.settings:
        return const SettingsPanel();
    }
  }

  Widget _buildPlaceholderContent(BuildContext context, String tabName) {
    return Container(
      color: context.colorScheme.primaryBlack,
      child: Center(
        child: FusionAppText(
          text: '$tabName content coming soon',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
