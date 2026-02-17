import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_slider.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/neumorphic_gain_text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/horizontal_scroll_effect_wrapper.dart';
import 'viewmodel/source_mix_additional_settings_viewmodel.dart';

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
  State<SourceMixAdditionalSettingsDialog> createState() => _SourceMixAdditionalSettingsState();
}

class _SourceMixAdditionalSettingsState extends State<SourceMixAdditionalSettingsDialog> {
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
                        child: BlocProvider<SourceMixAdditionalSettingsViewmodel>(
                          create: (_) => SourceMixAdditionalSettingsViewmodel()..init(zoneID: widget.zoneID),
                          child: BlocBuilder<SourceMixAdditionalSettingsViewmodel, SourceMixAdditionalSettingsViewmodelState>(
                            builder: (BuildContext context, SourceMixAdditionalSettingsViewmodelState state) {
                              final SourceMixAdditionalSettingsViewmodel vm = context.watch<SourceMixAdditionalSettingsViewmodel>();

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
                                            allowController: vm.isAssignToControllersEnabled,
                                            zoneId: widget.zoneID,
                                            onAllowControllerChanged: () {
                                              vm.toggleAssignToControllers();
                                            },
                                          ),
                                        ),

                                        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                        // RIGHT COLUMN (Static)
                                        Flexible(
                                          flex: 2,
                                          child: _ZoneSubZoneBuilder(
                                            zoneID: widget.zoneID,
                                            vm: vm,
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
                  children: List<Widget>.generate(sources.length, (int index) {
                    final Source source = sources[index];

                    final MixSettings mixSetting = widget.zoneFunctions.mixSettings!.singleWhere(
                      (MixSettings setting) => setting.sourceId == source.id,
                      orElse: () => MixSettings(sourceId: source.id, gain: 0, muted: true),
                    );

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
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                          Divider(color: context.colorScheme.strokeLight, height: 0),
                          const SizedBox(height: 10),
                          SemanticHelper.formControl(
                            testId: SemanticHelper.createTestId(SemanticTypes.textInput, "source_mix_gain_text_field"),
                            child: NeumorphicGainTextField(
                              controllerValue: mixSetting.gain,
                              minGain: -60,
                              maxGain: 12,
                              onSubmitted: (double value) {
                                projectViewModel.updateMixSettings(
                                  mixSettings: mixSetting.copyWith(
                                    gain: value,
                                  ),
                                  functionId: widget.zoneFunctions.id,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: context.colorScheme.strokeLight, height: 0),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(SemanticTypes.button, "source_mix_gain_slider"),
                                    child: VerticalRangeSelectionSlider(
                                      lowerValue: -40,
                                      upperValue: 0,
                                      min: -60,
                                      max: 12,
                                      onLowerChanged: (num value) {
                                        //
                                      },
                                      onUpperChanged: (num value) {
                                        //
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: context.colorScheme.strokeLight, height: 0),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Flexible(
                                        child: FusionAppText(
                                          text: "Allow mute",
                                          style: context.textTheme.labelMedium?.copyWith(
                                            color: context.colorScheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      FusionCheckbox(
                                        value: false,
                                        onChanged: () {
                                          //
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

class _ZoneSubZoneBuilder extends StatefulWidget {
  final String zoneID;
  final SourceMixAdditionalSettingsViewmodel vm;

  const _ZoneSubZoneBuilder({required this.zoneID, required this.vm});

  @override
  State<_ZoneSubZoneBuilder> createState() => _ZoneSubZoneSettingBuilderState();
}

class _ZoneSubZoneSettingBuilderState extends State<_ZoneSubZoneBuilder> {
  late final ScrollController _scrollController = ScrollController();
  late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late List<SubZone> subZones;
  late Zone? zone;
  late bool isSubZonesAvailable;

  @override
  void initState() {
    super.initState();
    subZones = projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneID);
    if (subZones.isEmpty) zone = projectViewModel.getZone(zoneId: widget.zoneID);
    isSubZonesAvailable = subZones.isNotEmpty;
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
      child: BlocBuilder<SourceMixAdditionalSettingsViewmodel, SourceMixAdditionalSettingsViewmodelState>(
        builder: (BuildContext context, SourceMixAdditionalSettingsViewmodelState state) {
          return Column(
            children: <Widget>[
              if (isSubZonesAvailable) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FusionAppText(
                    text: "SUB ZONE VOLUME",
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium,
                  ),
                ),
              ],

              /// SUBZONE VOLUME
              Expanded(
                child: HorizontalScrollWithShadows(
                  controller: _scrollController,
                  child: ListView.separated(
                    itemCount: isSubZonesAvailable ? subZones.length : 1,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      final SubZone? subZone = isSubZonesAvailable ? subZones[index] : null;

                      final String? title = isSubZonesAvailable ? subZone!.name : zone?.name;
                      if (title == null) return const SizedBox.shrink();

                      final String zoneOrSubzoneID = isSubZonesAvailable ? subZone!.id : zone!.id;

                      final bool isAllowMute = widget.vm.isAllowMute(zoneOrSubzoneID);

                      return Container(
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: context.colorScheme.strokeLight),
                            right: BorderSide(color: context.colorScheme.strokeLight),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              alignment: Alignment.center,
                              child: FusionAppText(
                                text: title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            Divider(color: context.colorScheme.strokeLight, height: 0),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: VerticalRangeSelectionSlider(
                                      min: -60,
                                      max: 12,
                                      lowerValue: widget.vm.getLowerGain(zoneOrSubzoneID),
                                      upperValue: widget.vm.getUpperGain(zoneOrSubzoneID),
                                      onLowerChanged: (num value) {
                                        widget.vm.updateZoneProperties(
                                          zoneOrSubzoneId: zoneOrSubzoneID,
                                          lowerLimit: value.toDouble(),
                                        );
                                      },
                                      onUpperChanged: (num value) {
                                        widget.vm.updateZoneProperties(
                                          zoneOrSubzoneId: zoneOrSubzoneID,
                                          upperLimit: value.toDouble(),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: context.colorScheme.strokeLight, height: 0),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Flexible(
                                          child: FusionAppText(
                                            text: "Allow mute",
                                            style: context.textTheme.labelMedium?.copyWith(
                                              color: context.colorScheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        FusionCheckbox(
                                          value: isAllowMute,
                                          onChanged: () {
                                            widget.vm.updateZoneProperties(
                                              zoneOrSubzoneId: zoneOrSubzoneID,
                                              allowMuteUnmute: !isAllowMute,
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
                    },
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
