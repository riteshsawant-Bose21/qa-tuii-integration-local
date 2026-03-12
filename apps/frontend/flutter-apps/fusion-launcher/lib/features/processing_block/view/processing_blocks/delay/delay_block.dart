import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_out_meter.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../widgets/pb_dropdown.dart';
import '../../widgets/pb_textfield.dart';
import '../widgets/pb_block_layout.dart';

part '_delay_controller.dart';

class DelayBlock extends StatelessWidget {
  const DelayBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();

    final String targetBlockId = watch.processingBlock.id;
    return ProxyProvider<AlgorithmDataViewmodel, DelayController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return DelayController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, DelayController? previous) => DelayController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          final DelayController controller = context.watch<DelayController>();
          return PBBlockLayout(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
            onBypassChanged: context.read<DelayController>().bypassGlobally,
            bypassed: controller.isGloballyBypassed,
            body: Row(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(context.mediumRadius),
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      /// Units dropdown
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FusionAppText(text: "Units", style: context.textTheme.bodySmall),
                          const SizedBox(width: 44),
                          SizedBox(
                            width: 200,
                            child: PBDropdown<_UnitsType>(
                              hintText: "Units",
                              onChanged: (_UnitsType value) {
                                context.read<DelayController>().updateUnits(value.value);
                              },
                              items: _UnitsType.values,
                              value: context.watch<DelayController>().currentUnits?.value,

                              itemBuilder: (BuildContext context, _UnitsType option) {
                                return Text(
                                  option.label,
                                  style: context.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      /// Delay time input
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 80,
                            child: PBNumberTextField(
                              value: context.watch<DelayController>().currentDelay ?? 0,
                              onChanged: (num value) {
                                context.read<DelayController>().updateDelay(value);
                              },
                              min: 1,
                              max: 96000,
                            ),
                          ),
                          const SizedBox(width: 4),
                          FusionAppText(text: context.watch<DelayController>().currentUnits?.shortLabel ?? "", style: context.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
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
                            bottom: BorderSide(color: context.colorScheme.elevation5),
                          ),
                        ),
                        child: FusionAppText(text: "OUTPUT", style: context.textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: PbOutMeter(
                            blockId: targetBlockId,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
