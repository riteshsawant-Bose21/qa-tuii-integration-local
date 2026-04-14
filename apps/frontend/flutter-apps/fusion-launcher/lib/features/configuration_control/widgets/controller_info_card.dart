import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Card widget displaying the selected controller's name and location
class ControllerInfoCard extends StatelessWidget {
  const ControllerInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      buildWhen: (ConfigurationControlState previous, ConfigurationControlState current) {
        return previous.selectedControllerId != current.selectedControllerId;
      },
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        final FusionController? controller = state.selectedController;
        if (controller == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colorScheme.elevation2,
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              /// Controller icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings_remote,
                  color: context.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              /// Controller info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// Controller name
                    FusionAppText(
                      text: controller.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    /// Controller location
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: context.colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        FusionAppText(
                          text: _getControllerLocation(controller),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// Controller type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isProController(controller) ? context.colorScheme.primary.withValues(alpha: 0.15) : context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FusionAppText(
                  text: _getControllerTypeLabel(controller),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isProController(controller) ? context.colorScheme.primary : context.colorScheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check if the controller is a Pro type
  bool _isProController(FusionController controller) {
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  /// Get location string for the controller
  String _getControllerLocation(FusionController controller) {
    // Check if location is assigned
    final bool hasListeningArea = controller.locationEntity.listeningAreaId != null && controller.locationEntity.listeningAreaId!.isNotEmpty;
    final bool hasFloor = controller.locationEntity.floorId != null && controller.locationEntity.floorId!.isNotEmpty;

    if (hasListeningArea || hasFloor) {
      return 'Location assigned';
    }
    return 'No location assigned';
  }

  /// Get display label for controller type
  String _getControllerTypeLabel(FusionController controller) {
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();

    if (sku.contains('virtual') || name.contains('virtual')) {
      if (sku.contains('pro') || name.contains('pro')) {
        return 'Virtual Pro';
      }
      return 'Virtual LT';
    }

    if (sku.contains('pro') || name.contains('pro')) {
      return 'LT Pro';
    }

    return 'LT';
  }
}
