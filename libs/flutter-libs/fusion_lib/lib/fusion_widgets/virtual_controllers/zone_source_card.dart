import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/controller_meter_painter.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/volume_meter_painter.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/widgets/horizontal_slider.dart';

class ZoneSourceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double volume;
  final bool muted;
  final VoidCallback? onTap;
  final ValueChanged<double>? onVolumeChanged;

  const ZoneSourceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.volume,
    this.muted = false,
    this.onTap,
    this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.elevation2,
        ),
      ),
      child: Column(
        children: [
          /// Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: context.colorScheme.iconDefault,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.b2Medium.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: FusionContainer(
                    raised:true,
                    borderRadius: 8,
                    child: Container(
                        margin: EdgeInsets.all(4),
                        child: Icon(
                            Icons.chevron_right,
                            color: context.colorScheme.iconWhite
                        )
                    )
                ),
              )
            ],
          ),

          const SizedBox(height: 16),

          /// Volume Row
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colorScheme.elevation2),
              borderRadius: BorderRadius.all(Radius.circular(8))
            ),
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  muted ? Icons.volume_off : Icons.volume_up,
                  color: muted ? context.colorScheme.iconDefault : context.colorScheme.primary,
                ),

                const SizedBox(width: 8),

                /// Slider
                Expanded(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Stack(
                          alignment: Alignment.center,
                          children: [
                          FusionContainer(
                              raised: false,
                              borderRadius: 50,
                              child: Container(
                                width: double.infinity,
                                height: 16,
                              ),
                            ),
                            Container(
                              height: 15,
                               child: HorizontalAudioSlider( key: key,
                                  isMuted: muted,
                                  initialValue: volume,

                                  onChanged: (volume) {
                                    //
                                    // context
                                    //     .read<
                                    //     VirtualControllerViewModel>()
                                    //     .updateVolume(
                                    //     selectSubZone!,
                                    //     volume,
                                    //     sendToService: !widget
                                    //         .isDesignMode);


                                  },)
                            )

                    ]
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// Volume Number
                SizedBox(
                  child: Text(
                    "${volume.toInt()}",
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.b3Medium.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}