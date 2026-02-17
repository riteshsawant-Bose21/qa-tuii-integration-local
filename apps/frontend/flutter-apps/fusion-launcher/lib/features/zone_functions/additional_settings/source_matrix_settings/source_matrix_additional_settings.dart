import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'viewmodel/source_matrix_additional_settings_viewmodel.dart';

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
  State<SourceMatrixAdditionalSettingsDialog> createState() => _SourceMatrixAdditionalSettingsState();
}

class _SourceMatrixAdditionalSettingsState extends State<SourceMatrixAdditionalSettingsDialog> {
  late ZoneFunctions zoneFunction;
  @override
  void initState() {
    super.initState();
    zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!;
  }

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  MixScene? selectedMixScene(ZoneFunctions zoneFunction) {
    final String? selectedId = zoneFunction.selectedMixSceneId;
    if (selectedId == null) return null;
    try {
      return zoneFunction.mixScenes.firstWhere((MixScene scene) => scene.id == selectedId);
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
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        child: FusionAppText(
                          text: "SOURCE MIX - PRIORITY SETTINGS ",
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
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_main_container"),
                        child: BlocProvider<SourceMatrixAdditionalSettingsViewmodel>(
                          create: (_) => SourceMatrixAdditionalSettingsViewmodel()..init(zoneID: widget.zoneID),
                          child: BlocBuilder<SourceMatrixAdditionalSettingsViewmodel, SourceMatrixSettingsViewmodelState>(
                            builder: (BuildContext context, SourceMatrixSettingsViewmodelState state) {
                              final SourceMatrixAdditionalSettingsViewmodel vm = context.watch<SourceMatrixAdditionalSettingsViewmodel>();

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
                                      border: Border.all(color: context.colorScheme.strokeLight),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Flexible(
                                          flex: 2,
                                          child: _SourcesSetting(
                                            zoneID: widget.zoneID,
                                            zoneFunctions: zoneFunction,
                                          ),
                                        ),

                                        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
                                        Flexible(
                                          child: _MixSceneSetting(
                                            allowController: false,
                                            zoneId: widget.zoneID,
                                            onAllowControllerChanged: () {
                                              //
                                            },
                                          ),
                                        ),

                                        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
                                        // _AdditionalPrioritySettingsWidget(
                                        //   zoneId: widget.zoneID,
                                        //   vm: context.read<ZoneFunctionAdditionalSettingsViewModel>(),
                                        // ),

                                        // RIGHT COLUMN (Static)
                                        // Flexible(
                                        //   flex: 2,
                                        //   child: AdditionalPriorityZoneSubZoneSettingBuilder(zoneID: widget.zoneID, vm: ),
                                        // ),
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
    late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

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
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
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

// class _AdditionalPrioritySettingsWidget extends StatefulWidget {
//   final String zoneId;
//   final SourceMatrixAdditionalSettingsViewmodel vm;
//   const _AdditionalPrioritySettingsWidget({super.key, required this.zoneId, required this.vm});

//   @override
//   State<_AdditionalPrioritySettingsWidget> createState() => _AdditionalPrioritySettingsWidgetState();
// }

// class _AdditionalPrioritySettingsWidgetState extends State<_AdditionalPrioritySettingsWidget> {
//   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

//   late final List<Source> sources;

//   @override
//   void initState() {
//     super.initState();
//     sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
//     if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

//     final SizedBox child = SizedBox(
//       width: 600,
//       child: Row(
//         children: <Widget>[
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Container(
//                   padding: const EdgeInsets.all(16.0),
//                   width: double.infinity,
//                   alignment: Alignment.center,
//                   child: FusionAppText(
//                     text: "PRIORITY",
//                     style: Theme.of(context).textTheme.labelSmall,
//                   ),
//                 ),

//                 Divider(color: context.colorScheme.strokeLight, height: 0),

//                 Flexible(child: _buildPriorityWidgets(widget.vm)),
//               ],
//             ),
//           ),
//           VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
//         ],
//       ),
//     );

//     // Otherwise, return the child directly
//     return child;
//   }

//   Widget _buildPriorityWidgets(SourceMatrixAdditionalSettingsViewmodel vm) {
//     final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
//     if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

//     return Material(
//       color: Colors.transparent,
//       child: ListView.separated(
//         shrinkWrap: true,
//         physics: const ClampingScrollPhysics(),
//         itemCount: 2,
//         separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
//         itemBuilder: (BuildContext context, int index) {
//           // String? selectedSourceId;
//           String? selectedSourceName;

//           final List<String> prioritySources = projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);

//           /// priority 1
//           if (index == 0) {
//             if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
//               final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[0]);
//               if (sourceData != null) {
//                 selectedSourceName = sourceData.name;
//                 // selectedSourceId = prioritySources[0];
//               }
//             }
//           } else {
//             /// priority 2
//             if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
//               final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[1]);
//               if (sourceData != null) {
//                 selectedSourceName = sourceData.name;
//                 // selectedSourceId = prioritySources[1];
//               }
//             }
//           }

//           final bool isStateActive = vm.isPriorityControlTypeThreshold(index) || vm.isPriorityStateActive(index);

//           return SemanticHelper.button(
//             testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_selection_widget_$index"),
//             child: SizedBox(
//               height: 600,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   //
//                   // ========= HEADINGS ========
//                   //
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: FusionAppText(
//                       text: "PRIORITY ${index + 1}",
//                       style: context.textTheme.labelMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Divider(color: context.colorScheme.strokeLight, height: 0), // // ========= CONTENT ======== //

//                   Expanded(
//                     child: Builder(
//                       builder: (BuildContext context) {
//                         if (selectedSourceName == null) {
//                           return FusionAppText(
//                             text: "No source selected for priority ${index + 1}.",
//                             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                               fontSize: 10,
//                               color: const Color(0xFF888888),
//                             ),
//                           );
//                         }

//                         return Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: <Widget>[
//                             Expanded(
//                               child: Column(
//                                 children: <Widget>[
//                                   Padding(
//                                     padding: const EdgeInsets.all(16.0),
//                                     child: Row(
//                                       spacing: 4,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "PTT/CONTROL",
//                                             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         SemanticHelper.button(
//                                           testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_active_button_$index"),
//                                           child: FusionSwitch(
//                                             value: vm.isPriorityControlTypePTT(index),
//                                             width: 44,
//                                             height: 24,
//                                             onChanged: (bool value) {
//                                               vm.updatePriorityProperties(
//                                                 zoneOrSubzoneId: widget.zoneId,
//                                                 index: index,
//                                                 priorityControlType: AdditionalSettingsPriorityControlType.pttControler,
//                                               );
//                                             },
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Divider(color: context.colorScheme.strokeLight, height: 0),
//                                   Padding(
//                                     padding: const EdgeInsets.all(16.0),
//                                     child: Row(
//                                       spacing: 4,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "THRESHOLD",
//                                             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         SemanticHelper.button(
//                                           testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_active_button_$index"),
//                                           child: FusionSwitch(
//                                             value: vm.isPriorityControlTypeThreshold(index),
//                                             width: 44,
//                                             height: 24,
//                                             onChanged: (bool value) {
//                                               vm.updatePriorityProperties(
//                                                 zoneOrSubzoneId: widget.zoneId,
//                                                 index: index,
//                                                 priorityControlType: AdditionalSettingsPriorityControlType.threshold,
//                                               );
//                                             },
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   const SizedBox(height: 10),
//                                   Divider(color: context.colorScheme.strokeLight, height: 0),
//                                   const SizedBox(height: 10),
//                                   Expanded(
//                                     child: DisabledWidgetWrapper(
//                                       isDisabled: vm.isPriorityControlTypePTT(index),
//                                       child: VerticalSlider(
//                                         value: vm.getThresholdValue(index),
//                                         min: -60,
//                                         max: 12,
//                                         onChanged: (num value) {
//                                           vm.updatePriorityProperties(
//                                             zoneOrSubzoneId: widget.zoneId,
//                                             index: index,
//                                             thresholdValue: value.toDouble(),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Divider(color: context.colorScheme.strokeLight, height: 0),
//                                   const SizedBox(height: 10),
//                                   DisabledWidgetWrapper(
//                                     isDisabled: vm.isPriorityControlTypePTT(index),
//                                     child: NeumorphicGainTextField(
//                                       controllerValue: vm.getThresholdValue(index),
//                                       maxGain: 12,
//                                       minGain: -60,
//                                       onSubmitted: (double value) {
//                                         vm.updatePriorityProperties(
//                                           zoneOrSubzoneId: widget.zoneId,
//                                           index: index,
//                                           thresholdValue: value,
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   FusionAppText(
//                                     text: "dBFS",
//                                     style: context.textTheme.labelSmall?.copyWith(
//                                       color: context.colorScheme.textSecondary,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                 ],
//                               ),
//                             ),

//                             VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

//                             Expanded(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: <Widget>[
//                                     Center(
//                                       child: FusionAppText(
//                                         text: "STATE",
//                                         style: context.textTheme.labelMedium?.copyWith(
//                                           color: context.colorScheme.textSecondary,
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     FusionNeumorphicButton(
//                                       height: 34,
//                                       width: double.infinity,
//                                       text: "Active",
//                                       color: isStateActive ? context.colorScheme.primaryColor : context.colorScheme.elevation2,
//                                       onTap: () {
//                                         // In Threshold mode, the state is always active.
//                                         if (vm.isPriorityControlTypeThreshold(index)) return;

//                                         vm.updatePriorityProperties(
//                                           zoneOrSubzoneId: widget.zoneId,
//                                           index: index,
//                                           isStateActive: !isStateActive,
//                                         );
//                                       },
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Divider(color: context.colorScheme.strokeLight, height: 0),
//                                     const SizedBox(height: 10),

//                                     Center(
//                                       child: FusionAppText(
//                                         text: "BEHAVIOR",
//                                         style: context.textTheme.labelMedium?.copyWith(
//                                           color: context.colorScheme.textSecondary,
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),

//                                     PBDropdown<AdditionalSettingPriorityBehavior>(
//                                       hintText: "select",
//                                       value: vm.getPriorityBehavior(index)?.displayName,
//                                       items: AdditionalSettingPriorityBehavior.values,
//                                       itemBuilder: (BuildContext context, AdditionalSettingPriorityBehavior mode) {
//                                         return FusionAppText(
//                                           text: mode.displayName,
//                                           style: context.textTheme.bodySmall,
//                                         );
//                                       },
//                                       onChanged: (AdditionalSettingPriorityBehavior value) {
//                                         vm.updatePriorityProperties(
//                                           zoneOrSubzoneId: widget.zoneId,
//                                           index: index,
//                                           priorityBehavior: value,
//                                         );
//                                       },
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       spacing: 5,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "DEPTH",
//                                             style: context.textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         NeumorphicGainTextField(
//                                           enabled: vm.isFieldsEnabled(index),
//                                           controllerValue: vm.getDepth(index),
//                                           maxGain: 12,
//                                           minGain: -60,
//                                           onSubmitted: (double value) {
//                                             vm.updatePriorityProperties(
//                                               zoneOrSubzoneId: widget.zoneId,
//                                               index: index,
//                                               depthValue: value.toDouble(),
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       spacing: 5,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "ATTACK",
//                                             style: context.textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         NeumorphicGainTextField(
//                                           enabled: vm.isFieldsEnabled(index),
//                                           controllerValue: vm.getAttack(index),
//                                           maxGain: 12,
//                                           minGain: -60,
//                                           onSubmitted: (double value) {
//                                             vm.updatePriorityProperties(
//                                               zoneOrSubzoneId: widget.zoneId,
//                                               index: index,
//                                               attackValue: value.toDouble(),
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       spacing: 5,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "HOLD",
//                                             style: context.textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         UnitNumberTextField(
//                                           enabled: vm.isFieldsEnabled(index),
//                                           min: 1,
//                                           max: null,
//                                           unit: "ms",
//                                           controllerValue: vm.getHold(index),
//                                           onSubmitted: (double value) {
//                                             vm.updatePriorityProperties(
//                                               zoneOrSubzoneId: widget.zoneId,
//                                               index: index,
//                                               holdValue: value.toDouble(),
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Row(
//                                       spacing: 5,
//                                       children: <Widget>[
//                                         Expanded(
//                                           child: FusionAppText(
//                                             text: "RELEASE",
//                                             style: context.textTheme.labelMedium?.copyWith(
//                                               color: context.colorScheme.textSecondary,
//                                             ),
//                                           ),
//                                         ),
//                                         UnitNumberTextField(
//                                           enabled: vm.isFieldsEnabled(index),
//                                           min: 1,
//                                           max: null,
//                                           unit: "ms",
//                                           controllerValue: vm.getRelease(index),
//                                           onSubmitted: (double value) {
//                                             vm.updatePriorityProperties(
//                                               zoneOrSubzoneId: widget.zoneId,
//                                               index: index,
//                                               releaseValue: value.toDouble(),
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),

//                             VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

//                             Expanded(
//                               child: Column(
//                                 children: <Widget>[
//                                   const Expanded(
//                                     child: Padding(
//                                       padding: EdgeInsets.all(16.0),
//                                       child: SizedBox(
//                                         width: 100,
//                                         child: SimpleVerticalMeter(
//                                           value: -20,
//                                           min: -42,
//                                           max: 0,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Divider(color: context.colorScheme.strokeLight, height: 0),
//                                   const SizedBox(height: 10),
//                                   FusionContainer(
//                                     width: 100,
//                                     height: 32,
//                                     alignment: Alignment.center,
//                                     borderRadius: 8,
//                                     color: context.colorScheme.elevation2,
//                                     child: FusionAppText(
//                                       text: "${vm.getReductionValue(index)}",
//                                       style: context.textTheme.labelMedium?.copyWith(
//                                         color: context.colorScheme.textSecondary,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   FusionAppText(
//                                     text: "dB",
//                                     style: context.textTheme.labelSmall?.copyWith(
//                                       color: context.colorScheme.textSecondary,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
