import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/constants/assets_constants.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/message_player_config/view/message_player_config_dialog.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/widgets/color_selector_popup.dart';

class ZoneAndListeningAreaPanel extends StatefulWidget {
  final FloorCanvasController floorCanvasController;

  const ZoneAndListeningAreaPanel({
    super.key,
    required this.floorCanvasController,
  });

  @override
  ZoneAndListeningAreaPanelState createState() => ZoneAndListeningAreaPanelState();
}

class ZoneAndListeningAreaPanelState extends State<ZoneAndListeningAreaPanel> with TickerProviderStateMixin {
  final Set<String> _expandedZones = <String>{};
  final Set<String> _expandedListeningAreas = <String>{};
  final Set<String> _expandedSubZones = <String>{};
  final Set<String> _expandedCircuitSections = <String>{};
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  String? editableZoneId;
  String? editableSubZoneId;
  String? editableCircuitSectionId;

  @override
  void initState() {
    super.initState();
    _initializeExpandedStates();
  }

  void _initializeExpandedStates() {
    // Expand all zones by default
    final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;
    for (final Zone zone in zones) {
      _expandedZones.add(zone.id);

      // Expand all subzones within each zone by default
      final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
      for (final SubZone subZone in subZones) {
        _expandedSubZones.add(subZone.id);
      }
    }

    // Expand unassigned speakers section by default
    _expandedCircuitSections.add('unassigned_speakers');
  }

  void _toggleZoneExpansion(String zoneId) {
    setState(() {
      if (_expandedZones.contains(zoneId)) {
        _expandedZones.remove(zoneId);
      } else {
        _expandedZones.add(zoneId);
      }
    });
  }

  void _toggleListeningAreaExpansion(String listeningAreaId) {
    setState(() {
      if (_expandedListeningAreas.contains(listeningAreaId)) {
        _expandedListeningAreas.remove(listeningAreaId);
      } else {
        _expandedListeningAreas.add(listeningAreaId);
      }
    });
  }

  void _toggleSubZoneExpansion(String subZoneId) {
    setState(() {
      if (_expandedSubZones.contains(subZoneId)) {
        _expandedSubZones.remove(subZoneId);
      } else {
        _expandedSubZones.add(subZoneId);
      }
    });
  }

  void _toggleCircuitSectionExpansion(String circuitSectionId) {
    setState(() {
      if (_expandedCircuitSections.contains(circuitSectionId)) {
        _expandedCircuitSections.remove(circuitSectionId);
      } else {
        _expandedCircuitSections.add(circuitSectionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header Section

              // // Divider
              // Container(
              //   height: 1,
              //   color: Colors.grey[200],
              //   margin: const EdgeInsets.symmetric(horizontal: 16),
              // ),

              // Zones List
              _buildZonesList(),

              // Unassigned Speakers Section
              _buildUnassignedSpeakersSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZonesList() {
    final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;

    if (zones.isEmpty) {
      return _buildEmptyState();
    }

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "zone_lists",
      ),
      child: Container(
        constraints: const BoxConstraints(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 3),
            ...zones.map((Zone zone) {
              final int index = zones.indexOf(zone);

              return SemanticHelper.container(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.container,
                  "zone_card_$index",
                ),
                child: Container(
                  child: _buildZoneCard(zone, index),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            FusionAppText(
              text: 'No zones yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(Zone zone, int index) {
    final List<ListeningArea> allListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(
      zoneId: zone.id,
    );
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    // Get all listening areas that are in subzones
    final Set<String> listeningAreasInSubZones = <String>{};
    for (final SubZone subZone in subZones) {
      final List<ListeningArea> subZoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(
        subZoneId: subZone.id,
      );
      listeningAreasInSubZones.addAll(
        subZoneAreas.map((ListeningArea area) => area.id),
      );
    }

    // Filter out listening areas that are in subzones (unused now that we only show circuits)
    // final List<ListeningArea> listeningAreas = allListeningAreas.where((ListeningArea area) => !listeningAreasInSubZones.contains(area.id)).toList();

    final bool isSelected = serviceLocator<ProjectViewModel>().isInZoneSelectionMode && serviceLocator<ProjectViewModel>().currentSelectedZoneId == zone.id;
    final bool isCollapsed = !_expandedZones.contains(zone.id);

    return DragTarget<ListeningArea>(
      onAcceptWithDetails: (DragTargetDetails<ListeningArea> details) {
        final ListeningArea listeningArea = details.data;
        serviceLocator<ProjectViewModel>().addListeningAreaToZone(
          listeningAreaId: listeningArea.id,
          zoneId: zone.id,
        );
      },
      builder: (
        BuildContext context,
        List<ListeningArea?> candidateItems,
        List<dynamic> rejectedItems,
      ) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        return Container(
          decoration: hasIncomingData ? BoxDecoration(color: Colors.blue.withValues(alpha: 0.3)) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Zone Header
              _buildZoneHeader(zone, isSelected, isCollapsed, index),

              // Expandable Zone Content Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Show subzones (which contain their own circuits)
                    _buildSubZonesSection(zone),

                    // Show individual circuits directly in this zone ONLY if there are no subzones
                    if (subZones.isEmpty) ..._buildZoneCircuits(zone),

                    _buildListeningAreaSectionForZone(zoneId: zone.id),
                    const SizedBox(height: 2),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneHeader(Zone zone, bool isSelected, bool isCollapsed, int index) {
    // Check if zone has subzones - if it does, don't accept drops on the zone header
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
    final bool canAcceptDrops = subZones.isEmpty;

    return DragTarget<Speaker>(
      onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        if (!canAcceptDrops) return false;

        // Check if speaker can be added to this zone (not in a subzone)
        final String? speakerZoneId = _getZoneIdForSpeaker(details.data);
        final String? speakerSubZoneId = _getSubZoneIdForSpeaker(details.data);

        // Speaker can be added to zone circuit if it's in the same zone and not in any subzone
        return speakerZoneId == zone.id && speakerSubZoneId == null;
      },
      onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        if (!canAcceptDrops) return;

        // Remove speaker from existing circuit if it's in one
        final CircuitModel? existingCircuit = _findCircuitForSpeaker(
          details.data,
        );
        if (existingCircuit != null) {
          _removeSpeakerFromCircuit(details.data, existingCircuit);
        }

        _createNewCircuitWithSpeaker(details.data, zone.id, null);
      },
      builder: (BuildContext context, List<Speaker?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        bool canAcceptDrop = false;
        if (canAcceptDrops && hasIncomingData && candidateItems.first != null) {
          final Speaker candidateSpeaker = candidateItems.first!;
          final String? speakerZoneId = _getZoneIdForSpeaker(candidateSpeaker);
          final String? speakerSubZoneId = _getSubZoneIdForSpeaker(
            candidateSpeaker,
          );
          canAcceptDrop = speakerZoneId == zone.id && speakerSubZoneId == null;
        }

        return Container(
          decoration: BoxDecoration(
            color: () {
              if (hasIncomingData && canAcceptDrops) {
                return (canAcceptDrop ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3));
              } else {
                return (isSelected ? context.colorScheme.elevation2 : Colors.transparent);
              }
            }(),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: InkWell(
              onTap: () => _toggleZoneExpansion(zone.id),
              child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  return Row(
                    children: <Widget>[
                      // Expand/Collapse icon
                      InkWell(
                        onTap: () => _toggleZoneExpansion(zone.id),
                        child: SemanticHelper.toggle(
                          testId: SemanticHelper.createTestId(SemanticTypes.toggle, "zone_expand_collapse_$index"),
                          value: isCollapsed,
                          child: Icon(
                            !isCollapsed ? LucideIcons.chevronDown200 : LucideIcons.chevronRight200,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildZoneIndicator(zone),
                      const SizedBox(width: 8),
                      Expanded(child: _buildZoneTitle(zone, isSelected)),
                      Builder(
                        builder: (BuildContext context) {
                          if (serviceLocator<ProjectViewModel>().currentSelectedZoneId != null) {
                            return const SizedBox(height: 24);
                          } else {
                            return SizedBox(
                              height: 24,
                              width: 24,
                              child: PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
                                  side: BorderSide(color: context.colorScheme.elevation4),
                                ),
                                padding: EdgeInsets.zero,
                                color: context.colorScheme.elevation1,
                                menuPadding: EdgeInsets.zero,
                                shadowColor: Colors.transparent,
                                iconSize: 12,
                                position: PopupMenuPosition.under,
                                icon: SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "zone_actions_$index"),
                                  child: const Icon(Icons.more_vert, size: 12, color: Colors.grey),
                                ),
                                tooltip: 'Zone actions',
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'add_subzone':
                                      _addSubZoneToZone(zone.id);
                                      break;
                                    case 'add_listening_area':
                                      serviceLocator<ProjectViewModel>().enterZoneSelectionMode(zone);
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmation(zone);
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'add_subzone',
                                      child: SemanticHelper.container(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.container,
                                          "add_subzone_menu_item_$index",
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.crop_free_sharp,
                                              size: 16,
                                              color: context.colorScheme.textPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: 'Add Subzone',
                                              style: context.textTheme.bodySmall?.copyWith(
                                                color: context.colorScheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ];

                                  final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
                                  if (subZones.isEmpty) {
                                    items.add(
                                      PopupMenuItem<String>(
                                        value: 'add_listening_area',
                                        child: SemanticHelper.container(
                                          testId: SemanticHelper.createTestId(SemanticTypes.container, "add_listening_area_menu_item_$index"),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Icons.add,
                                                size: 16,
                                                color: context.colorScheme.iconWhite,
                                              ),
                                              const SizedBox(width: 8),
                                              FusionAppText(
                                                text: 'Select Listening Areas',
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  color: context.colorScheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  items.add(const PopupMenuDivider(height: 0));
                                  items.add(
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: SemanticHelper.container(
                                        testId: SemanticHelper.createTestId(SemanticTypes.container, "delete_zone_menu_item_$index"),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Icon(
                                              LucideIcons.trash200,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: 'Delete Zone',
                                              style: context.textTheme.bodySmall?.copyWith(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  return items;
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoneIndicator(Zone zone) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "zone_color_selector"),
      child: ColorSelector(
        enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
        selectedColor: hexToColor(zone.zoneColor),
        availableColors: Zone.zoneColors.map((String color) => hexToColor(color)).toList(),
        onColorChanged: (Color color) {
          serviceLocator<ProjectViewModel>().updateZone(zone: zone.copyWith(zoneColor: colorToHex(color)));
        },
        width: 18,
        height: 18,
        borderRadius: 4,
      ),
    );
  }

  static Color hexToColor(String hexString) {
    final StringBuffer buffer = StringBuffer();
    if (hexString.startsWith('#')) hexString = hexString.substring(1);
    if (hexString.length == 6) buffer.write('FF');
    buffer.write(hexString);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    String twoHex(int v) => v.toRadixString(16).padLeft(2, '0');

    final int a = (color.a * 255.0).round() & 0xff;
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    final StringBuffer buffer = StringBuffer();
    if (includeAlpha) buffer.write(twoHex(a));
    buffer
      ..write(twoHex(r))
      ..write(twoHex(g))
      ..write(twoHex(b));

    return '#${buffer.toString().toUpperCase()}';
  }

  Widget _buildZoneTitle(Zone zone, bool isSelected) {
    final TextEditingController controller = TextEditingController(text: zone.name);

    void saveValue() {
      FocusManager.instance.primaryFocus?.unfocus();
      final String trimmedValue = controller.text.trim();
      setState(() => editableZoneId = null);

      if (trimmedValue.isNotEmpty && trimmedValue != zone.name) {
        final Zone updated = zone.copyWith(name: trimmedValue);
        serviceLocator<ProjectViewModel>().updateZone(zone: updated);
      } else if (trimmedValue.isEmpty) {
        FusionToast.error(context, message: 'Zone name cannot be empty');
        controller.text = zone.name; // Revert to original name
        return;
      }
    }

    return Container(
      key: ValueKey<String>(zone.id),
      constraints: const BoxConstraints(),
      alignment: Alignment.centerLeft,
      child: SemanticHelper.formControl(
        testId: SemanticHelper.createTestId(SemanticTypes.textInput, "zone_name"),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey<bool>(editableZoneId != null),
            children: <Widget>[
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    if (editableZoneId == zone.id) {
                      return PropertyTextField(
                        autofocus: true,
                        controller: controller,
                        maxLength: 24,
                        enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
                        hintText: 'Zone Name',
                        maxLines: 1,
                        onTapOutside: (PointerDownEvent event) => saveValue(),
                        onSubmitted: (String value) => saveValue(),
                      );
                    } else {
                      return GestureDetector(
                        onDoubleTap: () {
                          if (serviceLocator<ProjectViewModel>().currentSelectedZoneId == null) setState(() => editableZoneId = zone.id);
                        },
                        child: FusionAppText(
                          text: zone.name,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubZoneTitle(SubZone subZone, bool isSelected) {
    final TextEditingController controller = TextEditingController(text: subZone.name);

    void saveValue() {
      final String trimmedValue = controller.text.trim();
      if (trimmedValue.isNotEmpty && trimmedValue != subZone.name) {
        final SubZone updated = subZone.copyWith(name: trimmedValue);
        serviceLocator<ProjectViewModel>().updateSubZone(subZone: updated);
      } else if (trimmedValue.isEmpty) {
        controller.text = subZone.name; // Revert to original name
      }
    }

    return Container(
      key: ValueKey<String>(subZone.id),
      constraints: const BoxConstraints(),
      child: SemanticHelper.formControl(
        testId: SemanticHelper.createTestId(SemanticTypes.textInput, "subzone_name"),
        child: PropertyTextField(
          controller: controller,
          maxLength: 24,
          enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
          hintText: 'SubZone Name',
          maxLines: 1,
          onTapOutside: (PointerDownEvent event) {
            FocusManager.instance.primaryFocus?.unfocus();
            saveValue();
          },
          onSubmitted: (String v) {
            final String trimmedValue = v.trim();
            if (trimmedValue.isEmpty) {
              FusionToast.error(context, message: 'Subzone name cannot be empty');
              controller.text = subZone.name; // Revert to original name
              return;
            }
            saveValue();
          },
        ),
      ),
    );
  }

  Widget _buildListeningAreaSectionForZone({
    String? zoneId,
    String? subZoneId,
  }) {
    if (zoneId == null && subZoneId == null) {
      return const SizedBox.shrink();
    }
    final List<ListeningArea> listeningAreas =
        subZoneId != null
            ? serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(
              subZoneId: subZoneId,
            )
            : serviceLocator<ProjectViewModel>().getListeningAreasForZone(
              zoneId: zoneId!,
            );

    final List<HardwareComponent> allHardware = <HardwareComponent>[];

    for (ListeningArea area in listeningAreas) {
      final List<HardwareComponent> hardwareForArea =
          serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id).where((HardwareComponent hw) => hw is! Speaker).toList();
      allHardware.addAll(hardwareForArea);
    }

    if (allHardware.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Expandable Speakers Section
        if (allHardware.isNotEmpty) ...<Widget>[
          ...allHardware.map(
            (HardwareComponent hardware) {
              final int index = allHardware.indexOf(hardware);
              return SemanticHelper.container(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.container,
                  "listening_area_hardware_$index",
                ),
                child: _buildHardwareItem(hardware),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHardwareItem(HardwareComponent hardware) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == hardware.id;

        return Container(
          margin: const EdgeInsets.only(left: 24, top: 2),
          decoration: BoxDecoration(
            color: isSelected ? context.colorScheme.elevation4 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () {
              serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(
                hardware.id,
              );
              serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    hardware.assetImagePath,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    child: TitleTextFieldSwitcher(
                      value: hardware.name,
                      style: Theme.of(context).textTheme.bodySmall!,
                      save: (String value) {
                        if (value.isNotEmpty) {
                          if (hardware is Source) {
                            final HardwareComponent updatedHw = hardware.copyWith(name: value);
                            projectViewModel.updateHardware(
                              hardware: updatedHw,
                            );
                          } else if (hardware is FusionController) {
                            final HardwareComponent updatedHw = hardware.copyWith(name: value);
                            projectViewModel.updateHardware(
                              hardware: updatedHw,
                            );
                          }
                        }
                      },
                      hintText: 'Enter source name',
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// Only show config option for sources that have a paging source type (i.e. message players)
                  Visibility(
                    visible: hardware is Source ? hardware.pagingSourceType != null : false,
                    child: InkWell(
                      onTap: () {
                        MessagePlayerConfigDialog.show(
                          context,
                          sourceId: hardware.id,
                        );
                      },
                      child: FusionImage.asset(
                        Assets.configurationFilledIcon,
                        width: 18,
                        height: 18,
                        assetColor: context.colorScheme.primaryWhite,

                        fit: BoxFit.contain,
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
  }

  /// Build individual circuits for a zone as expandable items
  List<Widget> _buildZoneCircuits(Zone zone) {
    final List<CircuitModel> circuits = _getZoneCircuits(zone.id);
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    // Don't show zone circuits if zone has subzones
    if (subZones.isNotEmpty) return <Widget>[];

    // Zone header now handles drag target for creating new circuits
    // Just return the individual circuit items
    return circuits.map((CircuitModel circuit) => _buildExpandableCircuit(circuit, zone: zone)).toList();
  }

  /// Build individual circuits for a subzone as expandable items
  List<Widget> _buildSubZoneCircuits(SubZone subZone) {
    final List<CircuitModel> circuits = serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZone.id);

    // Subzone header now handles drag target for creating new circuits
    // Just return the individual circuit items
    return circuits.map((CircuitModel circuit) => _buildExpandableCircuit(circuit, subZone: subZone)).toList();
  }

  /// Build expandable circuit with speakers as children
  Widget _buildExpandableCircuit(CircuitModel circuit, {Zone? zone, SubZone? subZone}) {
    final List<HardwareComponent> circuitHardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(
      circuitId: circuit.id,
    );
    final List<Speaker> circuitSpeakers = circuitHardware.whereType<Speaker>().toList();
    final bool isSubZone = subZone != null;
    final double leftPadding = isSubZone ? 40.0 : 24.0;

    final String circuitId = circuit.id;
    final bool isExpanded = _expandedCircuitSections.contains(circuitId);

    return DragTarget<Speaker>(
      onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in this circuit
        if (circuitSpeakers.any((Speaker s) => s.id == details.data.id)) return false;

        // Check zone/subzone restrictions
        if (!_canSpeakerBeAddedToCircuit(details.data, circuit)) return false;

        // Only accept if circuit is empty or speaker is same model (SKU) as existing speakers
        if (circuitSpeakers.isEmpty) return true;
        return circuitSpeakers.first.speakerSKU == details.data.speakerSKU;
      },
      onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in this circuit
        if (circuitSpeakers.any((Speaker s) => s.id == details.data.id)) {
          return; // Do nothing if already in this circuit
        }

        // Check zone/subzone restrictions
        if (!_canSpeakerBeAddedToCircuit(details.data, circuit)) {
          _showSpeakerZoneRestrictionError(details.data, circuit);
          return;
        }

        // Check speaker model compatibility
        if (circuitSpeakers.isNotEmpty && circuitSpeakers.first.speakerSKU != details.data.speakerSKU) {
          _showSpeakerModelValidationError(details.data, circuitSpeakers.first);
          return;
        }

        // Remove speaker from existing circuit if it's in one
        final CircuitModel? existingCircuit = _findCircuitForSpeaker(
          details.data,
        );
        if (existingCircuit != null && existingCircuit.id != circuit.id) {
          _removeSpeakerFromCircuit(details.data, existingCircuit);
        }

        _addSpeakerToCircuit(details.data, circuit.id);

        // Auto-expand circuit when speaker is added
        setState(() {
          _expandedCircuitSections.add(circuitId);
        });
      },
      builder: (BuildContext context, List<Speaker?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        bool canAccept = false;
        if (hasIncomingData && candidateItems.first != null) {
          final Speaker candidateSpeaker = candidateItems.first!;
          canAccept =
              !circuitSpeakers.any((Speaker s) => s.id == candidateSpeaker.id) &&
              _canSpeakerBeAddedToCircuit(candidateSpeaker, circuit) &&
              (circuitSpeakers.isEmpty || circuitSpeakers.first.speakerSKU == candidateSpeaker.speakerSKU);
        }

        return Container(
          margin: EdgeInsets.only(left: leftPadding, top: 1, right: 12, bottom: 1),
          decoration: BoxDecoration(
            color: hasIncomingData ? (canAccept ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Circuit Header
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "speakers"),
                child: Padding(
                  padding: const EdgeInsets.all(6).copyWith(right: 0),
                  child: InkWell(
                    onTap: () => _toggleCircuitSectionExpansion(circuit.id),
                    child: Row(
                      children: <Widget>[
                        // Expand/Collapse icon
                        InkWell(
                          onTap: () => _toggleCircuitSectionExpansion(circuit.id),
                          child: Icon(
                            _expandedCircuitSections.contains(circuit.id) ? LucideIcons.chevronDown200 : LucideIcons.chevronRight200,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Circuit icon - show actual speaker image if circuit has speakers
                        if (circuitSpeakers.isNotEmpty)
                          FusionImage.asset(
                            serviceLocator<ProjectViewModel>().getHardwareImage(
                              productId: circuitSpeakers.first.productId ?? 0,
                              currentImagePath: circuitSpeakers.first.assetImagePath,
                            ),
                            width: 16,
                            height: 16,
                          )
                        else
                          Icon(
                            Icons.speaker_group,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FusionAppText(
                            semanticId: "circuit_speaker_name",
                            text: circuitSpeakers.isNotEmpty ? '${circuitSpeakers.first.name} (${circuitSpeakers.length}x)' : 'Empty circuit',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: circuitSpeakers.isNotEmpty ? context.colorScheme.textPrimary : context.colorScheme.elevation5,
                              fontStyle: circuitSpeakers.isEmpty ? FontStyle.italic : null,
                            ),
                          ),
                        ),
                        // Circuit actions menu
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                FusionSizes.borderRadius12,
                              ),
                              side: BorderSide(
                                color: context.colorScheme.elevation4,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            color: context.colorScheme.elevation1,
                            menuPadding: EdgeInsets.zero,
                            shadowColor: Colors.transparent,
                            iconSize: 12,
                            position: PopupMenuPosition.under,
                            icon: const Icon(
                              Icons.more_vert,
                              size: 12,
                              color: Colors.grey,
                            ),
                            tooltip: 'Circuit actions',
                            onSelected: (String value) {
                              switch (value) {
                                case 'rename':
                                  _showRenameCircuitDialog(circuit);
                                  break;
                                case 'delete':
                                  _showDeleteCircuitConfirmation(circuit);
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'rename',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: context.colorScheme.textPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      FusionAppText(
                                        text: 'Rename',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 0),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        LucideIcons.trash200,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      FusionAppText(
                                        text: 'Delete',
                                        style: context.textTheme.bodySmall?.copyWith(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Expandable Speakers Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (circuitSpeakers.isNotEmpty)
                      ...circuitSpeakers.map(
                        (Speaker speaker) => _buildCircuitSpeakerItem(speaker, circuit),
                      )
                    else
                      _buildEmptyCircuitMessage(),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build speaker item within a circuit (draggable to other circuits)
  Widget _buildCircuitSpeakerItem(Speaker speaker, CircuitModel circuit) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;

        return Draggable<Speaker>(
          data: speaker,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FusionImage.asset(
                    serviceLocator<ProjectViewModel>().getHardwareImage(
                      productId: speaker.productId ?? 0,
                      currentImagePath: speaker.assetImagePath,
                    ),
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    speaker.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(
              left: 12,
              top: 1,
              right: 6,
              bottom: 1,
            ),
            decoration: BoxDecoration(
              color: isSelected ? context.colorScheme.elevation4 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(
                  speaker.id,
                );
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  children: <Widget>[
                    FusionImage.asset(
                      serviceLocator<ProjectViewModel>().getHardwareImage(
                        productId: speaker.productId ?? 0,
                        currentImagePath: speaker.assetImagePath,
                      ),
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    // Expanded(
                    //   child: FusionAppText(
                    //     text: speaker.name,
                    //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    //       fontSize: 10,
                    //       fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    //       color: Colors.black87,
                    //     ),
                    //   ),
                    // ),
                    Expanded(
                      child: TitleTextFieldSwitcher(
                        value: speaker.name,
                        hintText: "Speaker Name",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: context.colorScheme.textPrimary,
                        ),
                        save: (String value) {
                          if (value.isNotEmpty) {
                            final HardwareComponent hardware = speaker.copyWith(
                              name: value,
                            );
                            projectViewModel.updateHardware(hardware: hardware);
                          }
                        },
                      ),
                    ),
                    // Remove from circuit action
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            FusionSizes.borderRadius12,
                          ),
                          side: BorderSide(
                            color: context.colorScheme.elevation4,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        color: context.colorScheme.elevation1,
                        menuPadding: EdgeInsets.zero,
                        shadowColor: Colors.transparent,
                        iconSize: 12,
                        position: PopupMenuPosition.under,
                        icon: const Icon(
                          Icons.more_vert,
                          size: 12,
                          color: Colors.grey,
                        ),
                        tooltip: 'Speaker actions',
                        onSelected: (String value) {
                          if (value == 'remove') {
                            _removeSpeakerFromCircuit(speaker, circuit);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'remove',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.remove_circle_outline,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    FusionAppText(
                                      text: 'Remove from Circuit',
                                      style: context.textTheme.bodySmall?.copyWith(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ),
                    Icon(
                      Icons.drag_indicator,
                      size: FusionSizes.iconSize16,
                      color: context.colorScheme.textPlaceholder,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build empty circuit message
  Widget _buildEmptyCircuitMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 6, top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FusionAppText(
              text: 'Drag speakers here to add to circuit',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build unassigned speakers section
  Widget _buildUnassignedSpeakersSection() {
    final List<Speaker> unassignedSpeakers = _getUnassignedSpeakers();

    if (unassignedSpeakers.isEmpty) {
      return const SizedBox.shrink();
    }

    const String sectionId = 'unassigned_speakers';
    final bool isExpanded = _expandedCircuitSections.contains(sectionId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Unassigned Speakers Header
        Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: InkWell(
              onTap: () => _toggleCircuitSectionExpansion(sectionId),
              child: Row(
                children: <Widget>[
                  // Expand/Collapse icon
                  InkWell(
                    onTap: () => _toggleCircuitSectionExpansion(sectionId),
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
                    Icons.warning_amber_outlined,
                    size: 14,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unassigned Speakers (${unassignedSpeakers.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable Speaker Items
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...unassignedSpeakers.map(
                (Speaker speaker) => _buildUnassignedSpeakerItem(speaker),
              ),
              const SizedBox(height: 2),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Get all speakers that are not assigned to any circuit
  List<Speaker> _getUnassignedSpeakers() {
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getAllHardware();
    final List<Speaker> allSpeakers = allHardware.whereType<Speaker>().toList();

    // Filter out speakers that are already in circuits
    return allSpeakers.where((Speaker speaker) => !_isSpeakerInAnyCircuit(speaker)).toList();
  }

  /// Build unassigned speaker item
  Widget _buildUnassignedSpeakerItem(Speaker speaker) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;

        return Draggable<Speaker>(
          data: speaker,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                borderRadius: BorderRadius.circular(4),
                // border: Border.all(color: context.colorScheme.strokeLight, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FusionImage.asset(
                    serviceLocator<ProjectViewModel>().getHardwareImage(
                      productId: speaker.productId ?? 0,
                      currentImagePath: speaker.assetImagePath,
                    ),
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 4),
                  FusionAppText(
                    text: speaker.name,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(left: 40, top: 2),
            decoration: BoxDecoration(
              color: isSelected ? context.colorScheme.elevation4 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(
                  speaker.id,
                );
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: <Widget>[
                    FusionImage.asset(
                      serviceLocator<ProjectViewModel>().getHardwareImage(
                        productId: speaker.productId ?? 0,
                        currentImagePath: speaker.assetImagePath,
                      ),
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FusionAppText(
                        text: speaker.name,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: context.colorScheme.textPrimary,
                        ),
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
  }

  /// Create a new circuit with the given speaker
  void _createNewCircuitWithSpeaker(
    Speaker speaker,
    String zoneId,
    String? subZoneId,
  ) {
    // Create a new circuit
    final List<CircuitModel> existingCircuits =
        subZoneId != null
            ? serviceLocator<ProjectViewModel>().getCircuitsInSubZone(
              subZoneId: subZoneId,
            )
            : _getZoneCircuits(zoneId);

    final CircuitModel newCircuit = CircuitModel(
      name: '${speaker.hardwareName} ${existingCircuits.length + 1}',
      speakerSKU: speaker.speakerSKU,
      addedInBuildingPage: true,
    );

    // Add the circuit to the project
    serviceLocator<ProjectViewModel>().addCircuit(circuit: newCircuit);

    // Add the circuit to the zone or subzone
    if (subZoneId != null) {
      serviceLocator<ProjectViewModel>().addCircuitToSubZone(
        circuitId: newCircuit.id,
        subZoneId: subZoneId,
      );
    } else {
      serviceLocator<ProjectViewModel>().addCircuitToZone(
        circuitId: newCircuit.id,
        zoneId: zoneId,
      );
    }

    // Add the speaker to the new circuit
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(
      hwId: speaker.id,
      circuitId: newCircuit.id,
    );

    // Automatically expand the circuit
    setState(() {
      _expandedCircuitSections.add(newCircuit.id);
    });
  }

  /// Find the parent zone ID for a given subzone
  String? _getParentZoneIdForSubZone(String subZoneId) {
    final List<Zone> allZones = serviceLocator<ProjectViewModel>().getAllZones();
    for (final Zone zone in allZones) {
      final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
      if (subZones.any((SubZone s) => s.id == subZoneId)) {
        return zone.id;
      }
    }
    return null;
  }

  /// Build subzones section
  Widget _buildSubZonesSection(Zone zone) {
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    if (subZones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...List<Widget>.generate(
          subZones.length,
          (int index) {
            final SubZone subZone = subZones[index];
            return _buildSubZoneItem(subZone, zone, index);
          },
        ),
      ],
    );
  }

  /// Build subzone item
  Widget _buildSubZoneItem(SubZone subZone, Zone zone, int index) {
    final bool isExpanded = _expandedSubZones.contains(subZone.id);

    return DragTarget<ListeningArea>(
      onAcceptWithDetails: (DragTargetDetails<ListeningArea> details) {
        final ListeningArea listeningArea = details.data;
        _addListeningAreaToSubZone(listeningArea.id, subZone.id);
      },
      builder: (
        BuildContext context,
        List<ListeningArea?> candidateItems,
        List<dynamic> rejectedItems,
      ) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        return Container(
          decoration: hasIncomingData ? BoxDecoration(color: Colors.green.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Subzone Header with Speaker DragTarget
              DragTarget<Speaker>(
                onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
                  // Check if speaker can be added to this subzone
                  final String? speakerSubZoneId = _getSubZoneIdForSpeaker(details.data);

                  // Speaker can be added to subzone circuit if it's in the same subzone
                  return speakerSubZoneId == subZone.id;
                },
                onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
                  // Remove speaker from existing circuit if it's in one
                  final CircuitModel? existingCircuit = _findCircuitForSpeaker(details.data);
                  if (existingCircuit != null) {
                    _removeSpeakerFromCircuit(details.data, existingCircuit);
                  }

                  // Get the parent zone for this subzone
                  final String? parentZoneId = _getParentZoneIdForSubZone(subZone.id);
                  if (parentZoneId != null) {
                    _createNewCircuitWithSpeaker(
                      details.data,
                      parentZoneId,
                      subZone.id,
                    );
                  }
                },
                builder: (
                  BuildContext context,
                  List<Speaker?> candidateSpeakers,
                  List<dynamic> rejectedSpeakers,
                ) {
                  final bool hasIncomingSpeaker = candidateSpeakers.isNotEmpty && candidateSpeakers.first != null;

                  bool canAcceptSpeaker = false;
                  if (hasIncomingSpeaker && candidateSpeakers.first != null) {
                    final Speaker candidateSpeaker = candidateSpeakers.first!;
                    final String? speakerSubZoneId = _getSubZoneIdForSpeaker(candidateSpeaker);
                    canAcceptSpeaker = speakerSubZoneId == subZone.id;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color:
                          hasIncomingSpeaker ? (canAcceptSpeaker ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)) : Colors.transparent,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                      child: InkWell(
                        onTap: () => _toggleSubZoneExpansion(subZone.id),
                        child: Row(
                          children: <Widget>[
                            // Expand/Collapse icon
                            InkWell(
                              onTap: () => _toggleSubZoneExpansion(subZone.id),
                              child: Icon(
                                isExpanded ? LucideIcons.chevronDown200 : LucideIcons.chevronRight200,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Subzone icon
                            Icon(
                              Icons.crop_free_sharp,
                              size: 12,
                              color: zone.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildSubZoneTitle(subZone, false),
                            ),
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    FusionSizes.borderRadius12,
                                  ),
                                  side: BorderSide(
                                    color: context.colorScheme.elevation4,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                color: context.colorScheme.elevation1,
                                menuPadding: EdgeInsets.zero,
                                shadowColor: Colors.transparent,
                                iconSize: 12,
                                position: PopupMenuPosition.under,
                                icon: SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.button,
                                    "subzone_actions_$index",
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                tooltip: 'Subzone actions',
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'select_listening_areas_subzone':
                                      serviceLocator<ProjectViewModel>().enterSubZoneSelectionMode(subZone);
                                      break;
                                    case 'delete':
                                      _showDeleteSubZoneConfirmation(subZone);
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (
                                      BuildContext context,
                                    ) => <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'select_listening_areas_subzone',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.add,
                                              size: 16,
                                              color: context.colorScheme.textPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: 'Select Listening Areas',
                                              style: context.textTheme.bodySmall?.copyWith(
                                                color: context.colorScheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(height: 0),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Icon(
                                              LucideIcons.trash200,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: 'Delete Subzone',
                                              style: context.textTheme.bodySmall?.copyWith(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Expandable Content Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Show individual circuits in subzones
                    ..._buildSubZoneCircuits(subZone),

                    Container(
                      margin: const EdgeInsets.only(
                        left: 24,
                        top: 1,
                        right: 12,
                        bottom: 1,
                      ),
                      child: _buildListeningAreaSectionForZone(
                        subZoneId: subZone.id,
                      ),
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSubZoneConfirmation(SubZone subZone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subzone'),
          content: Text('Are you sure you want to delete "${subZone.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                serviceLocator<ProjectViewModel>().removeSubZone(
                  subZoneId: subZone.id,
                );
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCircuitConfirmation(CircuitModel circuit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Circuit'),
          content: Text('Are you sure you want to delete "${circuit.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                serviceLocator<ProjectViewModel>().removeCircuit(
                  circuitId: circuit.id,
                );
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameCircuitDialog(CircuitModel circuit) {
    final TextEditingController controller = TextEditingController(
      text: circuit.name,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Circuit'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Circuit Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String newName = controller.text.trim();
                if (newName.isNotEmpty && newName != circuit.name) {
                  final CircuitModel updatedCircuit = circuit.copyWith(
                    name: newName,
                  );
                  serviceLocator<ProjectViewModel>().updateCircuit(
                    circuit: updatedCircuit,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _addNewZone() {
    final Zone zone = Zone(name: 'Zone ${serviceLocator<ProjectViewModel>().zones.length + 1}');
    serviceLocator<ProjectViewModel>().addZone(zone: zone);

    // Automatically expand the newly added zone and its circuit section
    setState(() {
      _expandedZones.add(zone.id);
      _expandedCircuitSections.add('zone_${zone.id}');
    });
    serviceLocator<GuideShowCaseController>().completeStep(
      GuideShowCaseSteps.addZone,
    );
  }

  void _addSubZoneToZone(String zoneId) {
    final List<SubZone> existingSubZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zoneId);
    final SubZone newSubZone = SubZone(
      name: 'Subzone ${existingSubZones.length + 1}',
    );
    serviceLocator<ProjectViewModel>().addSubZone(subZone: newSubZone);
    serviceLocator<ProjectViewModel>().addSubZoneToZone(
      subZoneId: newSubZone.id,
      parentZoneId: zoneId,
    );

    // Get existing listening areas in the zone
    final List<ListeningArea> existingListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(
      zoneId: zoneId,
    );

    // Move all listening areas from the zone to the newly created subzone
    // The service layer should automatically handle circuit reassignment when areas are moved
    for (final ListeningArea listeningArea in existingListeningAreas) {
      serviceLocator<ProjectViewModel>().addListeningAreaToSubZone(
        areaId: listeningArea.id,
        subZoneId: newSubZone.id,
      );
    }

    // Automatically expand the newly added subzone and its circuit section
    setState(() {
      _expandedSubZones.add(newSubZone.id);
      _expandedCircuitSections.add('subzone_${newSubZone.id}');
    });
  }

  void _addListeningAreaToSubZone(String listeningAreaId, String subZoneId) {
    serviceLocator<ProjectViewModel>().addListeningAreaToSubZone(
      areaId: listeningAreaId,
      subZoneId: subZoneId,
    );
  }

  void _showDeleteConfirmation(Zone zone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Zone'),
          content: Text('Are you sure you want to delete "${zone.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                serviceLocator<ProjectViewModel>().removeZone(zoneId: zone.id);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Helper methods for speaker circuit management
  bool _isSpeakerInAnyCircuit(Speaker speaker) {
    final List<CircuitModel> allCircuits = serviceLocator<ProjectViewModel>().getAllCircuits();
    for (final CircuitModel circuit in allCircuits) {
      final List<HardwareComponent> hardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(
        circuitId: circuit.id,
      );
      if (hardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        return true;
      }
    }
    return false;
  }

  CircuitModel? _findCircuitForSpeaker(Speaker speaker) {
    final List<CircuitModel> allCircuits = serviceLocator<ProjectViewModel>().getAllCircuits();
    for (final CircuitModel circuit in allCircuits) {
      final List<HardwareComponent> hardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(
        circuitId: circuit.id,
      );
      if (hardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        return circuit;
      }
    }
    return null;
  }

  /// Helper methods for zone/subzone validation
  String? _getZoneIdForSpeaker(Speaker speaker) {
    // Find the listening area that contains this speaker
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getAllHardware();
    if (!allHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
      return null;
    }

    // Get the listening area for this speaker
    final List<ListeningArea> allListeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();
    for (final ListeningArea area in allListeningAreas) {
      final List<HardwareComponent> areaHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(
        listeningAreaId: area.id,
      );
      if (areaHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        // Find which zone this listening area belongs to
        final List<Zone> allZones = serviceLocator<ProjectViewModel>().getAllZones();
        for (final Zone zone in allZones) {
          final List<ListeningArea> zoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(
            zoneId: zone.id,
          );
          if (zoneAreas.any((ListeningArea la) => la.id == area.id)) {
            return zone.id;
          }
        }
        break;
      }
    }
    return null;
  }

  String? _getSubZoneIdForSpeaker(Speaker speaker) {
    // Find the listening area that contains this speaker
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getAllHardware();
    if (!allHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
      return null;
    }

    // Get the listening area for this speaker
    final List<ListeningArea> allListeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();
    for (final ListeningArea area in allListeningAreas) {
      final List<HardwareComponent> areaHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(
        listeningAreaId: area.id,
      );
      if (areaHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        // Find which subzone this listening area belongs to
        final List<SubZone> allSubZones = serviceLocator<ProjectViewModel>().getAllSubZones();
        for (final SubZone subZone in allSubZones) {
          final List<ListeningArea> subZoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(
            subZoneId: subZone.id,
          );
          if (subZoneAreas.any((ListeningArea la) => la.id == area.id)) {
            return subZone.id;
          }
        }
        break;
      }
    }
    return null;
  }

  String? _getZoneIdForCircuit(CircuitModel circuit) {
    final List<Zone> allZones = serviceLocator<ProjectViewModel>().getAllZones();
    for (final Zone zone in allZones) {
      final List<CircuitModel> zoneCircuits = serviceLocator<ProjectViewModel>().getCircuitsInZone(zone.id);
      if (zoneCircuits.any((CircuitModel c) => c.id == circuit.id)) {
        return zone.id;
      }
    }
    return null;
  }

  String? _getSubZoneIdForCircuit(CircuitModel circuit) {
    final List<SubZone> allSubZones = serviceLocator<ProjectViewModel>().getAllSubZones();
    for (final SubZone subZone in allSubZones) {
      final List<CircuitModel> subZoneCircuits = serviceLocator<ProjectViewModel>().getCircuitsInSubZone(
        subZoneId: subZone.id,
      );
      if (subZoneCircuits.any((CircuitModel c) => c.id == circuit.id)) {
        return subZone.id;
      }
    }
    return null;
  }

  bool _canSpeakerBeAddedToCircuit(Speaker speaker, CircuitModel circuit) {
    // Get the zone/subzone IDs for the speaker
    final String? speakerZoneId = _getZoneIdForSpeaker(speaker);
    final String? speakerSubZoneId = _getSubZoneIdForSpeaker(speaker);

    // Get the zone/subzone IDs for the circuit
    final String? circuitZoneId = _getZoneIdForCircuit(circuit);
    final String? circuitSubZoneId = _getSubZoneIdForCircuit(circuit);

    // Speaker can be added to a circuit if:
    // 1. Both speaker and circuit are in the same zone and both are not in any subzone, OR
    // 2. Both speaker and circuit are in the same subzone

    if (speakerSubZoneId != null && circuitSubZoneId != null) {
      // Both are in subzones - they must be the same subzone
      return speakerSubZoneId == circuitSubZoneId;
    } else if (speakerSubZoneId == null && circuitSubZoneId == null) {
      // Neither is in a subzone - they must be in the same zone
      return speakerZoneId == circuitZoneId;
    } else {
      // One is in a subzone, one is not - not allowed
      return false;
    }
  }

  void _addSpeakerToCircuit(Speaker speaker, String circuitId) {
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(
      hwId: speaker.id,
      circuitId: circuitId,
    );
  }

  void _removeSpeakerFromCircuit(Speaker speaker, CircuitModel circuit) {
    serviceLocator<ProjectViewModel>().removeHardwareFromCircuit(
      hwId: speaker.id,
      circuitId: circuit.id,
    );
  }

  List<CircuitModel> _getZoneCircuits(String zoneId) {
    return serviceLocator<ProjectViewModel>().getCircuitsInZone(zoneId);
  }

  void _showSpeakerAlreadyInCircuitError(
    Speaker speaker,
    CircuitModel circuit,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${speaker.name} is already in ${circuit.name}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSpeakerModelValidationError(
    Speaker speaker,
    Speaker existingSpeaker,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cannot mix ${speaker.name} with ${existingSpeaker.name} in the same circuit',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSpeakerZoneRestrictionError(Speaker speaker, CircuitModel circuit) {
    final String? speakerZoneId = _getZoneIdForSpeaker(speaker);
    final String? speakerSubZoneId = _getSubZoneIdForSpeaker(speaker);

    String errorMessage = 'Speaker can only be added to circuits in its own zone or subzone';

    if (speakerSubZoneId != null) {
      final SubZone? speakerSubZone = serviceLocator<ProjectViewModel>().getSubZone(subZoneId: speakerSubZoneId);
      errorMessage = 'Speaker is in subzone "${speakerSubZone?.name ?? 'Unknown'}" and can only be added to circuits in the same subzone';
    } else if (speakerZoneId != null) {
      final Zone? speakerZone = serviceLocator<ProjectViewModel>().getZone(
        zoneId: speakerZoneId,
      );
      errorMessage = 'Speaker is in zone "${speakerZone?.name ?? 'Unknown'}" and can only be added to circuits in the same zone (not in subzones)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showZoneHasCircuitsWarning(String zoneId) {
    final Zone? zone = serviceLocator<ProjectViewModel>().getZone(
      zoneId: zoneId,
    );
    final List<CircuitModel> circuits = _getZoneCircuits(zoneId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cannot Add Subzone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Zone "${zone?.name ?? 'Unknown'}" already has ${circuits.length} circuit(s).',
              ),
              const SizedBox(height: 12),
              const Text(
                'Zones with subzones cannot have direct circuits. You can:',
              ),
              const SizedBox(height: 8),
              const Text('• Delete the existing circuits first, or'),
              const Text('• Create subzones and move circuits there'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
