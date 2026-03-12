import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_out_meter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class OutMeter extends StatelessWidget {
  final String blockId;

  const OutMeter({super.key, required this.blockId});

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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: PbOutMeter(
                blockId: blockId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
