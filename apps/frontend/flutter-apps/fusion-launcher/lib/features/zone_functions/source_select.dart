import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'source_mix.dart';
import 'widgets/priority_selection_widget.dart';

class SourceSelectZoneControlPanel extends StatefulWidget {
  final String zoneID;
  const SourceSelectZoneControlPanel({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceSelectZoneControlPanel(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceSelectZoneControlPanel> createState() => _SourceSelectZoneControlPanelState();
}

class _SourceSelectZoneControlPanelState extends State<SourceSelectZoneControlPanel> {
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
                          text: "ZONE CONTROL PANEL - SOURCE SELECT",
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
                                      Expanded(
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
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 8),
                                              padding: const EdgeInsets.all(16.0),
                                              child: Row(
                                                spacing: 10,
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Center(
                                                      child: FusionAppText(
                                                        text: "SIGNAL",
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Center(
                                                      child: FusionAppText(
                                                        text: "CHANNELS",
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Center(
                                                      child: FusionAppText(
                                                        text: "OUTPUT",
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Divider(color: context.colorScheme.strokeLight, height: 0),

                                            Expanded(
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

                                                  return ListView.separated(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    physics: const ClampingScrollPhysics(),
                                                    itemCount: sources.length,
                                                    separatorBuilder: (_, __) => Divider(color: context.colorScheme.strokeLight, height: 0),
                                                    itemBuilder: (BuildContext context, int index) {
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
                                                                Expanded(
                                                                  child: Column(
                                                                    children: <Widget>[
                                                                      Container(
                                                                        height: 16,
                                                                        width: 16,
                                                                        decoration: BoxDecoration(
                                                                          color: context.colorScheme.iconDisabled,
                                                                          borderRadius: BorderRadius.circular(4),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
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
                                                                Expanded(
                                                                  child: MouseRegion(
                                                                    cursor: SystemMouseCursors.click,
                                                                    child: GestureDetector(
                                                                      onTap: () {
                                                                        projectViewModel.selectSourceForFunction(
                                                                          functionId: zoneFunction!.id,
                                                                          sourceId: source.id,
                                                                        );
                                                                      },
                                                                      child: SemanticHelper.toggle(
                                                                        testId: SemanticHelper.createTestId(SemanticTypes.toggle, "source_select_radio_$index"),
                                                                        value: isSelected,
                                                                        child: Icon(
                                                                          Icons.radio_button_checked,
                                                                          size: 16,
                                                                          color:
                                                                              isSelected ? context.colorScheme.textPrimary : context.colorScheme.iconDisabled,
                                                                        ),
                                                                      ),
                                                                    ),
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
