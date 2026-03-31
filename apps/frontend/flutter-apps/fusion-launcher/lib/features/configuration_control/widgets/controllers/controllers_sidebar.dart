import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_dialog.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_sidebar_header.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_search_bar.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controller_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Sidebar widget displaying controllers list
class ControllersSidebar extends StatelessWidget {
  const ControllersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          children: <Widget>[
            /// Header
            ControllersSidebarHeader(
              onAddController: () => _handleAddController(context),
            ),

            /// Search bar
            const ControllersSearchBar(),

            /// Controllers list
            Expanded(
              child: _buildControllersList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControllersList(BuildContext context, ConfigControlLoaded state) {
    final List<FusionController> controllers = state.filteredControllers;

    if (controllers.isEmpty && state.searchQuery.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          border: Border(
            left: BorderSide(color: context.colorScheme.elevation2, width: 1),
            right: BorderSide(color: context.colorScheme.elevation2, width: 1),
            bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FusionAppText(
              text: 'No controllers match your search',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border(
          left: BorderSide(color: context.colorScheme.elevation2, width: 1),
          right: BorderSide(color: context.colorScheme.elevation2, width: 1),
          bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controllers.length,
        itemBuilder: (BuildContext context, int index) {
          final FusionController controller = controllers[index];
          final bool isSelected = controller.id == state.selectedControllerId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ControllerCard(
              controller: controller,
              isSelected: isSelected,
              zones: state.zones,
              subZonesInZones: state.subZonesInZones,
              onTap: () => context.read<ConfigurationControlViewmodel>().selectController(controller.id),
              onDelete: () => context.read<ConfigurationControlViewmodel>().deleteController(controller.id),
            ),
          );
        },
      ),
    );
  }

  void _handleAddController(BuildContext context) {
    AddControllerDialog.show(
      context,
      onControllerAdded: () {
        context.read<ConfigurationControlViewmodel>().refresh();
      },
    );
  }
}
