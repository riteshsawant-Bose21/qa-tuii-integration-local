import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import 'zone_panel_item_widget.dart';

class ZonesPanel extends StatefulWidget {
  final List<Zone> zones;
  final void Function(Zone) onZoneUpdated;
  final void Function(Zone) onZoneDeleted;
  final void Function(Zone) onZoneAdded;
  final void Function(Zone) onRequestListeningAreaSelection;
  final List<ListeningArea> Function(String) getZoneListeningAreas;
  final FloorModel Function(String) getListeningAreaFloor;
  final VoidCallback? onCancelSelection;
  final Function(String) onAreaRemovedFromZone;

  const ZonesPanel({
    super.key,
    required this.zones,
    required this.onZoneAdded,
    required this.onZoneUpdated,
    required this.onZoneDeleted,
    required this.onRequestListeningAreaSelection,
    required this.getZoneListeningAreas,
    required this.getListeningAreaFloor,
    this.onCancelSelection,
    required this.onAreaRemovedFromZone,
  });

  @override
  State<ZonesPanel> createState() => _ZonesPanelState();
}

class _ZonesPanelState extends State<ZonesPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Zone',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _addZone,
                ),
              ],
            ),
          ),

          widget.zones.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Click + to add a zone',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    widget.zones
                        .map(
                          (Zone zone) => ZonePanelWidget(
                            zone: zone,
                            zoneListeningAreas: widget.getZoneListeningAreas(zone.id),
                            onZoneChanged: (Zone updated) {
                              widget.onZoneUpdated(updated);
                            },
                            onDelete: () {
                              widget.onZoneDeleted(zone);
                            },
                            onAddListeningAreas: widget.onRequestListeningAreaSelection,
                            getListeningAreaFloor: widget.getListeningAreaFloor,
                            onAreaRemovedFromZone: (String removedAreaId) {
                              widget.onAreaRemovedFromZone(removedAreaId);
                            },
                          ),
                        )
                        .toList(),
              ),
        ],
      ),
    );
  }

  void _addZone() async {
    final Zone newZone = Zone(
      name: 'Zone ${widget.zones.length + 1}',
    );
    widget.onZoneAdded(newZone);
  }
}
