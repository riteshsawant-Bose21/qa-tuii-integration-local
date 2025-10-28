import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/constants/assets_constants.dart';
import '../../../../../core/widgets/color_selector_popup.dart';

class ZoneAndListeningAreaPanel extends StatefulWidget {
  const ZoneAndListeningAreaPanel({super.key});

  @override
  ZoneAndListeningAreaPanelState createState() => ZoneAndListeningAreaPanelState();
}

class ZoneAndListeningAreaPanelState extends State<ZoneAndListeningAreaPanel> with TickerProviderStateMixin {
  final Set<String> _expandedZones = <String>{};
  final Set<String> _expandedListeningAreas = <String>{};
  final Set<String> _expandedSubZones = <String>{};
  final Set<String> _expandedCircuitSections = <String>{};

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

  final GlobalKey _draggableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return SizedBox(
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
              _buildFooter(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              _addNewZone();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              '+ Add Zone',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;

    if (zones.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      constraints: const BoxConstraints(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 3),
          ...zones.map(
            (Zone zone) => Container(
              child: _buildZoneCard(zone),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
    );
  }

  Widget _buildZoneCard(Zone zone) {
    final List<ListeningArea> allListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zone.id);
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    // Get all listening areas that are in subzones
    final Set<String> listeningAreasInSubZones = <String>{};
    for (final SubZone subZone in subZones) {
      final List<ListeningArea> subZoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZone.id);
      listeningAreasInSubZones.addAll(subZoneAreas.map((ListeningArea area) => area.id));
    }

    // Filter out listening areas that are in subzones
    final List<ListeningArea> listeningAreas = allListeningAreas.where((ListeningArea area) => !listeningAreasInSubZones.contains(area.id)).toList();

    final bool isSelected = serviceLocator<ProjectViewModel>().isInZoneSelectionMode && serviceLocator<ProjectViewModel>().currentSelectedZoneId == zone.id;
    final bool isCollapsed = !_expandedZones.contains(zone.id);

    return DragTarget<ListeningArea>(
      onAcceptWithDetails: (DragTargetDetails<ListeningArea> details) {
        final ListeningArea listeningArea = details.data;
        serviceLocator<ProjectViewModel>().addListeningAreaToZone(listeningAreaId: listeningArea.id, zoneId: zone.id);
      },
      builder: (BuildContext context, List<ListeningArea?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        return Container(
          decoration:
              hasIncomingData
                  ? BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Zone Header
              _buildZoneHeader(zone, isSelected, isCollapsed),

              // Expandable Zone Content Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Sub Zones
                    _buildSubZonesSection(zone),

                    // Listening Areas
                    if (listeningAreas.isNotEmpty)
                      ...listeningAreas.map((ListeningArea area) => _buildListeningAreaItem(area, zone))
                    else if (serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id).isEmpty && _getZoneCircuits(zone.id).isEmpty)
                      _buildNoListeningAreasMessage(zone),

                    // Circuits directly under Zone
                    _buildZoneCircuitsSection(zone),
                    const SizedBox(height: 4),
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

  Widget _buildZoneHeader(Zone zone, bool isSelected, bool isCollapsed) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[200] : Colors.transparent,
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
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isCollapsed ? 0.0 : 0.25,
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildZoneIndicator(zone),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildZoneTitle(zone, isSelected),
                  ),
                  serviceLocator<ProjectViewModel>().currentSelectedZoneId != null
                      ? const SizedBox(
                        height: 24,
                      )
                      : SizedBox(
                        height: 24,
                        width: 24,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          position: PopupMenuPosition.under,
                          icon: const Icon(
                            Icons.more_vert,
                            size: 14,
                            color: Colors.grey,
                          ),
                          tooltip: 'Zone actions',
                          onSelected: (String value) {
                            switch (value) {
                              case 'add_circuit':
                                _addCircuitToZone(zone.id);
                                break;
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
                          itemBuilder:
                              (BuildContext context) => <PopupMenuEntry<String>>[
                                // const PopupMenuItem<String>(
                                //   value: 'add_circuit',
                                //   child: Row(
                                //     mainAxisSize: MainAxisSize.min,
                                //     children: <Widget>[
                                //       Icon(Icons.speaker_group, size: 16, color: Colors.blue),
                                //       SizedBox(width: 8),
                                //       Text('Add Circuit'),
                                //     ],
                                //   ),
                                // ),
                                const PopupMenuItem<String>(
                                  value: 'add_subzone',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.crop_free_sharp,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Add Subzone'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'add_listening_area',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.add, size: 16, color: Colors.black54),
                                      SizedBox(width: 8),
                                      Text('Select Listening Areas'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Zone', style: TextStyle(color: Colors.red)),
                                    ],
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
  }

  Widget _buildZoneIndicator(Zone zone) {
    return ColorSelector(
      enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
      selectedColor: hexToColor(zone.zoneColor),
      availableColors: Zone.zoneColors.map((String color) => hexToColor(color)).toList(),
      onColorChanged: (Color color) {
        serviceLocator<ProjectViewModel>().updateZone(zone: zone.copyWith(zoneColor: colorToHex(color)));
      },
      width: 18,
      height: 18,
      borderRadius: 4,
    );
    // return Container(
    //   width: 4,
    //   height: 24,
    //   decoration: BoxDecoration(
    //     color: zone.color,
    //     borderRadius: BorderRadius.circular(2),
    //   ),
    // );
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
      final String trimmedValue = controller.text.trim();
      if (trimmedValue.isNotEmpty && trimmedValue != zone.name) {
        final Zone updated = zone.copyWith(name: trimmedValue);
        serviceLocator<ProjectViewModel>().updateZone(zone: updated);
      } else if (trimmedValue.isEmpty) {
        controller.text = zone.name; // Revert to original name
      }
    }

    return Container(
      key: ValueKey<String>(zone.id),
      constraints: const BoxConstraints(),
      child: TextFormField(
        controller: controller,
        maxLength: 24,
        enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
        decoration: const InputDecoration(
          counterText: "",
          hintText: 'Zone Name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        scrollPadding: EdgeInsets.zero,
        maxLines: 1,
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
          saveValue();
        },
        onFieldSubmitted: (String v) {
          final String trimmedValue = v.trim();
          if (trimmedValue.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Zone name cannot be empty'),
                duration: Duration(seconds: 2),
              ),
            );
            controller.text = zone.name; // Revert to original name
            return;
          }
          saveValue();
        },
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
      child: TextFormField(
        controller: controller,
        maxLength: 24,
        enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
        decoration: const InputDecoration(
          counterText: "",
          hintText: 'SubZone Name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        scrollPadding: EdgeInsets.zero,
        maxLines: 1,
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
          saveValue();
        },
        onFieldSubmitted: (String v) {
          final String trimmedValue = v.trim();
          if (trimmedValue.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SubZone name cannot be empty'),
                duration: Duration(seconds: 2),
              ),
            );
            controller.text = subZone.name; // Revert to original name
            return;
          }
          saveValue();
        },
      ),
    );
  }

  // Removed _buildExpandIcon - zones now use inline arrow styling like other widgets

  // Removed _buildAddIcon and _buildDeleteButton - now using three-dot menus

  Widget _buildListeningAreaItem(ListeningArea area, Zone zone) {
    final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId == area.id;
    final bool isExpanded = _expandedListeningAreas.contains(area.id);
    final String floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id)?.name ?? '';

    // Get speakers for this listening area
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
    final List<Speaker> speakers = allHardware.whereType<Speaker>().toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Listening Area Header
        Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[200] : Colors.transparent,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 6, 16, 6), // Reduced padding
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(area.id);
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
              },
              child: Draggable<ListeningArea>(
                data: area,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: DraggingListItem(
                  dragKey: _draggableKey,
                  listeningArea: area.name,
                ),
                child: Row(
                  children: <Widget>[
                    // Expand/Collapse icon
                    InkWell(
                      onTap: () => _toggleListeningAreaExpansion(area.id),
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
                    // Listening area icon
                    SvgPicture.asset(
                      Assets.listeningAreaSvg,
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.black87,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FusionAppText(
                        text: "$floorName / ${area.name}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
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
              if (speakers.isNotEmpty) ...speakers.map((Speaker speaker) => _buildSpeakerItem(speaker)) else _buildNoSpeakersMessage(),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubZoneListeningAreaItem(ListeningArea area, SubZone subZone) {
    final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId == area.id;
    final bool isExpanded = _expandedListeningAreas.contains(area.id);
    final String floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id)?.name ?? '';

    // Get speakers for this listening area
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
    final List<Speaker> speakers = allHardware.whereType<Speaker>().toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Listening Area Header (indented under subzone)
        Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[200] : Colors.transparent,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(40, 6, 16, 6), // Extra indented for subzone
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(area.id);
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
              },
              child: Draggable<ListeningArea>(
                data: area,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: DraggingListItem(
                  dragKey: _draggableKey,
                  listeningArea: area.name,
                ),
                child: Row(
                  children: <Widget>[
                    // Expand/Collapse icon
                    InkWell(
                      onTap: () => _toggleListeningAreaExpansion(area.id),
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
                    // Listening area icon
                    SvgPicture.asset(
                      Assets.listeningAreaSvg,
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.black87,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FusionAppText(
                        text: "$floorName / ${area.name}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    // Option to remove from subzone
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                        position: PopupMenuPosition.under,
                        icon: const Icon(
                          Icons.more_vert,
                          size: 14,
                          color: Colors.grey,
                        ),
                        tooltip: 'Listening area actions',
                        onSelected: (String value) {
                          if (value == 'remove') {
                            serviceLocator<ProjectViewModel>().removeListeningAreaFromSubZone(areaId: area.id, subZoneId: subZone.id);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'remove',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Remove from Subzone', style: TextStyle(color: Colors.red)),
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
          ),
        ),

        // Expandable Speakers Section (same as zone listening areas but more indented)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (speakers.isNotEmpty) ...speakers.map((Speaker speaker) => _buildSubZoneSpeakerItem(speaker)) else _buildNoSpeakersInSubZoneMessage(),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSpeakerItem(Speaker speaker) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;
        final bool isInCircuit = _isSpeakerInAnyCircuit(speaker);
        final CircuitModel? assignedCircuit = _findCircuitForSpeaker(speaker);

        return Draggable<Speaker>(
          data: speaker,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isInCircuit ? Colors.red[50] : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: isInCircuit ? Border.all(color: Colors.red[200]!, width: 1) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    speaker.assetImagePath,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    speaker.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isInCircuit ? Colors.red[700] : Colors.black87,
                    ),
                  ),
                  if (isInCircuit) ...<Widget>[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.error_outline,
                      size: 10,
                      color: Colors.red[600],
                    ),
                  ],
                ],
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(left: 40, top: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[200] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(speaker.id);
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      speaker.assetImagePath,
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: speaker.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              color: isInCircuit ? Colors.grey[500] : Colors.grey[700],
                            ),
                          ),
                          if (isInCircuit && assignedCircuit != null)
                            FusionAppText(
                              text: 'In ${assignedCircuit.name}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w400,
                                color: Colors.blue[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isInCircuit)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 12,
                          position: PopupMenuPosition.under,
                          icon: const Icon(
                            Icons.link_off,
                            size: 12,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remove from circuit',
                          onSelected: (String value) {
                            if (value == 'remove' && assignedCircuit != null) {
                              _removeSpeakerFromCircuit(speaker, assignedCircuit);
                            }
                          },
                          itemBuilder:
                              (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'remove',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                                      SizedBox(width: 6),
                                      Text('Remove from Circuit', style: TextStyle(color: Colors.red)),
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
          ),
        );
      },
    );
  }

  Widget _buildSubZoneSpeakerItem(Speaker speaker) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;
        final bool isInCircuit = _isSpeakerInAnyCircuit(speaker);
        final CircuitModel? assignedCircuit = _findCircuitForSpeaker(speaker);

        return Draggable<Speaker>(
          data: speaker,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isInCircuit ? Colors.red[50] : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: isInCircuit ? Border.all(color: Colors.red[200]!, width: 1) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    speaker.assetImagePath,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    speaker.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isInCircuit ? Colors.red[700] : Colors.black87,
                    ),
                  ),
                  if (isInCircuit) ...<Widget>[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.error_outline,
                      size: 10,
                      color: Colors.red[600],
                    ),
                  ],
                ],
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(left: 56, top: 2), // Extra indented for subzone
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[200] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(speaker.id);
                serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      speaker.assetImagePath,
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: speaker.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              color: isInCircuit ? Colors.grey[500] : Colors.grey[700],
                            ),
                          ),
                          if (isInCircuit && assignedCircuit != null)
                            FusionAppText(
                              text: 'In ${assignedCircuit.name}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w400,
                                color: Colors.blue[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isInCircuit)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 12,
                          position: PopupMenuPosition.under,
                          icon: const Icon(
                            Icons.link_off,
                            size: 12,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remove from circuit',
                          onSelected: (String value) {
                            if (value == 'remove' && assignedCircuit != null) {
                              _removeSpeakerFromCircuit(speaker, assignedCircuit);
                            }
                          },
                          itemBuilder:
                              (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'remove',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                                      SizedBox(width: 6),
                                      Text('Remove from Circuit', style: TextStyle(color: Colors.red)),
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
          ),
        );
      },
    );
  }

  Widget _buildNoSpeakersMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'No speakers',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSpeakersInSubZoneMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'No speakers',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoZoneCircuitsMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'Drag speakers to create a circuit',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubZoneCircuitsMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'Drag speakers to create a circuit',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubZonesSection(Zone zone) {
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);

    if (subZones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: subZones.map((SubZone subZone) => _buildSubZoneItem(subZone, zone)).toList(),
    );
  }

  Widget _buildSubZoneItem(SubZone subZone, Zone zone) {
    final bool isExpanded = _expandedSubZones.contains(subZone.id);
    final List<ListeningArea> subZoneListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZone.id);

    return DragTarget<ListeningArea>(
      onAcceptWithDetails: (DragTargetDetails<ListeningArea> details) {
        final ListeningArea listeningArea = details.data;
        _addListeningAreaToSubZone(listeningArea.id, subZone.id);
      },
      builder: (BuildContext context, List<ListeningArea?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        return Container(
          decoration:
              hasIncomingData
                  ? BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Subzone Header
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 6, 16, 6),
                  child: InkWell(
                    onTap: () => _toggleSubZoneExpansion(subZone.id),
                    child: Row(
                      children: <Widget>[
                        // Expand/Collapse icon
                        InkWell(
                          onTap: () => _toggleSubZoneExpansion(subZone.id),
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
                        // Subzone icon
                        Icon(
                          Icons.crop_free_sharp,
                          size: 14,
                          color: zone.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSubZoneTitle(subZone, false),
                        ),
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 14,
                            position: PopupMenuPosition.under,
                            icon: const Icon(
                              Icons.more_vert,
                              size: 14,
                              color: Colors.grey,
                            ),
                            tooltip: 'Subzone actions',
                            onSelected: (String value) {
                              switch (value) {
                                case 'add_circuit':
                                  _addCircuitToSubZone(subZone.id);
                                  break;
                                case 'delete':
                                  _showDeleteSubZoneConfirmation(subZone);
                                  break;
                              }
                            },
                            itemBuilder:
                                (BuildContext context) => <PopupMenuEntry<String>>[
                                  // const PopupMenuItem<String>(
                                  //   value: 'add_circuit',
                                  //   child: Row(
                                  //     mainAxisSize: MainAxisSize.min,
                                  //     children: <Widget>[
                                  //       Icon(Icons.speaker_group, size: 16, color: Colors.blue),
                                  //       SizedBox(width: 8),
                                  //       Text('Add Circuit'),
                                  //     ],
                                  //   ),
                                  // ),
                                  // const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete Subzone', style: TextStyle(color: Colors.red)),
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
              ),

              // Expandable Content Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Show listening areas in subzone
                    if (subZoneListeningAreas.isNotEmpty) ...subZoneListeningAreas.map((ListeningArea area) => _buildSubZoneListeningAreaItem(area, subZone)),
                    // Always show circuits section
                    _buildSubZoneCircuitsSection(subZone),
                    // Show message if listening areas are empty
                    if (subZoneListeningAreas.isEmpty) _buildNoListeningAreaSubzoneMessage(),
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

  Widget _buildNoListeningAreaSubzoneMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FusionAppText(
              text: 'No listening areas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoListeningAreasMessage(Zone zone) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 12),
              FusionAppText(
                text: 'Select or drag listening areas',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              serviceLocator<ProjectViewModel>().enterZoneSelectionMode(zone);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.add_circle_outline,
                  size: 12,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Listening Areas',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Three-dot menu widgets now embedded in headers for hover detection

  // All menu methods now embedded in headers for better hover detection

  /// Dialog methods for various operations

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
                serviceLocator<ProjectViewModel>().removeSubZone(subZoneId: subZone.id);
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
                serviceLocator<ProjectViewModel>().removeCircuit(circuitId: circuit.id);
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
    final TextEditingController controller = TextEditingController(text: circuit.name);

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
                  final CircuitModel updatedCircuit = circuit.copyWith(name: newName);
                  serviceLocator<ProjectViewModel>().updateCircuit(circuit: updatedCircuit);
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

  /// Helper methods for circuit management

  // Removed _buildAddCircuitIcon - now using three-dot menus

  void _addCircuitToZone(String zoneId) {
    final CircuitModel newCircuit = CircuitModel(
      name: 'Circuit ${_getZoneCircuits(zoneId).length + 1}',
    );
    serviceLocator<ProjectViewModel>().addCircuit(circuit: newCircuit);
    serviceLocator<ProjectViewModel>().addCircuitToZone(zoneId: zoneId, circuitId: newCircuit.id);
  }

  void _addCircuitToSubZone(String subZoneId) {
    final CircuitModel newCircuit = CircuitModel(
      name: 'Circuit ${serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZoneId).length + 1}',
    );
    serviceLocator<ProjectViewModel>().addCircuit(circuit: newCircuit);
    serviceLocator<ProjectViewModel>().addCircuitToSubZone(subZoneId: subZoneId, circuitId: newCircuit.id);
  }

  void _addSpeakerToCircuit(Speaker speaker, String circuitId) {
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitId);
  }

  void _removeSpeakerFromCircuit(Speaker speaker, CircuitModel circuit) {
    serviceLocator<ProjectViewModel>().removeHardwareFromCircuit(hwId: speaker.id, circuitId: circuit.id);
  }

  List<CircuitModel> _getZoneCircuits(String zoneId) {
    return serviceLocator<ProjectViewModel>().getCircuitsInZone(zoneId);
  }

  void _showSpeakerAlreadyInCircuitError(Speaker speaker, CircuitModel circuit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${speaker.name} is already in ${circuit.name}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSpeakerModelValidationError(Speaker speaker, Speaker existingSpeaker) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot mix ${speaker.name} with ${existingSpeaker.name} in the same circuit'),
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
      final Zone? speakerZone = serviceLocator<ProjectViewModel>().getZone(zoneId: speakerZoneId);
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

  Widget _buildZoneCircuitsSection(Zone zone) {
    final List<CircuitModel> circuits = _getZoneCircuits(zone.id);

    return DragTarget<Speaker>(
      onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in any circuit
        if (_isSpeakerInAnyCircuit(details.data)) return false;

        // Check if speaker can be added to this zone (not in a subzone)
        final String? speakerZoneId = _getZoneIdForSpeaker(details.data);
        final String? speakerSubZoneId = _getSubZoneIdForSpeaker(details.data);

        // Speaker can only be added to zone circuit if it's in the same zone and not in any subzone
        return speakerZoneId == zone.id && speakerSubZoneId == null;
      },
      onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        _createNewCircuitWithSpeaker(details.data, zone.id, null);
      },
      builder: (BuildContext context, List<Speaker?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        bool canAccept = false;
        if (hasIncomingData && candidateItems.first != null) {
          final Speaker candidateSpeaker = candidateItems.first!;
          final String? speakerZoneId = _getZoneIdForSpeaker(candidateSpeaker);
          final String? speakerSubZoneId = _getSubZoneIdForSpeaker(candidateSpeaker);

          canAccept = !_isSpeakerInAnyCircuit(candidateSpeaker) && speakerZoneId == zone.id && speakerSubZoneId == null;
        }

        final String circuitSectionId = 'zone_${zone.id}';
        final bool isExpanded = _expandedCircuitSections.contains(circuitSectionId);

        return Container(
          decoration:
              hasIncomingData
                  ? BoxDecoration(
                    color: canAccept ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Circuits Section Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
                child: InkWell(
                  onTap: () => _toggleCircuitSectionExpansion(circuitSectionId),
                  child: Row(
                    children: <Widget>[
                      // Expand/Collapse icon
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.speaker_group,
                        size: 14,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${zone.name} circuits',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable Circuit Items
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (circuits.isNotEmpty) ...circuits.map((CircuitModel circuit) => _buildSimpleCircuitItem(circuit)) else _buildNoZoneCircuitsMessage(),
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

  Widget _buildSubZoneCircuitsSection(SubZone subZone) {
    final List<CircuitModel> circuits = serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZone.id);

    return DragTarget<Speaker>(
      onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in any circuit
        if (_isSpeakerInAnyCircuit(details.data)) return false;

        // Check if speaker can be added to this subzone
        final String? speakerSubZoneId = _getSubZoneIdForSpeaker(details.data);

        // Speaker can only be added to subzone circuit if it's in the same subzone
        return speakerSubZoneId == subZone.id;
      },
      onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Get the parent zone for this subzone
        final String? parentZoneId = _getParentZoneIdForSubZone(subZone.id);
        if (parentZoneId != null) {
          _createNewCircuitWithSpeaker(details.data, parentZoneId, subZone.id);
        }
      },
      builder: (BuildContext context, List<Speaker?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        bool canAccept = false;
        if (hasIncomingData && candidateItems.first != null) {
          final Speaker candidateSpeaker = candidateItems.first!;
          final String? speakerSubZoneId = _getSubZoneIdForSpeaker(candidateSpeaker);

          canAccept = !_isSpeakerInAnyCircuit(candidateSpeaker) && speakerSubZoneId == subZone.id;
        }

        final String circuitSectionId = 'subzone_${subZone.id}';
        final bool isExpanded = _expandedCircuitSections.contains(circuitSectionId);

        return Container(
          decoration:
              hasIncomingData
                  ? BoxDecoration(
                    color: canAccept ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Circuits Section Header
              Container(
                padding: const EdgeInsets.fromLTRB(40, 8, 16, 4),
                child: InkWell(
                  onTap: () => _toggleCircuitSectionExpansion(circuitSectionId),
                  child: Row(
                    children: <Widget>[
                      // Expand/Collapse icon
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.speaker_group,
                        size: 14,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${subZone.name} circuits',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable Circuit Items
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (circuits.isNotEmpty)
                      ...circuits.map((CircuitModel circuit) => _buildSimpleCircuitItem(circuit, isSubZone: true))
                    else
                      _buildNoSubZoneCircuitsMessage(),
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

  Widget _buildSimpleCircuitItem(CircuitModel circuit, {bool isSubZone = false}) {
    final List<HardwareComponent> circuitHardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(circuitId: circuit.id);
    final List<Speaker> circuitSpeakers = circuitHardware.whereType<Speaker>().toList();
    final double leftPadding = isSubZone ? 56.0 : 40.0;

    return DragTarget<Speaker>(
      onWillAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in any circuit
        if (_isSpeakerInAnyCircuit(details.data)) return false;

        // Check if speaker is already in this circuit
        if (circuitSpeakers.any((Speaker s) => s.id == details.data.id)) return false;

        // Check zone/subzone restrictions
        if (!_canSpeakerBeAddedToCircuit(details.data, circuit)) return false;

        // Only accept if circuit is empty or speaker is same model (SKU) as existing speakers
        if (circuitSpeakers.isEmpty) return true;
        return circuitSpeakers.first.speakerSKU == details.data.speakerSKU;
      },
      onAcceptWithDetails: (DragTargetDetails<Speaker> details) {
        // Check if speaker is already in another circuit
        final CircuitModel? existingCircuit = _findCircuitForSpeaker(details.data);
        if (existingCircuit != null) {
          _showSpeakerAlreadyInCircuitError(details.data, existingCircuit);
          return;
        }

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

        _addSpeakerToCircuit(details.data, circuit.id);
      },
      builder: (BuildContext context, List<Speaker?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        bool canAccept = false;
        if (hasIncomingData && candidateItems.first != null) {
          final Speaker candidateSpeaker = candidateItems.first!;

          // Can accept if:
          // 1. Speaker is not already in any circuit, AND
          // 2. Speaker is not already in this circuit, AND
          // 3. Speaker is in the same zone/subzone as the circuit, AND
          // 4. Circuit is empty OR speaker model matches existing speakers
          canAccept =
              !_isSpeakerInAnyCircuit(candidateSpeaker) &&
              !circuitSpeakers.any((Speaker s) => s.id == candidateSpeaker.id) &&
              _canSpeakerBeAddedToCircuit(candidateSpeaker, circuit) &&
              (circuitSpeakers.isEmpty || circuitSpeakers.first.speakerSKU == candidateSpeaker.speakerSKU);
        }

        return Container(
          margin: EdgeInsets.only(left: leftPadding, top: 2),
          decoration: BoxDecoration(
            color: hasIncomingData ? (canAccept ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () {
              // Optional: Handle circuit selection
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  // Circuit icon - show actual speaker image if circuit has speakers
                  if (circuitSpeakers.isNotEmpty)
                    Image.asset(
                      circuitSpeakers.first.assetImagePath,
                      width: 14,
                      height: 14,
                    )
                  else
                    const Icon(
                      Icons.speaker_group,
                      size: 12,
                      color: Colors.black87,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FusionAppText(
                          text: circuit.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        if (circuitSpeakers.isNotEmpty)
                          FusionAppText(
                            text: '${circuitSpeakers.first.name} (${circuitSpeakers.length}x)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Circuit actions menu
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
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
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'rename',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.edit, size: 14, color: Colors.black54),
                                  SizedBox(width: 6),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                  SizedBox(width: 6),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
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
    );
  }

  void _addNewZone() {
    final Zone zone = Zone(
      name: 'Zone ${serviceLocator<ProjectViewModel>().zones.length + 1}',
    );
    serviceLocator<ProjectViewModel>().addZone(zone: zone);

    // Automatically expand the newly added zone and its circuit section
    setState(() {
      _expandedZones.add(zone.id);
      _expandedCircuitSections.add('zone_${zone.id}');
    });
  }

  void _addSubZoneToZone(String zoneId) {
    final List<SubZone> existingSubZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zoneId);
    final SubZone newSubZone = SubZone(
      name: 'Subzone ${existingSubZones.length + 1}',
    );
    serviceLocator<ProjectViewModel>().addSubZone(subZone: newSubZone);
    serviceLocator<ProjectViewModel>().addSubZoneToZone(subZoneId: newSubZone.id, parentZoneId: zoneId);

    // Automatically expand the newly added subzone and its circuit section
    setState(() {
      _expandedSubZones.add(newSubZone.id);
      _expandedCircuitSections.add('subzone_${newSubZone.id}');
    });
  }

  void _addListeningAreaToSubZone(String listeningAreaId, String subZoneId) {
    serviceLocator<ProjectViewModel>().addListeningAreaToSubZone(areaId: listeningAreaId, subZoneId: subZoneId);
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

  void _updateExpandedStates() {
    // Add any new zones to the expanded set
    final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;
    for (final Zone zone in zones) {
      if (!_expandedZones.contains(zone.id)) {
        _expandedZones.add(zone.id);
      }

      // Add any new zone circuit sections to the expanded set
      if (!_expandedCircuitSections.contains('zone_${zone.id}')) {
        _expandedCircuitSections.add('zone_${zone.id}');
      }

      // Add any new subzones to the expanded set
      final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
      for (final SubZone subZone in subZones) {
        if (!_expandedSubZones.contains(subZone.id)) {
          _expandedSubZones.add(subZone.id);
        }

        // Add any new subzone circuit sections to the expanded set
        if (!_expandedCircuitSections.contains('subzone_${subZone.id}')) {
          _expandedCircuitSections.add('subzone_${subZone.id}');
        }
      }
    }
  }

  /// Helper methods for speaker circuit management
  bool _isSpeakerInAnyCircuit(Speaker speaker) {
    final List<CircuitModel> allCircuits = serviceLocator<ProjectViewModel>().getAllCircuits();
    for (final CircuitModel circuit in allCircuits) {
      final List<HardwareComponent> hardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(circuitId: circuit.id);
      if (hardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        return true;
      }
    }
    return false;
  }

  CircuitModel? _findCircuitForSpeaker(Speaker speaker) {
    final List<CircuitModel> allCircuits = serviceLocator<ProjectViewModel>().getAllCircuits();
    for (final CircuitModel circuit in allCircuits) {
      final List<HardwareComponent> hardware = serviceLocator<ProjectViewModel>().getHardwareForCircuit(circuitId: circuit.id);
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
      final List<HardwareComponent> areaHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
      if (areaHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        // Find which zone this listening area belongs to
        final List<Zone> allZones = serviceLocator<ProjectViewModel>().getAllZones();
        for (final Zone zone in allZones) {
          final List<ListeningArea> zoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zone.id);
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
      final List<HardwareComponent> areaHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
      if (areaHardware.any((HardwareComponent hw) => hw.id == speaker.id)) {
        // Find which subzone this listening area belongs to
        final List<SubZone> allSubZones = serviceLocator<ProjectViewModel>().getAllSubZones();
        for (final SubZone subZone in allSubZones) {
          final List<ListeningArea> subZoneAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZone.id);
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
      final List<CircuitModel> subZoneCircuits = serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZone.id);
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

  /// Create a new circuit with the given speaker
  void _createNewCircuitWithSpeaker(Speaker speaker, String zoneId, String? subZoneId) {
    // Create a new circuit
    final List<CircuitModel> existingCircuits =
        subZoneId != null ? serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZoneId) : _getZoneCircuits(zoneId);

    final CircuitModel newCircuit = CircuitModel(
      name: 'Circuit ${existingCircuits.length + 1}',
    );

    // Add the circuit to the project
    serviceLocator<ProjectViewModel>().addCircuit(circuit: newCircuit);

    // Add the circuit to the appropriate zone or subzone
    if (subZoneId != null) {
      serviceLocator<ProjectViewModel>().addCircuitToSubZone(subZoneId: subZoneId, circuitId: newCircuit.id);
    } else {
      serviceLocator<ProjectViewModel>().addCircuitToZone(zoneId: zoneId, circuitId: newCircuit.id);
    }

    // Add the speaker to the circuit
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: newCircuit.id);
  }

  /// Find the parent zone ID for a given subzone
  String? _getParentZoneIdForSubZone(String subZoneId) {
    final List<Zone> allZones = serviceLocator<ProjectViewModel>().getAllZones();
    for (final Zone zone in allZones) {
      final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zone.id);
      if (subZones.any((SubZone sz) => sz.id == subZoneId)) {
        return zone.id;
      }
    }
    return null;
  }
}

class DraggingListItem extends StatelessWidget {
  const DraggingListItem({
    super.key,
    required this.dragKey,
    required this.listeningArea,
  });

  final GlobalKey dragKey;
  final String listeningArea;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              Assets.listeningAreaSvg,
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Colors.black87,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              listeningArea,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
