import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/popups/create_zone_popup/view_model/create_zone_viewmodel.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../side_panel_widgets/schematic_properties.dart' show hexToColor;
import 'view_model/state.dart';

part 'widgets/add_listening_areas_to_zone.dart';
part 'widgets/create_new_location.dart';
part 'widgets/create_subzone_widget.dart';

class CreateZonePopup extends StatelessWidget {
  final Widget child;
  const CreateZonePopup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      blurAmount: 1,
      backgroundColor: const Color(0xFF292826),
      content: const NewWidget(),
      child: child,
    );
  }
}

class NewWidget extends StatefulWidget {
  const NewWidget({super.key});

  @override
  State<NewWidget> createState() => _NewWidgetState();
}

class _NewWidgetState extends State<NewWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateZoneViewModel>(
      create: (BuildContext context) => CreateZoneViewModel(),
      child: BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
        builder: (BuildContext context, CreateZoneViewModelState state) {
          return Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF292826),
              borderRadius: BorderRadius.circular(16),
            ),
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: Navigator.of(context).pop,
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(LucideIcons.x200, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 0.5, height: 0),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16).copyWith(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // container 20 x 20
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
                                  child: TextFormField(
                                    initialValue: zoneName,
                                    onChanged: (String value) {
                                      context.read<CreateZoneViewModel>().setZoneName(value);
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter zone name',
                                      hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      hoverColor: Colors.transparent,
                                      errorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      fillColor: Colors.transparent,
                                    ),
                                    style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(
                          width: 400,
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
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                      ),
                                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(thickness: 0.5, height: 0),
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

                        const Divider(thickness: 0.5, height: 0),
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
                            NeumorphicDarkButton(
                              onTap: () => context.read<CreateZoneViewModel>().createZone(context),
                              backgroundColor: context.colorScheme.surface,
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
