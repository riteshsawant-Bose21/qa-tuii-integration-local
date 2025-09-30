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

  @override
  void initState() {
    super.initState();
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Zone zone) {
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zone.id);
    final bool isSelected = serviceLocator<ProjectViewModel>().isInZoneSelectionMode && serviceLocator<ProjectViewModel>().currentSelectedZoneId == zone.id;
    final bool isExpanded = _expandedZones.contains(zone.id);

    return DragTarget<ListeningArea>(
      onAcceptWithDetails: (DragTargetDetails<ListeningArea> details) {
        final ListeningArea listeningArea = details.data;
        serviceLocator<ProjectViewModel>().addListeningAreaToZone(listeningArea.id, zone.id);
      },
      builder: (BuildContext context, List<ListeningArea?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && candidateItems.first != null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: Stack(
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Zone Header (always visible)
                  InkWell(
                    onTap: () => _toggleZoneExpansion(zone.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[200] : Colors.white,
                        // border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                        builder: (BuildContext context, ProjectViewModelState state) {
                          return Row(
                            children: <Widget>[
                              _buildZoneIndicator(zone),
                              const SizedBox(width: 8),

                              Expanded(
                                child: _buildZoneTitle(zone, isSelected),
                              ),
                              if (serviceLocator<ProjectViewModel>().currentSelectedZoneId == null) ...<Widget>[
                                InkWell(
                                  onTap: () => serviceLocator<ProjectViewModel>().enterZoneSelectionMode(zone),
                                  child: _buildAddIcon(),
                                ),
                                const SizedBox(width: 8),
                                _buildDeleteButton(zone),
                              ],

                              const SizedBox(width: 8),
                              _buildExpandIcon(isExpanded),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Expandable Listening Areas Section
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Listening Areas or Empty Message
                          if (listeningAreas.isNotEmpty)
                            ...listeningAreas.map((ListeningArea area) => _buildListeningAreaItem(area, zone))
                          else
                            _buildNoListeningAreasMessage(),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Drop overlay that covers the entire column
              if (hasIncomingData)
                Positioned.fill(
                  child: Container(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneIndicator(Zone zone) {
    return ColorSelector(
      enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
      selectedColor: hexToColor(zone.zoneColor),
      availableColors: Zone.zoneColors.map((String color) => hexToColor(color)).toList(),
      onColorChanged: (Color color) {
        serviceLocator<ProjectViewModel>().updateZone(zone.copyWith(zoneColor: colorToHex(color)));
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
    return Container(
      key: ValueKey<String>(zone.id),
      constraints: const BoxConstraints(),
      child: TextFormField(
        initialValue: zone.name,
        enabled: serviceLocator<ProjectViewModel>().currentSelectedZoneId == null,
        decoration: const InputDecoration(
          hintText: 'Zone Name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        scrollPadding: EdgeInsets.zero,

        maxLines: 1,
        onFieldSubmitted: (String v) {
          final String trimmedValue = v.trim();
          if (trimmedValue.isEmpty) {
            // Show a snackbar to inform user that zone name cannot be empty
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Zone name cannot be empty'),
                duration: Duration(seconds: 2),
              ),
            );
            // Don't update zone name and revert to previous name
            return;
          }
          final Zone updated = zone.copyWith(name: trimmedValue);
          serviceLocator<ProjectViewModel>().updateZone(updated);
        },
      ),
    );
  }

  Widget _buildExpandIcon(bool isExpanded) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 200),
      turns: isExpanded ? 0.5 : 0.0,
      child: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildAddIcon() {
    return const Icon(
      Icons.add,
      size: 18,
      color: Colors.black54,
    );
  }

  Widget _buildDeleteButton(Zone zone) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _showDeleteConfirmation(zone),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.delete_outline,
            size: 16,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildListeningAreaItem(ListeningArea area, Zone zone) {
    final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId == area.id;

    final String floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(area.id)?.name ?? '';

    return Draggable<ListeningArea>(
      data: area,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: DraggingListItem(
        dragKey: _draggableKey,
        listeningArea: area.name,
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[200] : Colors.transparent,
        ),
        child: ListTile(
          dense: true,

          leading: SvgPicture.asset(
            Assets.listeningAreaSvg,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
          ),
          title: FusionAppText(
            text: "$floorName / ${area.name}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          trailing:
              isSelected
                  ? Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                  )
                  : null,
          onTap: () => serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(area.id),
        ),
      ),
    );
  }

  Widget _buildNoListeningAreasMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FusionAppText(
                  text: 'No listening areas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
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

  void _addNewZone() {
    final Zone zone = Zone(
      name: 'Zone ${serviceLocator<ProjectViewModel>().zones.length + 1}',
    );
    serviceLocator<ProjectViewModel>().addZone(zone);
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
                serviceLocator<ProjectViewModel>().removeZone(zone.id);
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
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: SizedBox(
        key: dragKey,
        height: 50,
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.volume_up,
              size: 24,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              listeningArea,

              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
