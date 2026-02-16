import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/widgets.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/common_reorderable_list_view.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/neumorphic_gain_text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../viewmodel/additional_settings_viewmodel.dart';
import '../widgets/horizontal_scroll_effect_wrapper.dart';

class SourceSelectAdditionalSettings extends StatefulWidget {
  final String zoneID;

  const SourceSelectAdditionalSettings({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceSelectAdditionalSettings(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceSelectAdditionalSettings> createState() => _SourceSelectAdditionalSettingsState();
}

class _SourceSelectAdditionalSettingsState extends State<SourceSelectAdditionalSettings> {
  late List<Source> sources;
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
  ZoneFunctions? zoneFunction;

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
    zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
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
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                    BlocProvider<ZoneFunctionAdditionalSettingsViewModel>(
                      create: (_) => ZoneFunctionAdditionalSettingsViewModel()..init(zoneFunctionsType: zoneFunction!.type),
                      child: BlocBuilder<ZoneFunctionAdditionalSettingsViewModel, ZoneFunctionAdditionalSettingsViewmodelState>(
                        builder: (BuildContext context, ZoneFunctionAdditionalSettingsViewmodelState state) {
                          final ZoneFunctionAdditionalSettingsViewModel vm = context.watch<ZoneFunctionAdditionalSettingsViewModel>();

                          return Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: SemanticHelper.container(
                              testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_main_container"),
                              child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                                listener: (BuildContext context, ProjectViewModelState state) {
                                  zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
                                  vm.updateZoneFunctionsType(zoneFunction!.type);
                                },
                                builder: (BuildContext context, ProjectViewModelState state) {
                                  return Container(
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
                                            border: Border.all(color: context.colorScheme.strokeLight),
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
                                                      padding: const EdgeInsets.all(16.0),
                                                      child: FusionAppText(
                                                        text: "SOURCES",
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                    Divider(color: context.colorScheme.strokeLight, height: 0),

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
                                                                    vm.toggleSourceSelect(
                                                                      source.id,
                                                                    );
                                                                  },
                                                                  behavior: HitTestBehavior.opaque,
                                                                  child: Padding(
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
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                                                    value: vm.useOff,
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
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      child: Divider(color: context.colorScheme.strokeLight, height: 0),
                                                    ),
                                                    MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(12),
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
                                                                  value: vm.useCrossfade,
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
                                              VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                              AdditionalPrioritySettingsWidget(
                                                zoneId: widget.zoneID,
                                                vm: vm,
                                              ),

                                              // RIGHT COLUMN (Static)
                                              Flexible(flex: 3, child: AdditionalPriorityZoneSubZoneSettingBuilder(zoneID: widget.zoneID)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

class AdditionalPrioritySettingsWidget extends StatefulWidget {
  final String zoneId;
  final ZoneFunctionAdditionalSettingsViewModel vm;
  const AdditionalPrioritySettingsWidget({super.key, required this.zoneId, required this.vm});

  @override
  State<AdditionalPrioritySettingsWidget> createState() => _AdditionalPrioritySettingsWidgetState();
}

class _AdditionalPrioritySettingsWidgetState extends State<AdditionalPrioritySettingsWidget> {
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

                Flexible(child: _buildReorderablePriorityWidgets(widget.vm)),
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

  Widget _buildReorderablePriorityWidgets(ZoneFunctionAdditionalSettingsViewModel vm) {
    final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    return Material(
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
                      text: "PRIORITY $index",
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
                            text: "No source selected for priority $index.",
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
                                            value: vm.isPriorityControlTypePTT(index),
                                            width: 44,
                                            height: 24,
                                            onChanged: (bool value) {
                                              vm.setPriorityControlType(index, AdditionalSettingsPriorityControlType.pttControler);
                                            },
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
                                            value: vm.isPriorityControlTypeThreshold(index),
                                            width: 44,
                                            height: 24,
                                            onChanged: (bool value) {
                                              vm.setPriorityControlType(index, AdditionalSettingsPriorityControlType.threshold);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  Divider(color: context.colorScheme.strokeLight, height: 0),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: VerticalSlider(
                                      value: vm.thresholdValue,
                                      min: -60,
                                      max: 12,
                                      onChanged: (num value) {
                                        vm.setThresholdValue(value.toDouble());
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(color: context.colorScheme.strokeLight, height: 0),
                                  const SizedBox(height: 10),
                                  NeumorphicGainTextField(
                                    controllerValue: vm.thresholdValue,
                                    maxGain: 12,
                                    minGain: -60,
                                    onSubmitted: vm.setThresholdValue,
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
                                    PBDropdown<AdditionalSettingPriorityBehavior>(
                                      hintText: "select",
                                      items: AdditionalSettingPriorityBehavior.values,
                                      itemBuilder: (BuildContext context, AdditionalSettingPriorityBehavior mode) {
                                        return FusionAppText(
                                          text: mode.displayName,
                                          style: context.textTheme.bodySmall,
                                        );
                                      },
                                      onChanged: (AdditionalSettingPriorityBehavior value) {
                                        vm.setPriorityBehavior(index, value);
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      spacing: 5,
                                      children: <Widget>[
                                        const Expanded(
                                          child: FusionAppText(
                                            text: "DEPTH",
                                          ),
                                        ),
                                        NeumorphicGainTextField(
                                          controllerValue: vm.getDepth(index),
                                          maxGain: 12,
                                          minGain: -60,
                                          onSubmitted: (double value) {
                                            vm.setDepth(index, value.toDouble());
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      spacing: 5,
                                      children: <Widget>[
                                        const Expanded(
                                          child: FusionAppText(
                                            text: "ATTACK",
                                          ),
                                        ),
                                        NeumorphicGainTextField(
                                          controllerValue: vm.getAttack(index),
                                          maxGain: 12,
                                          minGain: -60,
                                          onSubmitted: (double value) {
                                            vm.setAttack(index, value.toDouble());
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      spacing: 5,
                                      children: <Widget>[
                                        const Expanded(
                                          child: FusionAppText(
                                            text: "HOLD",
                                          ),
                                        ),
                                        UnitNumberTextField(
                                          min: 1,
                                          max: null,
                                          unit: "ms",
                                          controllerValue: vm.getHold(index),
                                          onSubmitted: (double value) {
                                            vm.setHold(index, value.toDouble());
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      spacing: 5,
                                      children: <Widget>[
                                        const Expanded(
                                          child: FusionAppText(
                                            text: "RELEASE",
                                          ),
                                        ),
                                        UnitNumberTextField(
                                          min: 1,
                                          max: null,
                                          unit: "ms",
                                          controllerValue: vm.getRelease(index),
                                          onSubmitted: (double value) {
                                            vm.setRelease(index, value.toDouble());
                                          },
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
                                  NeumorphicGainTextField(
                                    maxGain: 12,
                                    minGain: -60,
                                    showDbSuffix: false,
                                    enabled: false,
                                    controllerValue: vm.reductionValue,
                                    onSubmitted: (double value) {
                                      // TODO:
                                    },
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
    );
  }
}

class AdditionalPriorityZoneSubZoneSettingBuilder extends StatefulWidget {
  final String zoneID;

  const AdditionalPriorityZoneSubZoneSettingBuilder({super.key, required this.zoneID});

  @override
  State<AdditionalPriorityZoneSubZoneSettingBuilder> createState() => _ZoneSubZoneSettingBuilderState();
}

class _ZoneSubZoneSettingBuilderState extends State<AdditionalPriorityZoneSubZoneSettingBuilder> {
  late final ScrollController _scrollController = ScrollController();
  late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late List<SubZone> subZones;
  late Zone? zone;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectViewModel>();

    subZones = projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneID);
    if (subZones.isEmpty) zone = projectViewModel.getZone(zoneId: widget.zoneID);

    final bool isSubZonesAvailable = subZones.isNotEmpty;

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
                final bool isMuted = isSubZonesAvailable ? subZone!.muted : zone!.muted;
                final double zoneOrSubzoneGain = isSubZonesAvailable ? subZone!.gain : zone!.gain;

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
                      SemanticHelper.formControl(
                        testId: SemanticHelper.createTestId(SemanticTypes.formControl, "source_mix_zone_gain_text_field"),
                        child: NeumorphicGainTextField(
                          controllerValue: zoneOrSubzoneGain,
                          minGain: -60,
                          maxGain: 12,
                          onSubmitted: (double value) {
                            projectViewModel.updateZoneGain(
                              zoneId: zoneOrSubzoneID,
                              gain: value,
                            );
                          },
                          width: 100,
                          height: 32,
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
                              child: VerticalRangeSelectionSlider(
                                min: -60,
                                max: 12,
                                lowerValue: -40,
                                upperValue: 0,
                                onLowerChanged: (num value) {
                                  print("Lower changed: $value");
                                },
                                onUpperChanged: (num value) {
                                  print("Upper changed: $value");
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
                                    value: isMuted,
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
              },
            ),
          ),
        ),
      ],
    );
  }
}
