import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class OutMeter extends StatelessWidget {
  const OutMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(context.mediumRadius),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.strokeLight,
                  width: 1,
                ),
              ),
            ),
            child: const FusionAppText(
              text: "OUTPUT",
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: VerticalMeter(
                semanticId: 'out_meter_vertical_meter',
                value: -60,
                min: -60,
                max: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
