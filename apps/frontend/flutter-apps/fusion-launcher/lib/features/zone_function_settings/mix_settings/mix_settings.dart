import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../zone_functions/widgets/horizontal_scroll_effect_wrapper.dart';
import '../models/models.dart';
import '../widgets/zone_subzone_builder.dart';
import 'viewmodel/mix_settings_vm.dart';

class SourceMixAdditionalSettingsDialog extends StatefulWidget {
  final String zoneID;

  const SourceMixAdditionalSettingsDialog({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceMixAdditionalSettingsDialog(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceMixAdditionalSettingsDialog> createState() =>
      _SourceMixAdditionalSettingsState();
}

class _SourceMixAdditionalSettingsState
    extends State<SourceMixAdditionalSettingsDialog> {
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
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "source_select_main_container",
                        ),
                        child: BlocProvider<
                          SourceMixAdditionalSettingsViewmodel
                        >(
                          create:
                              (_) =>
                                  SourceMixAdditionalSettingsViewmodel()
                                    ..init(zoneID: widget.zoneID),
                          child: BlocBuilder<
                            SourceMixAdditionalSettingsViewmodel,
                            SourceMixAdditionalSettingsVmState
                          >(
                            builder: (
                              BuildContext context,
                              SourceMixAdditionalSettingsVmState state,
                            ) {
                              final SourceMixAdditionalSettingsViewmodel vm =
                                  context
                                      .watch<
                                        SourceMixAdditionalSettingsViewmodel
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
                                            vm: vm,
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
  final SourceMixAdditionalSettingsViewmodel vm;

  const _SourcesSetting({required this.zoneID, required this.vm});

  @override
  State<_SourcesSetting> createState() => __SourcesSettingState();
}

class __SourcesSettingState extends State<_SourcesSetting> {
  late final ScrollController _scrollController = ScrollController();

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    final ProjectViewModel projectViewModel =
        serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesInZone(zoneId: widget.zoneID);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectViewModel>();

    return BlocProvider<SourceMixAdditionalSettingsViewmodel>.value(
      value: widget.vm,
      child: BlocBuilder<
        SourceMixAdditionalSettingsViewmodel,
        SourceMixAdditionalSettingsVmState
      >(
        builder: (
          BuildContext context,
          SourceMixAdditionalSettingsVmState state,
        ) {
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
                child: Builder(
                  builder: (BuildContext context) {
                    if (sources.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: context.colorScheme.strokeLight,
                            ),
                          ),
                        ),
                        child: Center(
                          child: FusionAppText(
                            text: "No sources selected for this function",
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.textPlaceholder,
                            ),
                          ),
                        ),
                      );
                    }

                    return HorizontalScrollWithShadows(
                      controller: _scrollController,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(sources.length, (
                          int index,
                        ) {
                          final Source source = sources[index];

                          final SourceVolumneRangeModel sourceRange = widget.vm
                              .getSourceRange(source.id);

                          return Container(
                            width: 150,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: context.colorScheme.strokeLight,
                                ),
                                right: BorderSide(
                                  color: context.colorScheme.strokeLight,
                                ),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsGeometry.all(16),
                                  child: Center(
                                    child: FusionAppText(
                                      text: source.name,
                                      textAlign: TextAlign.center,
                                      maxLine: 1,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: context.colorScheme.strokeLight,
                                  height: 0,
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(
                                            SemanticTypes.button,
                                            "source_mix_gain_slider",
                                          ),
                                          child: VerticalRangeSelectionSlider(
                                            lowerValue: sourceRange.lowerGain,
                                            upperValue: sourceRange.upperGain,
                                            min: -60,
                                            max: 12,
                                            onLowerChanged: (num value) {
                                              widget.vm.updateSource(
                                                sourceId: source.id,
                                                lowerGain: value.toDouble(),
                                              );
                                            },
                                            onUpperChanged: (num value) {
                                              widget.vm.updateSource(
                                                sourceId: source.id,
                                                upperGain: value.toDouble(),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Divider(
                                          color:
                                              context.colorScheme.strokeLight,
                                          height: 0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            Flexible(
                                              child: FusionAppText(
                                                text: "Allow mute",
                                                style: context
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color:
                                                          context
                                                              .colorScheme
                                                              .textSecondary,
                                                    ),
                                              ),
                                            ),
                                            FusionCheckbox(
                                              value: sourceRange.allowMute,
                                              onChanged: () {
                                                widget.vm.updateSource(
                                                  sourceId: source.id,
                                                  alloMute:
                                                      !sourceRange.allowMute,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
