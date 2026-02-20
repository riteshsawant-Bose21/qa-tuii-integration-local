import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/equipment_location_dialog.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/right_aligned_popup_menu.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/equip_location.dart';
import 'package:fusion_lib/models/project_entities/hardware_component_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../configuration/presentation/viewmodel/project_view_model.dart';

class EquipmentLocationSection extends StatelessWidget {
  const EquipmentLocationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<EquipLocation> equipmentLocations = BlocProvider.of<ProjectViewModel>(context).equipLocations;
        return Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FusionAppText(
                      text: "EQUIPMENT LOCATIONS",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      BlocProvider.of<ProjectViewModel>(context).addEquipLocation(
                        equipLocation: EquipLocation(
                          name: "Equipment Location ${equipmentLocations.length + 1}",
                        ),
                      );
                    },

                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "add_equipment_location_button"),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(
                          LucideIcons.plus200,
                          size: 14,
                          color: Theme.of(context).colorScheme.primaryWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // for (final EquipLocation location in equipmentLocations)
            ...List<Widget>.generate(equipmentLocations.length, (int index) {
              final EquipLocation location = equipmentLocations[index];

              return SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_section_item_$index"),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: _ExpansionTile(
                    index: index,
                    title: location.name,
                    isExpanded: true,
                    location: location,
                    trailing: SizedBox(
                      height: 24,
                      width: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 12,
                        position: PopupMenuPosition.under,

                        icon: const Icon(
                          Icons.more_vert,
                          size: 12,
                          color: Colors.grey,
                        ),
                        onSelected: (String value) {
                          if (value == 'delete') {
                            BlocProvider.of<ProjectViewModel>(context).removeEquipLocation(
                              equipLocationId: location.id,
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuItem<String>>[
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: SemanticHelper.button(
                                testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_section_item_remove_button_$index"),
                                child: FusionAppText(
                                  text: 'Delete',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        final List<HardwareComponent> hardwares = BlocProvider.of<ProjectViewModel>(
                          context,
                        ).getHardwareForEquipLocation(equipLocationId: location.id);
                        hardwares.sort((HardwareComponent a, HardwareComponent b) {
                          final int posA = a.equipmentLocationPosition ?? 9999;
                          final int posB = b.equipmentLocationPosition ?? 9999;
                          return posA.compareTo(posB);
                        });
                        return Column(
                          children: <Widget>[
                            for (final HardwareComponent hardware in hardwares)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      LucideIcons.box,
                                      size: 12,
                                      color: context.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FusionAppText(
                                        text: hardware.name,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        BlocProvider.of<ProjectViewModel>(context).removeHardware(
                                          hardwareId: hardware.id,
                                        );
                                      },
                                      child: SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_section_item_remove_button_$index"),
                                        child: Icon(LucideIcons.trash200, size: 12, color: Colors.red[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _ExpansionTile extends StatefulWidget {
  const _ExpansionTile({
    required this.title,
    required this.child,
    this.isExpanded = false,
    required this.trailing,
    required this.location,
    required this.index,
  });
  final String title;
  final Widget child;
  final bool isExpanded;
  final Widget trailing;
  final EquipLocation location;
  final int index;
  @override
  State<_ExpansionTile> createState() => __ExpansionTileState();
}

class __ExpansionTileState extends State<_ExpansionTile> {
  bool isExpanded = true;
  @override
  void initState() {
    super.initState();
    isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(covariant _ExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      isExpanded = widget.isExpanded;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            // Expand/Collapse icon
            InkWell(
              onTap:
                  () => setState(() {
                    isExpanded = !isExpanded;
                  }),
              child: SemanticHelper.toggle(
                testId: SemanticHelper.createTestId(SemanticTypes.toggle, "equipment_location_section_item_expand_collapse_${widget.index}"),
                value: isExpanded,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0.0,
                  child: Icon(
                    Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.maximize200,
              size: 12,
              color: context.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),

            Expanded(
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_section_item_popup_menu_${widget.index}"),
                child: RightAlignedPopupMenu(
                  menuContent: EquipmentLocationDialog(equipmentLocationId: widget.location.id),
                  child: SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_section_item_${widget.index}_title_textfield"),
                    child: TitleTextFieldSwitcher(
                      hintText: "Name",
                      value: widget.title,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      save: (String newValue) {
                        BlocProvider.of<ProjectViewModel>(context).updateEquipLocation(
                          equipLocation: widget.location.copyWith(
                            name: newValue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            widget.trailing,
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child:
              isExpanded
                  ? widget.child
                  : const SizedBox(
                    width: double.infinity,
                  ),
        ),
      ],
    );
  }
}
