import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_slider.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../processing_block/view/processing_blocks/widgets/disabled_widget_wrapper.dart';
import '../../../processing_block/view/widgets/pb_dropdown.dart';
import '../../../processing_block/view/widgets/pb_meter.dart';
import '../../widgets/neumorphic_gain_text_field.dart';
import '../models/models.dart';

class PrioritySettingsWidget extends StatefulWidget {
  final String zoneId;

  final bool Function(int index) isStateActive;
  final void Function(int index) onStateActiveChanged;

  final void Function(int index) onPTTControlTypeChanged;
  final void Function(int index) onThresholdControlTypeChanged;

  // is ptt selected
  final bool Function(int index) isPriorityControlTypePTT;
  final bool Function(int index) isPriorityControlTypeThreshold;
  final bool Function(int index) enableBehaviorSettingsFields;

  final double? Function(int index) getThresholdValue;
  final double? Function(int index) getDepth;
  final double? Function(int index) getAttack;
  final double? Function(int index) getHold;
  final double? Function(int index) getRelease;
  final double? Function(int index) getReductionValue;

  final AdditionalSettingPriorityBehavior? Function(int index) getPriorityBehavior;

  final void Function(int index, num value) onThresholdValueChanged;
  final void Function(int index, num value) onDepthValueChanged;
  final void Function(int index, num value) onAttackValueChanged;
  final void Function(int index, num value) onHoldValueChanged;
  final void Function(int index, num value) onReleaseValueChanged;

  final void Function(int index, AdditionalSettingPriorityBehavior value) onPriorityBehaviorChanged;

  const PrioritySettingsWidget({
    super.key,
    required this.zoneId,
    required this.isStateActive,
    required this.onStateActiveChanged,
    required this.onPTTControlTypeChanged,
    required this.onThresholdControlTypeChanged,
    required this.isPriorityControlTypePTT,
    required this.isPriorityControlTypeThreshold,
    required this.enableBehaviorSettingsFields,
    required this.getThresholdValue,
    required this.getDepth,
    required this.getAttack,
    required this.getHold,
    required this.getRelease,
    required this.getReductionValue,
    required this.getPriorityBehavior,
    required this.onThresholdValueChanged,
    required this.onDepthValueChanged,
    required this.onAttackValueChanged,
    required this.onHoldValueChanged,
    required this.onReleaseValueChanged,
    required this.onPriorityBehaviorChanged,
  });

  @override
  State<PrioritySettingsWidget> createState() => PrioritySettingsWidgetState();
}

class PrioritySettingsWidgetState extends State<PrioritySettingsWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late final List<Source> sources;

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneId);
  }

  @override
  Widget build(BuildContext context) {
    final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    final SizedBox child = SizedBox(
      width: 600,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: FusionAppText(
                    text: "PRIORITY",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),

                Divider(color: context.colorScheme.strokeLight, height: 0),

                Flexible(
                  child: Material(
                    color: Colors.transparent,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: 2,
                      separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
                      itemBuilder: (BuildContext context, int index) {
                        // String? selectedSourceId;
                        String? selectedSourceName;

                        final List<String> prioritySources = projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);

                        /// priority 1
                        if (index == 0) {
                          if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
                            final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[0]);
                            if (sourceData != null) {
                              selectedSourceName = sourceData.name;
                              // selectedSourceId = prioritySources[0];
                            }
                          }
                        } else {
                          /// priority 2
                          if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
                            final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[1]);
                            if (sourceData != null) {
                              selectedSourceName = sourceData.name;
                              // selectedSourceId = prioritySources[1];
                            }
                          }
                        }

                        final bool isStateActive = widget.isStateActive(index);

                        return SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_selection_widget_$index"),
                          child: SizedBox(
                            height: 600,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                //
                                // ========= HEADINGS ========
                                //
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: FusionAppText(
                                    text: "PRIORITY ${index + 1}",
                                    style: context.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Divider(color: context.colorScheme.strokeLight, height: 0), // // ========= CONTENT ======== //

                                Expanded(
                                  child: Builder(
                                    builder: (BuildContext context) {
                                      if (selectedSourceName == null) {
                                        return FusionAppText(
                                          text: "No source selected for priority ${index + 1}.",
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            color: const Color(0xFF888888),
                                          ),
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Row(
                                                    spacing: 4,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "PTT/CONTROL",
                                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      SemanticHelper.button(
                                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_active_button_$index"),
                                                        child: FusionSwitch(
                                                          value: widget.isPriorityControlTypePTT(index),
                                                          width: 44,
                                                          height: 24,
                                                          onChanged: (bool value) => widget.onPTTControlTypeChanged(index),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Divider(color: context.colorScheme.strokeLight, height: 0),
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Row(
                                                    spacing: 4,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "THRESHOLD",
                                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      SemanticHelper.button(
                                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_active_button_$index"),
                                                        child: FusionSwitch(
                                                          value: widget.isPriorityControlTypeThreshold(index),
                                                          width: 44,
                                                          height: 24,
                                                          onChanged: (bool value) => widget.onThresholdControlTypeChanged(index),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(height: 10),
                                                Divider(color: context.colorScheme.strokeLight, height: 0),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: DisabledWidgetWrapper(
                                                    isDisabled: widget.isPriorityControlTypePTT(index),
                                                    child: VerticalSlider(
                                                      value: widget.getThresholdValue(index) ?? 0.0,
                                                      min: -60,
                                                      max: 12,
                                                      onChanged: (num value) => widget.onThresholdValueChanged(index, value),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Divider(color: context.colorScheme.strokeLight, height: 0),
                                                const SizedBox(height: 10),
                                                DisabledWidgetWrapper(
                                                  isDisabled: widget.isPriorityControlTypePTT(index),
                                                  child: NeumorphicGainTextField(
                                                    controllerValue: widget.getThresholdValue(index),
                                                    maxGain: 12,
                                                    minGain: -60,
                                                    onSubmitted: (double value) => widget.onThresholdValueChanged(index, value),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                FusionAppText(
                                                  text: "dBFS",
                                                  style: context.textTheme.labelSmall?.copyWith(
                                                    color: context.colorScheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),
                                          ),

                                          VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Center(
                                                    child: FusionAppText(
                                                      text: "STATE",
                                                      style: context.textTheme.labelMedium?.copyWith(
                                                        color: context.colorScheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  FusionNeumorphicButton(
                                                    height: 34,
                                                    width: double.infinity,
                                                    text: "Active",
                                                    color: isStateActive ? context.colorScheme.primaryColor : context.colorScheme.elevation2,
                                                    onTap: () => widget.onStateActiveChanged(index),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Divider(color: context.colorScheme.strokeLight, height: 0),
                                                  const SizedBox(height: 10),

                                                  Center(
                                                    child: FusionAppText(
                                                      text: "BEHAVIOR",
                                                      style: context.textTheme.labelMedium?.copyWith(
                                                        color: context.colorScheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),

                                                  PBDropdown<AdditionalSettingPriorityBehavior>(
                                                    hintText: "select",
                                                    value: widget.getPriorityBehavior(index)?.displayName,
                                                    items: AdditionalSettingPriorityBehavior.values,
                                                    itemBuilder: (BuildContext context, AdditionalSettingPriorityBehavior mode) {
                                                      return FusionAppText(
                                                        text: mode.displayName,
                                                        style: context.textTheme.bodySmall,
                                                      );
                                                    },
                                                    onChanged: (AdditionalSettingPriorityBehavior value) {
                                                      widget.onPriorityBehaviorChanged(index, value);
                                                    },
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    spacing: 5,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "DEPTH",
                                                          style: context.textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      NeumorphicGainTextField(
                                                        enabled: widget.enableBehaviorSettingsFields(index),
                                                        controllerValue: widget.getDepth(index),
                                                        maxGain: 12,
                                                        minGain: -60,
                                                        onSubmitted: (double value) => widget.onDepthValueChanged(index, value),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    spacing: 5,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "ATTACK",
                                                          style: context.textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      NeumorphicGainTextField(
                                                        enabled: widget.enableBehaviorSettingsFields(index),
                                                        controllerValue: widget.getAttack(index),
                                                        maxGain: 12,
                                                        minGain: -60,
                                                        onSubmitted: (double value) => widget.onAttackValueChanged(index, value),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    spacing: 5,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "HOLD",
                                                          style: context.textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      UnitNumberTextField(
                                                        enabled: widget.enableBehaviorSettingsFields(index),
                                                        min: 1,
                                                        max: null,
                                                        unit: "ms",
                                                        controllerValue: widget.getHold(index),
                                                        onSubmitted: (double value) => widget.onHoldValueChanged(index, value),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    spacing: 5,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: FusionAppText(
                                                          text: "RELEASE",
                                                          style: context.textTheme.labelMedium?.copyWith(
                                                            color: context.colorScheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      UnitNumberTextField(
                                                        enabled: widget.enableBehaviorSettingsFields(index),
                                                        min: 1,
                                                        max: null,
                                                        unit: "ms",
                                                        controllerValue: widget.getRelease(index),
                                                        onSubmitted: (double value) => widget.onReleaseValueChanged(index, value),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                          Expanded(
                                            child: Column(
                                              children: <Widget>[
                                                const Expanded(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(16.0),
                                                    child: SizedBox(
                                                      width: 100,
                                                      child: SimpleVerticalMeter(
                                                        value: -20,
                                                        min: -42,
                                                        max: 0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Divider(color: context.colorScheme.strokeLight, height: 0),
                                                const SizedBox(height: 10),
                                                FusionContainer(
                                                  width: 100,
                                                  height: 32,
                                                  alignment: Alignment.center,
                                                  borderRadius: 8,
                                                  color: context.colorScheme.elevation2,
                                                  child: FusionAppText(
                                                    text: "${widget.getReductionValue(index)}",
                                                    style: context.textTheme.labelMedium?.copyWith(
                                                      color: context.colorScheme.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                FusionAppText(
                                                  text: "dB",
                                                  style: context.textTheme.labelSmall?.copyWith(
                                                    color: context.colorScheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
        ],
      ),
    );

    // Otherwise, return the child directly
    return child;
  }
}
