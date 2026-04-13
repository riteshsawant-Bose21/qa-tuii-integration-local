import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/MessageViewModel/message_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/ScheduleViewModel/schedule_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/SettingsViewModel/settings_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/snapshotViewModel/snapshot_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/zoneControlViewmodel/zone_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controllers_sidebar.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/empty_controllers_state.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/control_content_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main page for Configuration Control feature.
///
/// Owns [ConfigurationControlViewmodel] (tab/controller management) and
/// provides dedicated ViewModels for each feature tab.
/// A [BlocConsumer] triggers sub-ViewModel data loads whenever the
/// selected controller changes.
class ConfigurationControlPage extends StatelessWidget {
  const ConfigurationControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ConfigurationControlViewmodel>(
          create: (_) => ConfigurationControlViewmodel(),
        ),
        BlocProvider<ZoneControlViewModel>(
          create: (_) => ZoneControlViewModel(),
        ),
        BlocProvider<SnapshotViewModel>(
          create: (_) => SnapshotViewModel(),
        ),
        BlocProvider<MessageViewModel>(
          create: (_) => MessageViewModel(),
        ),
        BlocProvider<ScheduleViewModel>(
          create: (_) => ScheduleViewModel(),
        ),
        BlocProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),
      ],
      child: const _ConfigurationControlBody(),
    );
  }
}

class _ConfigurationControlBody extends StatefulWidget {
  const _ConfigurationControlBody();

  @override
  State<_ConfigurationControlBody> createState() => _ConfigurationControlBodyState();
}

class _ConfigurationControlBodyState extends State<_ConfigurationControlBody> {
  String? _lastLoadedControllerId;

  void _loadSubViewModels(BuildContext context, ConfigControlLoaded state) {
    if (state.selectedControllerId == null) return;
    if (state.selectedControllerId == _lastLoadedControllerId) return;

    _lastLoadedControllerId = state.selectedControllerId;
    final String controllerId = state.selectedControllerId!;
    final bool isPro = state.isProController;

    // Always reload zone and settings — needed for both LT and Pro controllers.
    context.read<ZoneControlViewModel>().loadData(controllerId, isProController: isPro);
    context.read<SettingsViewModel>().loadData(controllerId);

    // Pro-only tabs.
    if (isPro) {
      context.read<SnapshotViewModel>().loadData(controllerId);
      context.read<MessageViewModel>().loadData(controllerId);
      context.read<ScheduleViewModel>().loadData(controllerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        // Trigger sub-viewmodel loads after the frame is built
        if (state is ConfigControlLoaded && state.selectedControllerId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadSubViewModels(context, state);
          });
        }

        return Scaffold(
          backgroundColor: context.colorScheme.elevation1,
          body: switch (state) {
            ConfigControlInitial() => _buildLoadingState(context),
            ConfigControlLoading() => _buildLoadingState(context),
            ConfigControlEmpty() => const EmptyControllersState(),
            ConfigControlLoaded() => _buildLoadedState(context, state),
            ConfigControlError() => _buildErrorState(context, state),
          },
        );
      },
    );
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
