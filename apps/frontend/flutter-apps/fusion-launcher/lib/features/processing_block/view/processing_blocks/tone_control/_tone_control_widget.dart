import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/disabled_widget_wrapper.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_textfield.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ToneControlWidget extends StatelessWidget {
  final String title;
  final bool leftRadius;
  final bool isBypassed;
  final bool isDisabled;
  final void Function(bool) onBypassChanged;
  final num value;
  final void Function(num) onChanged;
  final String? semanticId;
  const ToneControlWidget({
    super.key,
    this.leftRadius = false,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isBypassed,
    required this.onBypassChanged,
    required this.isDisabled,
    this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.horizontal(
          left:
              leftRadius ? Radius.circular(context.mediumRadius) : Radius.zero,
        ),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: DisabledWidgetWrapper(
              isDisabled: isDisabled,
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.colorScheme.elevation3,
                          width: 1,
                        ),
                      ),
                    ),
                    child: FusionAppText(
                      text: title,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: VerticalSlider(
                        semanticId: 'tone_slider$semanticId',
                        value: value.toDouble(),
                        min: -15,
                        max: 15,
                        intervalGap: 15,
                        onChanged: (num sliderValue) {
                          onChanged(sliderValue);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.colorScheme.strokeLight,
                        ),
                        top: BorderSide(color: context.colorScheme.strokeLight),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /// threshold input
                        SizedBox(
                          width: 80,
                          // height: 25,
                          child: PBNumberTextField(
                            semanticId: 'tone_threshold$semanticId',
                            // value: context.watch<LimiterController>().currentThreshold ?? 0,
                            value: value,
                            onChanged: (num value) {
                              onChanged(value);
                              // context.read<LimiterController>().updateThreshold(value);
                            },
                            min: 1,
                            max: 96000,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FusionAppText(
                          text: "db",
                          capitalize: false,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // by pass text with bypass toggle
                FusionAppText(
                  text: "Bypass",
                  style: context.textTheme.bodySmall,
                ),
                FusionSwitch(
                  semanticId: 'tone_bypass$semanticId',
                  inactiveTrackColor: context.colorScheme.elevation1,
                  value: isBypassed,
                  onChanged: (bool value) {
                    onBypassChanged(value);
                  },
                  height: 30,
                  width: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
