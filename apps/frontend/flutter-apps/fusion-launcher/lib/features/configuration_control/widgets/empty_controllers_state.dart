import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_dialog.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_sidebar_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Empty state widget displayed when no controllers are in the project
class EmptyControllersState extends StatelessWidget {
  const EmptyControllersState({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        /// Left sidebar with header
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border(
              left: BorderSide(color: context.colorScheme.elevation2, width: 1),
              top: BorderSide(color: context.colorScheme.elevation2, width: 1),
            ),
          ),
          width: MediaQuery.of(context).size.width * 0.17,
          child: Column(
            children: <Widget>[
              ControllersSidebarHeader(
                onAddController: () => _showAddControllerDialog(context),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation1,
                    border: Border(
                      right: BorderSide(
                        color: context.colorScheme.strokeLight,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Main content area with empty state message
        Expanded(
          child: Container(
            color: context.colorScheme.elevation1,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                /// Warning icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.colorScheme.warningText,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    size: 40,
                    color: context.colorScheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 32),

                /// Title
                FusionAppText(text: 'No Controllers found in this project', style: Theme.of(context).textTheme.h4SemiBold),
                const SizedBox(height: 8),

                /// Subtitle
                FusionAppText(
                  text: 'Please add Controllers to your project to configure controllers.',
                  style: Theme.of(context).textTheme.b3Regular.withColor(context.colorScheme.textSecondary),
                ),
                const SizedBox(height: 23),

                /// Add controller button
                FusionAppButton(
                  style: FusionAppButtonStyle.primary,
                  height: 32,
                  width: 195,
                  borderRadius: 8,
                  semanticId: 'add_controllers_to_project',
                  textstyle: context.textTheme.l1Medium,
                  text: 'Add controllers to project  +',
                  onPressed: () => _showAddControllerDialog(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddControllerDialog(BuildContext context) {
    AddControllerDialog.show(
      context,
      onControllerAdded: () {
        // Refresh the viewmodel when a controller is added
        if (context.mounted) {
          context.read<ConfigurationControlViewmodel>().refresh();
        }
      },
    );
  }
}
