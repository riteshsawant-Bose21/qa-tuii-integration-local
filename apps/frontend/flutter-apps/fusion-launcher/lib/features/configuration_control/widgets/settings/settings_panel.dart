import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/SettingsViewModel/settings_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/SettingsViewModel/settings_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/controller_settings_section.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/settings/virtual_control_section.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Main settings panel that composes the Virtual Control and Controller Settings sections.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.settingsTab),
      child: BlocBuilder<SettingsViewModel, SettingsState>(
        builder: (BuildContext context, SettingsState state) {
          if (state is! SettingsLoaded) {
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
                      child: VirtualControlSection(controllerId: state.controllerId),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Controller Settings section — hidden for Virtual Control Pal Pro / LT
                  if (!state.isVirtual)
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
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: child,
    );
  }
}
