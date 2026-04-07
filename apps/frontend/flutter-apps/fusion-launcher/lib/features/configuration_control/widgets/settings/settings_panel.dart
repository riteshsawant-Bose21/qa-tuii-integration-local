import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/controller_settings_section.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/virtual_control_section.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Main settings panel that composes the Virtual Control and Controller Settings sections
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          color: context.colorScheme.elevation1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),

                /// Virtual Control section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCard(
                    context,
                    child: VirtualControlSection(
                      state: state,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Controller Settings section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCard(
                    context,
                    child: const ControllerSettingsSection(),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Builds a URL (or identifier) for the QR code based on the selected controller.
  /// Falls back to a generic URL when no controller is selected.
  String? _buildControllerUrl(ConfigControlLoaded state) {
    final FusionController? controller = state.selectedController;
    if (controller == null) return null;
    // Generate a simple URL; can be replaced with real endpoint once available.
    return 'fusion://virtual-controller/${controller.id}';
  }
}
