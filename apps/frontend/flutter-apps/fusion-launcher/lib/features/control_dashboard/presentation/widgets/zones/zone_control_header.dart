import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/volume_control_buttons.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ZoneControlHeader extends StatefulWidget {
  const ZoneControlHeader({
    super.key,
    required this.zone,
  });

  final Zone zone;

  @override
  State<ZoneControlHeader> createState() => _ZoneControlHeaderState();
}

class _ZoneControlHeaderState extends State<ZoneControlHeader> {
  bool get shouldShowVolumeControl {
    //check if it has subzones, if it does not have subzones show volume control
    return serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: widget.zone.id).isEmpty;
  }

  late final TextEditingController volumeController;

  @override
  void initState() {
    volumeController = TextEditingController(text: "10.0");
    super.initState();
  }

  @override
  void dispose() {
    volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: ShapeDecoration(
        color: widget.zone.color.withAlpha((0.5 * 255).toInt()),
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
              text: widget.zone.name,
              style: context.textTheme.labelMedium,
            ),
          ),

          if (shouldShowVolumeControl) ...<Widget>[
            VolumeControlButtons(
              volumeController: volumeController,
              onVolumeChanged: (double newVolume) {
                if (newVolume < -60) {
                  newVolume = -60.0;
                } else if (newVolume > 12) {
                  newVolume = 12.0;
                }
                volumeController.text = newVolume.toStringAsFixed(1);
              },
              onIncrement: () {
                double currentVolume = double.tryParse(volumeController.text) ?? 0.0;

                currentVolume += 1.0;
                if (currentVolume > 12.0) {
                  currentVolume = 12.0;
                }
                volumeController.text = currentVolume.toStringAsFixed(1);
              },
              onDecrement: () {
                double currentVolume = double.tryParse(volumeController.text) ?? 0.0;

                currentVolume -= 1.0;
                if (currentVolume < -60.0) {
                  currentVolume = -60.0;
                }

                volumeController.text = currentVolume.toStringAsFixed(1);
              },
            ),

            // Fix 1: Volume Icon
            IconButton(
              onPressed: () {
                serviceLocator<ProjectViewModel>().muteZone(
                  zoneId: widget.zone.id,
                  isMuted: !widget.zone.muted,
                );
              },
              padding: EdgeInsets.zero, // Removes internal padding
              constraints: const BoxConstraints(), // Removes 48px limit
              icon: Icon(
                widget.zone.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
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
