import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import 'zone_widget.dart';

class ZonesColumn extends StatefulWidget {
  final List<Zone> zones;
  final List<SourceSet> sourceSets;
  final List<Speaker> allSpeakers;
  final List<Source> sources;
  final void Function(Zone) onZoneUpdated;
  final void Function(Zone) onZoneDeleted;
  final void Function(Zone) onZoneAdded;
  final Function(Speaker) onSpeakerUpdated;
  final Function(Speaker) onSpeakerDeleted;
  final Function(Speaker) onSpeakerAdded;
  final Function(FloorModel) onFloorUpdated;
  final Function(FloorModel) onFloorAdded;
  final bool isControlMode;

  const ZonesColumn({
    super.key,
    required this.zones,
    required this.sourceSets,
    required this.onZoneAdded,
    required this.onZoneUpdated,
    required this.onZoneDeleted,
    required this.sources,
    required this.allSpeakers,
    required this.onSpeakerUpdated,
    required this.onSpeakerDeleted,
    required this.onSpeakerAdded,
    required this.onFloorUpdated,
    required this.onFloorAdded,
    required this.isControlMode,
  });

  @override
  State<ZonesColumn> createState() => _ZonesColumnState();
}

class _ZonesColumnState extends State<ZonesColumn> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(),
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.layers,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Zones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          if (!widget.isControlMode)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade700,
                size: 18,
              ),
              onPressed: _addZone,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    return widget.zones.isEmpty
        ? const Center(
          child: Text(
            'No zones created yet\nClick + to add a zone',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        )
        : ListView.builder(
          itemCount: widget.zones.length,
          itemBuilder: (BuildContext ctx, int i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ZoneWidget(
                zone: widget.zones[i],
                availableMixes: widget.sourceSets,
                sources: widget.sources,
                isControlMode: widget.isControlMode,
                onZoneUpdated: (Zone updated) {
                  widget.onZoneUpdated(updated);
                },
                onDelete: () {
                  widget.onZoneDeleted(widget.zones[i]);
                },
                zoneSpeakers: widget.allSpeakers.where((Speaker val) => val.locationEntity.zoneId == widget.zones[i].id).toList(),
                duplicateZone: (Zone zone) {
                  final Zone newZone = Zone(
                    name: '${zone.name} (Copy)',
                    mixIds: List<String>.from(zone.mixIds),
                  );
                  widget.onZoneAdded(newZone);
                },
                onSpeakerUpdated: (Speaker speakers) {
                  widget.onSpeakerUpdated(speakers);
                },
                onSpeakerDeleted: (Speaker speakers) {
                  widget.onSpeakerDeleted(speakers);
                },
                onSpeakerAdded: (Speaker speaker) {
                  widget.onSpeakerAdded(speaker);
                },
                onFloorUpdated: (FloorModel updatedFloor) {
                  widget.onFloorUpdated(updatedFloor);
                },
                onFloorAdded: (FloorModel newFloor) {
                  widget.onFloorAdded(newFloor);
                },
              ),
            );
          },
        );
  }

  void _addZone() {
    final Zone newZone = Zone(
      name: 'Zone ${widget.zones.length + 1}',
    );
    widget.onZoneAdded(newZone);
  }
}
