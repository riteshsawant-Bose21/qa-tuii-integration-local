import 'package:flutter/material.dart';

import 'package:fusion_launcher/features/add_source_popup/view_model/add_source_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/algorithm_data_viewmodel.dart';
import '../../widgets/pb_meter.dart';
import '../../widgets/pb_textfield.dart';
import '../widgets/block_header.dart';
import '../widgets/disabled_widget_wrapper.dart';

part '_limiter_controller.dart';

class LimiterBlock extends StatelessWidget {
  const LimiterBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final AlgorithmDataViewmodel watch = context.watch<AlgorithmDataViewmodel>();
    return ProxyProvider<AlgorithmDataViewmodel, LimiterController>(
      key: ValueKey<String>(watch.processingBlock.id),
      create: (BuildContext context) {
        return LimiterController(watch);
      },
      update: (BuildContext context, AlgorithmDataViewmodel valueHandler, LimiterController? previous) => LimiterController(valueHandler),
      child: Builder(
        builder: (BuildContext context) {
          return Stack(
            children: <Widget>[
              /// Header with block name and actions
              ...getBlockHeader(
                context,
                context.watch<AlgorithmDataViewmodel>().processingBlock,
                actions: <Widget>[
                  const FusionAppText(text: "BYPASS"),
                  const SizedBox(width: 10),
                  FusionSwitch(
                    inactiveTrackColor: context.colorScheme.elevation1,
                    value: context.watch<LimiterController>().isGloballyBypassed,
                    onChanged: (bool value) {
                      context.read<LimiterController>().bypassGlobally(value);
                    },
                    height: 30,
                    width: 50,
                  ),
                ],
              ),

              /// Main content area
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: DisabledWidgetWrapper(
                  isDisabled: context.watch<LimiterController>().isGloballyBypassed,
                  child: Row(
                    spacing: 3,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Limiter setup
                      Container(
                        width: 239,
                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation2,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(context.mediumRadius),
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
                                  bottom: BorderSide(color: context.colorScheme.strokeLight),
                                ),
                              ),
                              child: FusionAppText(text: "Limiter setup", style: context.textTheme.bodyMedium),
                            ),

                            /// V Peak section
                            /// With threshold input and link to gain reduction meter
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: context.colorScheme.strokeLight),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Column(
                                children: <Widget>[
                                  Align(alignment: Alignment.topLeft, child: FusionAppText(text: "V PEAK", style: context.textTheme.bodyMedium)),
                                  const SizedBox(height: 18),

                                  /// V Peak input
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(text: "THRESHOLD", style: context.textTheme.bodySmall),
                                      const SizedBox(width: 24),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          /// threshold input
                                          FusionContainer(
                                            alignment: Alignment.center,
                                            width: 58,
                                            color: context.colorScheme.elevation2,
                                            child: PBNumberTextField(
                                              value: context.watch<LimiterController>().currentThreshold ?? 0,
                                              onChanged: (num value) {
                                                context.read<LimiterController>().updateThreshold(value);
                                              },
                                              min: 1,
                                              max: 96000,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FusionAppText(text: "dbfs", capitalize: false, style: context.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// V RMS section
                            /// With threshold, attack and release inputs
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: context.colorScheme.strokeLight),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Column(
                                spacing: 14,
                                children: <Widget>[
                                  Align(alignment: Alignment.topLeft, child: FusionAppText(text: "V RMS", style: context.textTheme.bodyMedium)),

                                  /// V RMS input
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(text: "THRESHOLD", style: context.textTheme.bodySmall),
                                      const SizedBox(width: 24),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          /// threshold input
                                          FusionContainer(
                                            alignment: Alignment.center,
                                            width: 58,
                                            color: context.colorScheme.elevation2,
                                            child: PBNumberTextField(
                                              value: context.watch<LimiterController>().currentRMSThreshold ?? 0,
                                              onChanged: (num value) {
                                                context.read<LimiterController>().updateRMSThreshold(value);
                                              },
                                              min: 1,
                                              max: 96000,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FusionAppText(text: "dBFS", capitalize: false, style: context.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    height: 1,
                                    color: context.colorScheme.strokeLight,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                    children: <Widget>[
                                      FusionAppText(text: "ATTACK", style: context.textTheme.bodySmall),
                                      const SizedBox(width: 24),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          /// threshold input
                                          FusionContainer(
                                            alignment: Alignment.center,
                                            width: 58,
                                            color: context.colorScheme.elevation2,
                                            child: PBNumberTextField(
                                              value: context.watch<LimiterController>().currentRMSAttackTime ?? 0,
                                              onChanged: (num value) {
                                                context.read<LimiterController>().updateRMSAttackTime(value);
                                              },
                                              min: 1,
                                              max: 96000,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FusionAppText(text: "msec", capitalize: false, style: context.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    height: 1,
                                    color: context.colorScheme.strokeLight,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FusionAppText(text: "RELEASE", style: context.textTheme.bodySmall),
                                      const SizedBox(width: 24),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          /// threshold input
                                          FusionContainer(
                                            alignment: Alignment.center,
                                            width: 58,
                                            color: context.colorScheme.elevation2,
                                            child: PBNumberTextField(
                                              value: context.watch<LimiterController>().currentRMSReleaseTime ?? 0,
                                              onChanged: (num value) {
                                                context.read<LimiterController>().updateRMSReleaseTime(value);
                                              },
                                              min: 1,
                                              max: 96000,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FusionAppText(text: "msec", capitalize: false, style: context.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Gain reduction meter
                      Container(
                        width: 267,
                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation2,
                        ),
                        child: Column(
                          children: <Widget>[
                            /// output meter
                            Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12.0),

                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: context.colorScheme.strokeLight),
                                ),
                              ),
                              child: FusionAppText(text: "GAIN REDUCTION (dB)", style: context.textTheme.bodyMedium),
                            ),

                            /// input meter
                            Flexible(
                              child: Row(
                                children: <Widget>[
                                  /// Peac widget
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: const SimpleVerticalMeter(
                                              value: -10,
                                              min: -60,
                                              max: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.elevation2,
                                            border: Border(
                                              top: BorderSide(color: context.colorScheme.strokeLight),
                                            ),
                                          ),
                                          child: FusionAppText(
                                            text: "PEAK",
                                            style: context.textTheme.labelMedium?.copyWith(
                                              color: context.colorScheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// RMS widget
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            decoration: BoxDecoration(
                                              color: context.colorScheme.elevation2,
                                              border: Border(
                                                right: BorderSide(color: context.colorScheme.strokeLight),
                                                left: BorderSide(color: context.colorScheme.strokeLight),
                                              ),
                                            ),
                                            child: const SimpleVerticalMeter(
                                              value: -10,
                                              min: -60,
                                              max: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.elevation2,
                                            border: Border(
                                              top: BorderSide(color: context.colorScheme.strokeLight),
                                              right: BorderSide(color: context.colorScheme.strokeLight),
                                              left: BorderSide(color: context.colorScheme.strokeLight),
                                            ),
                                          ),
                                          child: FusionAppText(
                                            text: "RMS",
                                            style: context.textTheme.labelMedium?.copyWith(
                                              color: context.colorScheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Total widget
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: const SimpleVerticalMeter(
                                              value: -10,
                                              min: -60,
                                              max: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.elevation2,
                                            border: Border(
                                              top: BorderSide(color: context.colorScheme.strokeLight),
                                            ),
                                          ),
                                          child: FusionAppText(
                                            text: "TOTAL",
                                            style: context.textTheme.labelMedium?.copyWith(
                                              color: context.colorScheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// output meter
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
                                  bottom: BorderSide(color: context.colorScheme.strokeLight),
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
