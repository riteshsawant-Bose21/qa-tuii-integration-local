import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/pb_section.dart';
import 'package:fusion_launcher/features/processing_block/viewmodel/algorithm_data_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../widgets/pb_meter.dart';
import '../widgets/pb_block_layout.dart';

part '_gate_controller.dart';

class GateBlock extends StatelessWidget {
  const GateBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    return ProxyProvider<AlgorithmDataViewmodel, GateController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return GateController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, GateController? previous) => GateController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          return PBBlockLayout(
            pb: context.watch<AlgorithmDataViewmodel>().processingBlock,
            onBypassChanged: context.read<GateController>().bypassGlobally,
            bypassed: context.watch<GateController>().isGloballyBypassed,
            body: Row(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const PBSection(
                  type: PBSectionType.left,
                  child: Column(
                    children: <Widget>[
                      /// Units dropdown
                    ],
                  ),
                ),
                PBSection(
                  type: PBSectionType.right,
                  child: SizedBox(
                    width: 100,
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
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: VerticalMeter(
                              value: -60,
                              min: -60,
                              max: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          // return Stack(
          //   children: <Widget>[
          //     /// Header with block name and actions
          //     ...getBlockHeader(
          //       context,
          //       context.watch<AlgorithmDataViewmodel>().processingBlock,
          //       actions: <Widget>[
          //         const FusionAppText(text: "BYPASS"),
          //         const SizedBox(width: 10),
          //         FusionSwitch(
          //           inactiveTrackColor: context.colorScheme.elevation1,
          //           value: context.watch<GateController>().isGloballyBypassed,
          //           onChanged: (bool value) {
          //             context.read<GateController>().bypassGlobally(value);
          //           },
          //           height: 30,
          //           width: 50,
          //         ),
          //       ],
          //     ),

          //     /// Main content area
          //     Padding(
          //       padding: const EdgeInsets.only(top: 50),
          //       child: DisabledWidgetWrapper(
          //         isDisabled: context.watch<GateController>().isGloballyBypassed,
          //         child: Row(
          //           spacing: 3,
          //           mainAxisSize: MainAxisSize.min,
          //           children: <Widget>[
          //             Container(
          //               decoration: BoxDecoration(
          //                 color: context.colorScheme.elevation2,
          //                 borderRadius: BorderRadius.horizontal(
          //                   left: Radius.circular(context.mediumRadius),
          //                 ),
          //               ),
          //               padding: const EdgeInsets.all(20.0),
          //               child: Column(
          //                 children: <Widget>[
          //                   /// Units dropdown
          //                   Row(
          //                     mainAxisSize: MainAxisSize.min,
          //                     children: <Widget>[
          //                       FusionAppText(text: "Units", style: context.textTheme.bodySmall),
          //                       const SizedBox(width: 44),
          //                       SizedBox(
          //                         width: 200,
          //                         child: PBDropdown<_UnitsType>(
          //                           hintText: "Units",
          //                           onChanged: (_UnitsType value) {
          //                             context.read<GateController>().updateUnits(value.value);
          //                           },
          //                           items: _UnitsType.values,
          //                           value: context.watch<GateController>().currentUnits?.value,

          //                           itemBuilder: (BuildContext context, _UnitsType option) {
          //                             return Text(
          //                               option.label,
          //                               style: context.textTheme.bodySmall,
          //                             );
          //                           },
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                   const SizedBox(height: 24),

          //                   /// Delay time input
          //                   Row(
          //                     mainAxisSize: MainAxisSize.min,
          //                     children: <Widget>[
          //                       FusionContainer(
          //                         alignment: Alignment.center,
          //                         width: 80,
          //                         color: context.colorScheme.elevation2,
          //                         child: PBNumberTextField(
          //                           value: context.watch<GateController>().currentDelay ?? 0,
          //                           onChanged: (num value) {
          //                             context.read<GateController>().updateDelay(value);
          //                           },
          //                           min: 1,
          //                           max: 96000,
          //                         ),
          //                       ),
          //                       const SizedBox(width: 4),
          //                       FusionAppText(text: context.watch<GateController>().currentUnits?.shortLabel ?? "", style: context.textTheme.bodySmall),
          //                     ],
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             Container(
          //               width: 100,
          //               decoration: BoxDecoration(
          //                 color: context.colorScheme.elevation2,
          //                 borderRadius: BorderRadius.horizontal(
          //                   right: Radius.circular(context.mediumRadius),
          //                 ),
          //               ),
          //               child: Column(
          //                 children: <Widget>[
          //                   Container(
          //                     width: double.infinity,
          //                     alignment: Alignment.center,
          //                     padding: const EdgeInsets.symmetric(vertical: 12.0),

          //                     decoration: BoxDecoration(
          //                       border: Border(
          //                         bottom: BorderSide(color: context.colorScheme.elevation5),
          //                       ),
          //                     ),
          //                     child: FusionAppText(text: "OUTPUT", style: context.textTheme.bodyMedium),
          //                   ),
          //                   const Expanded(
          //                     child: Padding(
          //                       padding: EdgeInsets.all(12.0),
          //                       child: VerticalMeter(
          //                         value: -60,
          //                         min: -60,
          //                         max: 0,
          //                       ),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // );
        },
      ),
    );
  }
}
