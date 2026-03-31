import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_sidebar.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/empty_controllers_state.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/control_content_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main page for Configuration Control feature
class ConfigurationControlPage extends StatelessWidget {
  const ConfigurationControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return BlocProvider<ConfigurationControlViewmodel>(
      create:
          (BuildContext context) => ConfigurationControlViewmodel(
            projectViewModel: projectViewModel,
          ),
      child: const _ConfigurationControlBody(),
    );
  }
}

class _ConfigurationControlBody extends StatelessWidget {
  const _ConfigurationControlBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        return Scaffold(
          backgroundColor: context.colorScheme.primaryBlack,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ConfigurationControlState state) {
    return switch (state) {
      ConfigControlInitial() => _buildLoadingState(context),
      ConfigControlLoading() => _buildLoadingState(context),
      ConfigControlEmpty() => const EmptyControllersState(),
      ConfigControlLoaded() => _buildLoadedState(context, state),
      ConfigControlError() => _buildErrorState(context, state),
    };
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: context.colorScheme.primary,
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, ConfigControlLoaded state) {
    return Row(
      children: <Widget>[
        /// Controllers sidebar
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.17,
          child: const ControllersSidebar(),
        ),

        /// Main content panel
        const Expanded(
          child: ControlContentPanel(),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ConfigControlError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.colorScheme.error,
          ),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'Error loading configuration control',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: state.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
