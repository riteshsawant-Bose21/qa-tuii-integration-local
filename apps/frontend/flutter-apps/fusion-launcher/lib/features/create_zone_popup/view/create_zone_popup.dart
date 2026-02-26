import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/create_zone_popup/view_model/create_zone_viewmodel.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/schematic_properties.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../view_model/create_zone_viewmodel_state.dart';

part 'widgets/create_new_listening_area.dart';
part 'widgets/create_subzone_widget.dart';
part 'widgets/select_listening_areas.dart';

class CreateZonePopup extends StatelessWidget {
  final Widget child;
  final bool isFromBuildingPage;
  const CreateZonePopup({
    super.key,
    required this.child,
    required this.isFromBuildingPage,
  });

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      backgroundColor: context.colorScheme.elevation1,
      content: NewWidget(isFromBuildingPage: isFromBuildingPage),
      child: child,
    );
  }
}

class NewWidget extends StatefulWidget {
  const NewWidget({super.key, this.isFromBuildingPage = false});
  final bool isFromBuildingPage;

  @override
  State<NewWidget> createState() => _NewWidgetState();
}

class _NewWidgetState extends State<NewWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateZoneViewModel>(
      create: (BuildContext context) => CreateZoneViewModel()..init(isFromBuilding: widget.isFromBuildingPage),
      child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
        builder: (BuildContext context, CreateZoneViewModelState state) {
          return SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ADD SOURCE
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'CREATE ZONE',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, "create_zone_close_button"),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: Navigator.of(context).pop,
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(LucideIcons.x200, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16).copyWith(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // container 20 x 20
                        const SizedBox(height: 10),
                        BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
                          buildWhen: (CreateZoneViewModelState previous, CreateZoneViewModelState current) {
                            return previous.zoneName != current.zoneName || previous.zoneColor != current.zoneColor;
                          },
                          builder: (BuildContext context, CreateZoneViewModelState state) {
                            final String zoneName = state.zoneName;
                            final String zoneColor = state.zoneColor;

                            return Row(
                              children: <Widget>[
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: hexToColor(zoneColor),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SemanticHelper.formControl(
                                    testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_zone_name_input"),
                                    child: PropertyTextField(
                                      initialValue: zoneName,
                                      onChanged: context.read<CreateZoneViewModel>().setZoneName,
                                      hintText: 'Enter zone name',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: 400,
                          child: SemanticHelper.container(
                          testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_color_options"),
                          child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
                            buildWhen: (CreateZoneViewModelState previous, CreateZoneViewModelState current) {
                              return previous.zoneColor != current.zoneColor;
                            },
                            builder: (BuildContext context, CreateZoneViewModelState state) {
                              return GridView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(),
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 21,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: Zone.zoneColors.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String hexCode = Zone.zoneColors[index];
                                  final Color color = hexToColor(hexCode);
                                  final bool isSelected = state.zoneColor == hexCode;

                                  return GestureDetector(
                                    onTap: () {
                                      context.read<CreateZoneViewModel>().setZoneColor(hexCode);
                                    },
                                    child: SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "zone_color_option_$index"),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(4),
                                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                        ),
                                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        ),

                        const SizedBox(height: 20),
                        Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),
                        const SizedBox(height: 20),

                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FusionAppText(
                                text: "Function",
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: BuildingPageDronDown<ZoneFunctionsType>(
                                value: state.zoneFunctionType,
                                items: ZoneFunctionsType.values,
                                labelBuilder: (ZoneFunctionsType option) {
                                  return FusionAppText(
                                    text: option.displayName,
                                    maxLine: 1,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  );
                                },
                                hintText: "Select function type",
                                onSelect: (ZoneFunctionsType newValue) {
                                  context.read<CreateZoneViewModel>().setZoneFunctionType(newValue);
                                },
                              ),
                            ),
                          ],
                        ),

                        if (state.subzones.isEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: "Listening Areas",
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildListeningAreaSelectionSection(context),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),
                        const SizedBox(height: 10),

                        const CreateSubzoneWidget(),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            // Cancel & Save buttons
                            GestureDetector(
                              onTap: Navigator.of(context).pop,
                              child: FusionAppText(
                                text: "Cancel",
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            FusionNeumorphicButton(
                              onTap: () => context.read<CreateZoneViewModel>().createZone(context),
                              color: context.colorScheme.surface,
                              text: "Save",
                              width: 69,
                              height: 32,
                              borderRadius: 8,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
