import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/volume_control_buttons.dart';
import 'package:fusion_launcher/features/control_dashboard/view_models/zone_control_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigZoneControlHeader extends StatefulWidget {
  const ConfigZoneControlHeader({
    super.key,
    required this.zone,
  });

  final Zone zone;

  @override
  State<ConfigZoneControlHeader> createState() => _ConfigZoneControlHeaderState();
}

class _ConfigZoneControlHeaderState extends State<ConfigZoneControlHeader> {
  late final TextEditingController volumeController;

  @override
  void initState() {
    volumeController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    volumeController.dispose();
    super.dispose();
  }

  /// Keep the text field in sync with cubit state without losing cursor focus.
  void _syncVolumeText(double gain) {
    final double percentageGain = context.read<ZoneControlViewModel>().dbfsToPercentage(gain);
    final String formatted = percentageGain.toStringAsFixed(1);

    if (volumeController.text != formatted) {
      volumeController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZoneControlViewModel, ZoneControlState>(
      builder: (BuildContext context, ZoneControlState zoneState) {
        // Keep text field in sync with cubit.
        _syncVolumeText(zoneState.gain);

        final ZoneControlViewModel vm = context.read<ZoneControlViewModel>();

        return Container(
          height: 32,
          color: context.colorScheme.elevation2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

              if (vm.subZones.isEmpty) ...<Widget>[
                VolumeControlButtons(
                  volumeController: volumeController,
                  onVolumeChanged: (double newVolume) {
                    vm.setGain(newVolume);
                  },
                  onIncrement: () {
                    vm.incrementGain();
                  },
                  onDecrement: () {
                    vm.decrementGain();
                  },
                ),

                IconButton(
                  onPressed: () {
                    vm.toggleMute();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    zoneState.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                    size: 16,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ],

              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: FusionImageAuto(
                  path: AssetIcons.controllerSettings,
                  height: 14,
                  width: 16,
                  color: context.colorScheme.iconWhite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
