import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Card widget displaying a single controller with its location
class ControllerCard extends StatelessWidget {
  final FusionController controller;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ControllerCard({
    super.key,
    required this.controller,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ConfigurationControlViewmodel viewModel = context.read<ConfigurationControlViewmodel>();
    final String locationName = viewModel.getControllerLocation(controller);
    final Zone? zone = viewModel.getZoneForController(controller);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.elevation3 : context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? context.colorScheme.strokeDark : context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            /// Controller name and menu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: controller.name,
                    style: Theme.of(context).textTheme.l1SemiBold,
                    maxLine: 1,
                  ),
                  const SizedBox(height: 8),

                  /// Location display
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: FusionAppText(
                          text: controller.sku,
                          style: Theme.of(context).textTheme.l1Regular,
                          maxLine: 1,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colorScheme.textBody,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      _buildLocationDisplay(context, locationName, zone),
                    ],
                  ),
                ],
              ),
            ),
            FusionKebabPopup(
              semanticId: 'controller_card_kebab_menu',
              onEdit: () => onEdit?.call(),
              onDelete: () => onDelete?.call(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay(BuildContext context, String locationName, Zone? zone) {
    final bool hasLocation = locationName != '--';

    return Row(
      children: <Widget>[
        if (zone != null) ...<Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: zone.color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.colorScheme.zone1Stroke, width: 1),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (hasLocation) ...<Widget>[
          Icon(
            Icons.location_on_outlined,
            size: 12,
            color: context.colorScheme.textSecondary,
          ),
          const SizedBox(width: 4),
        ],
        FusionAppText(
          text: locationName,
          style: Theme.of(context).textTheme.l1Regular,
          maxLine: 1,
        ),
      ],
    );
  }
}
