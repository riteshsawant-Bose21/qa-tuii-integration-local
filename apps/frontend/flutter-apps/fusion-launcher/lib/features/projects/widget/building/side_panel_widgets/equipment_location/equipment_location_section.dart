import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/equipment_location_dialog.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/right_aligned_popup_menu.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/equip_location.dart';
import 'package:fusion_lib/models/project_entities/hardware_component_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../../configuration_page/widgets/snapshots/snapshots_and_scenes_panel.dart';

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

                  PopupMenuButton<dynamic>(
                    onSelected: (dynamic value) {},
                    shadowColor: Colors.transparent,
                    color: Colors.transparent,
                    itemBuilder:
                        (BuildContext context) => <PopupMenuItem<dynamic>>[
                          PopupMenuItem<dynamic>(
                            enabled: false,
                            padding: EdgeInsets.zero,
                            child: SizedBox(
                              width: 250,
                              child: StatefulBuilder(
                                builder: (BuildContext context, StateSetter setMenuState) {
                                  final TextEditingController snapshotsNameController = TextEditingController();
                                  return SingleChildScrollView(
                                    child: CreateSnapshotsOrScenesWidget(
                                      headerText: 'Equipment Location',
                                      nameController: snapshotsNameController,
                                      onCreate: () {
                                        /// Pass popup context so only the menu closes.
                                        BlocProvider.of<ProjectViewModel>(context).addEquipLocation(
                                          equipLocation: EquipLocation(
                                            name: snapshotsNameController.text,
                                          ),
                                        );
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      onCancel: () {
                                        /// Cancel inside popup: close only popup.
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        LucideIcons.plus200,
                        size: 14,
                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final EquipLocation location in equipmentLocations)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: _ExpansionTile(
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
                      itemBuilder:
                          (BuildContext context) => <PopupMenuItem<String>>[
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: FusionAppText(
                                text: 'Delete',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
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
                                    child: Icon(Icons.delete_outline_rounded, size: 12, color: Colors.red[600]),
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
  });
  final String title;
  final Widget child;
  final bool isExpanded;
  final Widget trailing;
  final EquipLocation location;
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
            const SizedBox(width: 4),
            Icon(
              LucideIcons.maximize200,
              size: 12,
              color: context.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),

            Expanded(
              child: RightAlignedPopupMenu(
                menuContent: Theme(
                  data: ThemeData.dark(),
                  child: EquipmentLocationDialog(equipmentLocationId: widget.location.id),
                ),
                child: FusionAppText(
                  text: widget.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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
