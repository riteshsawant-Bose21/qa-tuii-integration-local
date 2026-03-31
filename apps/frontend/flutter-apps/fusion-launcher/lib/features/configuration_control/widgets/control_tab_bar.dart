import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Tab bar widget for switching between control tabs
class ControlTabBar extends StatelessWidget {
  const ControlTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      buildWhen: (ConfigurationControlState previous, ConfigurationControlState current) {
        return previous.currentTab != current.currentTab || previous.selectedControllerId != current.selectedControllerId;
      },
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        final FusionController? selectedController = state.selectedController;
        final List<ConfigControlTab> tabs = _getTabsForController(selectedController);

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.elevation2,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children:
                tabs.map((ConfigControlTab tab) {
                  final bool isSelected = state.currentTab == tab;
                  return _TabItem(
                    tab: tab,
                    isSelected: isSelected,
                    onTap: () => context.read<ConfigurationControlViewmodel>().changeTab(tab),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  /// Check if the controller is a Pro type
  bool _isProController(FusionController? controller) {
    if (controller == null) return false;
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  List<ConfigControlTab> _getTabsForController(FusionController? controller) {
    // If controller is Pro type, show all tabs
    if (_isProController(controller)) {
      return ConfigControlTab.values;
    }

    // For LT or basic controllers, show limited tabs
    return <ConfigControlTab>[
      ConfigControlTab.zoneControl,
      ConfigControlTab.settings,
    ];
  }
}

class _TabItem extends StatelessWidget {
  final ConfigControlTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? context.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: FusionAppText(
          text: _getTabLabel(tab),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getTabLabel(ConfigControlTab tab) {
    switch (tab) {
      case ConfigControlTab.zoneControl:
        return 'Zone Control';
      case ConfigControlTab.snapshotsScenes:
        return 'Snapshot / Scene Set';
      case ConfigControlTab.schedule:
        return 'Schedule';
      case ConfigControlTab.message:
        return 'Message';
      case ConfigControlTab.settings:
        return 'Settings';
    }
  }
}
