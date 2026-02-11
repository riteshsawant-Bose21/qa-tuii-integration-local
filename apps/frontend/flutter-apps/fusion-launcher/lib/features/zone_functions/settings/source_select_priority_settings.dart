import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/common_reorderable_list_view.dart';
import 'package:fusion_launcher/features/zone_functions/source_mix.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/priority_selection_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SourceSelectPrioritySettings extends StatefulWidget {
  final String zoneID;

  const SourceSelectPrioritySettings({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceSelectPrioritySettings(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceSelectPrioritySettings> createState() => _SourceSelectPrioritySettingsState();
}

class _SourceSelectPrioritySettingsState extends State<SourceSelectPrioritySettings> {
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
                          text: "SOURCE SELECT - PRIORITY SETTINGS ",
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
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_main_container"),
                        child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                          listener: (BuildContext context, ProjectViewModelState state) {
                            zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
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

                                                        final bool isSelected = source.id == zoneFunction?.selectedSourceId;

                                                        return MouseRegion(
                                                          cursor: SystemMouseCursors.click,
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              projectViewModel.selectSourceForFunction(
                                                                functionId: zoneFunction!.id,
                                                                sourceId: source.id,
                                                              );
                                                            },
                                                            behavior: HitTestBehavior.opaque,
                                                            child: Container(
                                                              key: ValueKey<String>(source.id),
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
                                                                        text: source.name,
                                                                        maxLine: 1,
                                                                        style: Theme.of(context).textTheme.labelSmall,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  MouseRegion(
                                                                    cursor: SystemMouseCursors.click,
                                                                    child: FusionCheckbox(
                                                                      value: isSelected,
                                                                      onChanged: () {
                                                                        projectViewModel.selectSourceForFunction(
                                                                          functionId: zoneFunction!.id,
                                                                          sourceId: source.id,
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
                                                    );
                                                  },
                                                ),
                                              ),
                                              MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {},
                                                  behavior: HitTestBehavior.opaque,
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
                                                            value: false,
                                                            onChanged: () {
                                                              //
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
                                        ),
                                        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                        PrioritySelectionWidget(zoneId: widget.zoneID),

                                        // RIGHT COLUMN (Static)
                                        Flexible(flex: 3, child: ZoneControlSliderBuilder(zoneID: widget.zoneID)),
                                      ],
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
