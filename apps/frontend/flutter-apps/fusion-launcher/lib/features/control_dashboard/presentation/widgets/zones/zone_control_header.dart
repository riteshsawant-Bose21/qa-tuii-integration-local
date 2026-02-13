import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/volume_control_buttons.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ZoneControlHeader extends StatelessWidget {
  const ZoneControlHeader({
    super.key,
    required this.zone,
  });

  final Zone zone;

  bool get shouldShowVolumeControl {
    //check if it has subzones, if it does not have subzones show volume control
    return serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id).isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: ShapeDecoration(
        color: zone.color.withAlpha((0.5 * 255).toInt()),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(8.0),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: zone.name,
              style: context.textTheme.labelMedium,
            ),
          ),

          if (shouldShowVolumeControl) ...<Widget>[
            VolumeControlButtons(
              onVolumeChanged: (double newVolume) {
                // Handle volume change logic here
              },
              onIncrement: () {
                // Handle increment logic here
              },
              onDecrement: () {
                // Handle decrement logic here
              },
            ),

            // Fix 1: Volume Icon
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero, // Removes internal padding
              constraints: const BoxConstraints(), // Removes 48px limit
              icon: Icon(
                Icons.volume_up_outlined,
                size: 16,
                color: context.colorScheme.iconWhite,
              ),
            ),
          ],
          // Fix 2: Settings Icon
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: FusionImage.asset(
              AssetIcons.controllerSettings,
              height: 14,
              width: 16,
              assetColor: context.colorScheme.iconWhite,
            ),
          ),
        ],
      ),
    );
  }
}
