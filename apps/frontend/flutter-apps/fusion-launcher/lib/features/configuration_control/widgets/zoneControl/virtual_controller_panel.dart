import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Panel displaying the virtual controller emulator
class VirtualControllerPanel extends StatelessWidget {
  const VirtualControllerPanel({super.key});

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colorScheme.elevation2,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Header
              _buildHeader(context),

              /// Content
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.elevation2,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          FusionAppText(
            text: 'VIRTUAL CONTROLLER',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConfigControlLoaded state) {
    final Zone? selectedZone =
        state.selectedZoneId != null
            ? state.zones.firstWhere(
              (Zone z) => z.id == state.selectedZoneId,
              orElse: () => state.zones.isNotEmpty ? state.zones.first : Zone(name: 'No Zone'),
            )
            : (state.zones.isNotEmpty ? state.zones.first : null);

    if (selectedZone == null) {
      return Center(
        child: FusionAppText(
          text: 'No zone selected',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Zone title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: selectedZone.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FusionAppText(
                        text: selectedZone.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              /// Emulator placeholder
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colorScheme.strokeDark,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.settings_remote,
                      size: 48,
                      color: context.colorScheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    FusionAppText(
                      text: 'Emulator goes here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FusionAppText(
                      text: 'Virtual controller design will be implemented here',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.textPlaceholder,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
