import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import 'floor_properties.dart';
import 'hardware_properties.dart';
import 'surface_properties.dart';

class PropertiesSideBar extends StatefulWidget {
  final FloorModel? floor;
  final ListeningArea? surface;
  final HardwareComponent? hardwareComponent;
  final Function(FloorModel floorEntity) onFloorChanged;
  final Function(FloorModel floorEntity) onFloorDelete;
  final Function(HardwareComponent) onHardwareDelete;
  final Function(ListeningArea) onSurfaceDelete;

  const PropertiesSideBar({
    super.key,
    this.floor,
    this.surface,
    this.hardwareComponent,
    required this.onFloorChanged,
    required this.onFloorDelete,
    required this.onHardwareDelete,
    required this.onSurfaceDelete,
  });

  @override
  State<PropertiesSideBar> createState() => _PropertiesSideBarState();
}

class _PropertiesSideBarState extends State<PropertiesSideBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.floor == null) {
      return Container(padding: const EdgeInsets.all(12), color: Colors.white, child: const Text('No floor selected'));
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: <Widget>[
            if (widget.surface != null) ...<Widget>[
              SurfaceProperties(
                canvasSurface: widget.surface!,
                floorEntity: widget.floor!,
                onEntityChanged: (FloorModel floorEntity) {
                  widget.onFloorChanged(floorEntity);
                },
                onSurfaceDelete: (ListeningArea canvasSurface) {
                  widget.onSurfaceDelete(canvasSurface);
                },
              ),
            ] else if (widget.hardwareComponent != null) ...<Widget>[
              HardwareProperties(
                hardwareComponent: widget.hardwareComponent!,
                floorEntity: widget.floor!,
                onEntityChanged: (FloorModel floorEntity) {
                  widget.onFloorChanged(floorEntity);
                },
                onHardwareDelete: (HardwareComponent hardwareComponent) {
                  widget.onHardwareDelete(hardwareComponent);
                },
              ),
            ] else if (widget.floor != null) ...<Widget>[
              FloorPropertiesSidebar(
                entity: widget.floor!.floorPlan,
                floorEntity: widget.floor!,
                onEntityChanged: (FloorModel floorEntity) {
                  widget.onFloorChanged(floorEntity);
                },
                onFloorDelete: (FloorModel floorEntity) {
                  widget.onFloorDelete(floorEntity);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
