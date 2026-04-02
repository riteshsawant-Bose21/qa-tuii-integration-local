import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_dialog.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_sidebar_header.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_list.dart';
import 'package:fusion_lib/fusion_lib.dart';

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

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border(
              left: BorderSide(color: context.colorScheme.elevation2, width: 1),
              top: BorderSide(color: context.colorScheme.elevation2, width: 1),
              bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
            ),
          ),
          child: Column(
            children: <Widget>[
              /// Header
              ControllersSidebarHeader(
                onAddController: () => _handleAddController(context),
              ),

              /// Search bar
              // const ControllersSearchBar(),

              /// Controllers list
              Expanded(
                child: ControllersList(
                  controllers: state.filteredControllers,
                  selectedControllerId: state.selectedControllerId,
                  searchQuery: state.searchQuery,
                ),
              ),
            ],
          ),
        );
      },
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
