import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/features/control_dashboard/presentation/widgets/zones/volume_control_buttons.dart';
import 'package:fusion_launcher/features/control_dashboard/view_models/zone_control_view_model.dart';
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
    final String formatted = gain.toStringAsFixed(1);
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
      },
    );
  }
}
