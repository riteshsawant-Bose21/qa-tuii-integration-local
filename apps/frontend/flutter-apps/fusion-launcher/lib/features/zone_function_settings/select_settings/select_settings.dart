import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/common_reorderable_list_view.dart';
import 'package:fusion_launcher/features/zone_function_settings/widgets/priority_setting_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../widgets/zone_subzone_builder.dart';
import 'viewmodel/select_settings_vm.dart';

class SourceSelectAdditionalSettingsDialog extends StatefulWidget {
  final String zoneID;

  const SourceSelectAdditionalSettingsDialog({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceSelectAdditionalSettingsDialog(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceSelectAdditionalSettingsDialog> createState() => _SourceSelectAdditionalSettingsState();
}

class _SourceSelectAdditionalSettingsState extends State<SourceSelectAdditionalSettingsDialog> {
  late List<Source> sources;
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
  ZoneFunctions? zoneFunction;

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(
      zoneId: widget.zoneID,
    );
    zoneFunction = projectViewModel.getZoneFunctionForZone(
      zoneId: widget.zoneID,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (zoneFunction == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: Navigator.of(context).pop,
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  border: Border.all(color: context.colorScheme.strokeLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.loose,
                  children: <Widget>[
                    // TITLTE
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        child: FusionAppText(
                          text: "SOURCE SELECT - PRIORITY SETTINGS",
                          style: context.textTheme.titleSmall,
                          maxLine: 1,
                        ),
                      ),
                    ),

                    // CLOSE BUTTON
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: Navigator.of(context).pop,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                LucideIcons.x200,
                                color: context.colorScheme.iconDefault,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// --------------------------------------------------------------------------------
                    ///                             MAIN CONTENT
                    /// --------------------------------------------------------------------------------
                    BlocProvider<SourceSelectAdditionalSettingsViewmodel>(
                      create: (_) => SourceSelectAdditionalSettingsViewmodel()..init(zoneID: widget.zoneID),
                      child: BlocBuilder<SourceSelectAdditionalSettingsViewmodel, SourceSelectAdditionalSettingsVmState>(
                        builder: (
                          BuildContext context,
                          SourceSelectAdditionalSettingsVmState sourceSelectAdditionalSettingsVmState,
                        ) {
                          final SourceSelectAdditionalSettingsViewmodel vm = context.watch<SourceSelectAdditionalSettingsViewmodel>();

                          context.watch<ProjectViewModel>();

                          return Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: SemanticHelper.container(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.container,
                                "source_select_main_container",
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: context.colorScheme.strokeLight,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.elevation2,
                                        border: Border.all(
                                          color: context.colorScheme.strokeLight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          // LEFT COLUMN (Reorderable List)
                                          Flexible(
                                            flex: 2,
                                            child: Column(
                                              children: <Widget>[
                                                Container(
                                                  width: double.infinity,
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: FusionAppText(
                                                    text: "SOURCES",
                                                    style: Theme.of(context).textTheme.labelSmall,
                                                  ),
                                                ),
                                                Divider(
                                                  color: context.colorScheme.strokeLight,
                                                  height: 0,
                                                ),

                                                Flexible(
                                                  child: Builder(
                                                    builder: (BuildContext context) {
                                                      if (sources.isEmpty) {
                                                        return Center(
                                                          child: FusionAppText(
                                                            text: "No sources selected for this function",
                                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                              color: context.colorScheme.primaryWhite,
                                                            ),
                                                          ),
                                                        );
                                                      }

                                                      return CommonReorderableListView<Source>(
                                                        items: sources,
                                                        emptyMessage: "No sources selected for this function",
                                                        keyExtractor: (Source item) => item.id,
                                                        onReorder: (int oldIndex, int newIndex) {},
                                                        itemBuilder: (BuildContext context, Source item, int index) {
                                                          final Source source = sources[index];

                                                          final bool isSourceSelected = vm.isSourceSelect(source.id);

                                                          return MouseRegion(
                                                            cursor: SystemMouseCursors.click,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                vm.toggleSourceSelect(source.id);
                                                              },
                                                              behavior: HitTestBehavior.opaque,
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                ),
                                                                child: Container(
                                                                  key: ValueKey<String>(source.id),
                                                                  padding: const EdgeInsets.all(12),

                                                                  decoration: BoxDecoration(
                                                                    border: Border(
                                                                      bottom: BorderSide(
                                                                        color: Theme.of(context).colorScheme.outline.withValues(
                                                                          alpha: 0.3,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: <Widget>[
                                                                      Icon(
                                                                        Icons.drag_indicator,
                                                                        size: FusionSizes.iconSize16,
                                                                        color: context.colorScheme.iconDefault,
                                                                      ),
                                                                      Expanded(
                                                                        flex: 2,
                                                                        child: Center(
                                                                          child: FusionAppText(
                                                                            text: source.name,
                                                                            maxLine: 1,
                                                                            style: Theme.of(context).textTheme.labelSmall,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      MouseRegion(
                                                                        cursor: SystemMouseCursors.click,
                                                                        child: FusionCheckbox(
                                                                          semanticId: 'source_select_checkbox',
                                                                          value: isSourceSelected,
                                                                          onChanged: () {
                                                                            vm.toggleSourceSelect(
                                                                              source.id,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                                MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: GestureDetector(
                                                    onTap: () {},
                                                    behavior: HitTestBehavior.opaque,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(12),
                                                        child: Row(
                                                          children: <Widget>[
                                                            Icon(
                                                              Icons.drag_indicator,
                                                              size: FusionSizes.iconSize16,
                                                              color: context.colorScheme.iconDefault,
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Center(
                                                                child: FusionAppText(
                                                                  text: "Off",
                                                                  maxLine: 1,
                                                                  style: Theme.of(context).textTheme.labelSmall,
                                                                ),
                                                              ),
                                                            ),
                                                            MouseRegion(
                                                              cursor: SystemMouseCursors.click,
                                                              child: FusionCheckbox(
                                                                semanticId: 'select_settings_off',
                                                                value: sourceSelectAdditionalSettingsVmState.useOff,
                                                                onChanged: () => vm.toggleUseOff(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                                  child: Divider(
                                                    color: context.colorScheme.strokeLight,
                                                    height: 0,
                                                  ),
                                                ),
                                                MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(
                                                        12,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: <Widget>[
                                                          Flexible(
                                                            flex: 2,
                                                            child: Center(
                                                              child: FusionAppText(
                                                                text: "Use crossfade",
                                                                maxLine: 1,
                                                                style: Theme.of(context).textTheme.labelSmall,
                                                              ),
                                                            ),
                                                          ),
                                                          MouseRegion(
                                                            cursor: SystemMouseCursors.click,
                                                            child: FusionCheckbox(
                                                              semanticId: 'select_settings_crossfade',
                                                              value: sourceSelectAdditionalSettingsVmState.useCrossfade,
                                                              onChanged: () => vm.toggleUseCrossfade(),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          VerticalDivider(
                                            width: 1,
                                            color: context.colorScheme.strokeLight,
                                          ),

                                          PrioritySettingsWidget(
                                            zoneId: widget.zoneID,
                                            isStateActive: (int index) => vm.isPriorityControlTypeThreshold(index) || vm.isPriorityStateActive(index),
                                            onStateActivePressAndHoldChanged: (int index, bool isPressed) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                isStateActive: isPressed,
                                              );
                                            },
                                            onPTTControlTypeChanged: (int index) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                priorityControlType: AdditionalSettingsPriorityControlType.pttControler,
                                              );
                                            },
                                            onThresholdControlTypeChanged: (int index) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                priorityControlType: AdditionalSettingsPriorityControlType.threshold,
                                              );
                                            },
                                            isPriorityControlTypePTT: (int index) => vm.isPriorityControlTypePTT(index),
                                            isPriorityControlTypeThreshold: (int index) => vm.isPriorityControlTypeThreshold(index),
                                            enableBehaviorSettingsFields: (int index) => vm.enableBehaviorSettingsFields(index),
                                            getThresholdValue: (int index) => vm.getThresholdValue(index),
                                            getDepth: (int index) => vm.getDepth(index),
                                            getAttack: (int index) => vm.getAttack(index),
                                            getHold: (int index) => vm.getHold(index),
                                            getRelease: (int index) => vm.getRelease(index),
                                            getReductionValue: (int index) => vm.getReductionValue(index),
                                            getPriorityBehavior: (int index) => vm.getPriorityBehavior(index),
                                            onThresholdValueChanged: (int index, num value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                thresholdValue: value.toDouble(),
                                              );
                                            },
                                            onDepthValueChanged: (int index, num value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                depthValue: value.toDouble(),
                                              );
                                            },
                                            onAttackValueChanged: (int index, num value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                attackValue: value.toDouble(),
                                              );
                                            },
                                            onHoldValueChanged: (int index, num value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                holdValue: value.toDouble(),
                                              );
                                            },
                                            onReleaseValueChanged: (int index, num value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                releaseValue: value.toDouble(),
                                              );
                                            },
                                            onPriorityBehaviorChanged: (int index, AdditionalSettingPriorityBehavior value) {
                                              vm.updatePriorityProperties(
                                                zoneOrSubzoneId: widget.zoneID,
                                                index: index,
                                                priorityBehavior: value,
                                              );
                                            },
                                          ),

                                          // RIGHT COLUMN (Static)
                                          Flexible(
                                            flex: 3,
                                            child: ZoneSubZoneBuilderWidget(
                                              zoneID: widget.zoneID,
                                              getLowerGain: (String zoneOrSubzoneID) => vm.getLowerGain(zoneOrSubzoneID),
                                              getUpperGain: (String zoneOrSubzoneID) => vm.getUpperGain(zoneOrSubzoneID),
                                              isAllowMute: (String zoneOrSubzoneID) => vm.isAllowMute(zoneOrSubzoneID),
                                              onLowerRangeChanged: (String zoneOrSubzoneID, num value) {
                                                vm.updateZoneProperties(
                                                  zoneOrSubzoneId: zoneOrSubzoneID,
                                                  lowerLimit: value.toDouble(),
                                                );
                                              },
                                              onUpperRangeChanged: (String zoneOrSubzoneID, num value) {
                                                vm.updateZoneProperties(
                                                  zoneOrSubzoneId: zoneOrSubzoneID,
                                                  upperLimit: value.toDouble(),
                                                );
                                              },
                                              onAllowMuteChanged: (String zoneOrSubzoneID, bool newValue) {
                                                vm.updateZoneProperties(
                                                  zoneOrSubzoneId: zoneOrSubzoneID,
                                                  allowMuteUnmute: newValue,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
