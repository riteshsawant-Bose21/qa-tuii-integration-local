import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../widgets/priority_setting_widget.dart';
import '../widgets/zone_subzone_builder.dart';
import 'viewmodel/matrix_settings_vm.dart';

class SourceMatrixAdditionalSettingsDialog extends StatefulWidget {
  final String zoneID;

  const SourceMatrixAdditionalSettingsDialog({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceMatrixAdditionalSettingsDialog(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceMatrixAdditionalSettingsDialog> createState() =>
      _SourceMatrixAdditionalSettingsState();
}

class _SourceMatrixAdditionalSettingsState
    extends State<SourceMatrixAdditionalSettingsDialog> {
  late ZoneFunctions zoneFunction;
  @override
  void initState() {
    super.initState();
    zoneFunction =
        projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!;
  }

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  MixScene? selectedMixScene(ZoneFunctions zoneFunction) {
    final String? selectedId = zoneFunction.selectedMixSceneId;
    if (selectedId == null) return null;
    try {
      return zoneFunction.mixScenes.firstWhere(
        (MixScene scene) => scene.id == selectedId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          text: "SOURCE MATRIX - PRIORITY SETTINGS ",
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
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "source_select_main_container",
                        ),
                        child: BlocProvider<
                          SourceMatrixAdditionalSettingsViewmodel
                        >(
                          create:
                              (_) =>
                                  SourceMatrixAdditionalSettingsViewmodel()
                                    ..init(zoneID: widget.zoneID),
                          child: BlocBuilder<
                            SourceMatrixAdditionalSettingsViewmodel,
                            SourceMatrixSettingsVmState
                          >(
                            builder: (
                              BuildContext context,
                              SourceMatrixSettingsVmState state,
                            ) {
                              final SourceMatrixAdditionalSettingsViewmodel vm =
                                  context
                                      .watch<
                                        SourceMatrixAdditionalSettingsViewmodel
                                      >();

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: context.colorScheme.strokeLight,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Flexible(
                                          flex: 2,
                                          child: _SourcesSetting(
                                            zoneID: widget.zoneID,
                                            zoneFunctions: zoneFunction,
                                          ),
                                        ),

                                        VerticalDivider(
                                          width: 1,
                                          color:
                                              context.colorScheme.strokeLight,
                                        ),
                                        Flexible(
                                          child: _MixSceneSetting(
                                            allowController:
                                                vm.isAssignToControllersEnabled,
                                            zoneId: widget.zoneID,
                                            onAllowControllerChanged: () {
                                              vm.toggleAssignToControllers();
                                            },
                                          ),
                                        ),

                                        VerticalDivider(
                                          width: 1,
                                          color:
                                              context.colorScheme.strokeLight,
                                        ),
                                        PrioritySettingsWidget(
                                          zoneId: widget.zoneID,
                                          isStateActive:
                                              (int index) =>
                                                  vm.isPriorityControlTypeThreshold(
                                                    index,
                                                  ) ||
                                                  vm.isPriorityStateActive(
                                                    index,
                                                  ),
                                          onStateActiveChanged: (int index) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              isStateActive:
                                                  !vm.isPriorityControlTypeThreshold(
                                                    index,
                                                  ),
                                            );
                                          },
                                          onPTTControlTypeChanged: (int index) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              priorityControlType:
                                                  AdditionalSettingsPriorityControlType
                                                      .pttControler,
                                            );
                                          },
                                          onThresholdControlTypeChanged: (
                                            int index,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              priorityControlType:
                                                  AdditionalSettingsPriorityControlType
                                                      .threshold,
                                            );
                                          },
                                          isPriorityControlTypePTT:
                                              (int index) =>
                                                  vm.isPriorityControlTypePTT(
                                                    index,
                                                  ),
                                          isPriorityControlTypeThreshold:
                                              (int index) => vm
                                                  .isPriorityControlTypeThreshold(
                                                    index,
                                                  ),
                                          enableBehaviorSettingsFields:
                                              (int index) => vm
                                                  .enableBehaviorSettingsFields(
                                                    index,
                                                  ),
                                          getThresholdValue:
                                              (int index) =>
                                                  vm.getThresholdValue(index),
                                          getDepth:
                                              (int index) => vm.getDepth(index),
                                          getAttack:
                                              (int index) =>
                                                  vm.getAttack(index),
                                          getHold:
                                              (int index) => vm.getHold(index),
                                          getRelease:
                                              (int index) =>
                                                  vm.getRelease(index),
                                          getReductionValue:
                                              (int index) =>
                                                  vm.getReductionValue(index),
                                          getPriorityBehavior:
                                              (int index) =>
                                                  vm.getPriorityBehavior(index),
                                          onThresholdValueChanged: (
                                            int index,
                                            num value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              thresholdValue: value.toDouble(),
                                            );
                                          },
                                          onDepthValueChanged: (
                                            int index,
                                            num value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              depthValue: value.toDouble(),
                                            );
                                          },
                                          onAttackValueChanged: (
                                            int index,
                                            num value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              attackValue: value.toDouble(),
                                            );
                                          },
                                          onHoldValueChanged: (
                                            int index,
                                            num value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              holdValue: value.toDouble(),
                                            );
                                          },
                                          onReleaseValueChanged: (
                                            int index,
                                            num value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              releaseValue: value.toDouble(),
                                            );
                                          },
                                          onPriorityBehaviorChanged: (
                                            int index,
                                            AdditionalSettingPriorityBehavior
                                            value,
                                          ) {
                                            vm.updatePriorityProperties(
                                              zoneOrSubzoneId: widget.zoneID,
                                              index: index,
                                              priorityBehavior: value,
                                            );
                                          },
                                        ),

                                        // RIGHT COLUMN (Static)
                                        Flexible(
                                          flex: 2,
                                          child: ZoneSubZoneBuilderWidget(
                                            zoneID: widget.zoneID,
                                            getLowerGain:
                                                (String zoneOrSubzoneID) =>
                                                    vm.getLowerGain(
                                                      zoneOrSubzoneID,
                                                    ),
                                            getUpperGain:
                                                (String zoneOrSubzoneID) =>
                                                    vm.getUpperGain(
                                                      zoneOrSubzoneID,
                                                    ),
                                            isAllowMute:
                                                (String zoneOrSubzoneID) =>
                                                    vm.isAllowMute(
                                                      zoneOrSubzoneID,
                                                    ),
                                            onLowerRangeChanged: (
                                              String zoneOrSubzoneID,
                                              num value,
                                            ) {
                                              vm.updateZoneProperties(
                                                zoneOrSubzoneId:
                                                    zoneOrSubzoneID,
                                                lowerLimit: value.toDouble(),
                                              );
                                            },
                                            onUpperRangeChanged: (
                                              String zoneOrSubzoneID,
                                              num value,
                                            ) {
                                              vm.updateZoneProperties(
                                                zoneOrSubzoneId:
                                                    zoneOrSubzoneID,
                                                upperLimit: value.toDouble(),
                                              );
                                            },
                                            onAllowMuteChanged: (
                                              String zoneOrSubzoneID,
                                              bool newValue,
                                            ) {
                                              vm.updateZoneProperties(
                                                zoneOrSubzoneId:
                                                    zoneOrSubzoneID,
                                                allowMuteUnmute: newValue,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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

class _SourcesSetting extends StatefulWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const _SourcesSetting({
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  State<_SourcesSetting> createState() => __SourcesSettingState();
}

class __SourcesSettingState extends State<_SourcesSetting> {
  late final ScrollController _scrollController = ScrollController();

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    late final ProjectViewModel projectViewModel =
        serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(
      zoneId: widget.zoneID,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectViewModel>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FusionAppText(
            text: "SOURCES",
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.strokeLight,
                ),
              ),
            ),
            child: Builder(
              builder: (BuildContext context) {
                if (sources.isEmpty) {
                  return Center(
                    child: FusionAppText(
                      text: "No sources selected for this function",
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.textPlaceholder,
                      ),
                    ),
                  );
                }

                return Opacity(
                  opacity: 0.4,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(0.0),
                    itemBuilder: (BuildContext context, int index) {
                      final Source source = sources[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          key: ValueKey<String>(source.id),
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            spacing: 10,
                            children: <Widget>[
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: FusionAppText(
                                    text: source.name,
                                    maxLine: 1,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder:
                        (BuildContext context, int index) =>
                            const SizedBox(height: 10),
                    itemCount: sources.length,
                    physics: const ClampingScrollPhysics(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MixSceneSetting extends StatelessWidget {
  final String zoneId;
  final bool allowController;
  final VoidCallback onAllowControllerChanged;

  const _MixSceneSetting({
    required this.zoneId,
    required this.allowController,
    required this.onAllowControllerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: FusionAppText(
            text: "MIX SCENES",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Divider(color: context.colorScheme.strokeLight, height: 0),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                child: FusionAppText(
                  text: "Assign to controllers",
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ),
              FusionCheckbox(
                semanticId: 'matrix_setting_assign_controller',
                value: allowController,
                onChanged: onAllowControllerChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
