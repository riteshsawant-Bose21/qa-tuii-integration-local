import 'dart:ui';

import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/schematics/entity/schematic_hardware_component.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class SchematicHardwareTransformUseCase<T extends HardwareComponent> {
  List<SchematicHardwareComponent<T>> forModels(List<T> hardwareList) {
    return hardwareList.map((T hardware) => forModel(hardware)).toList();
  }

  SchematicHardwareComponent<T> forModel(T hardware) {
    return SchematicHardwareComponent<T>(
      hardware: hardware,
      locationName: getLocationName(hardware.locationEntity.listeningAreaId),
      zoneName: getZoneName(hardware.id),
      zoneColor: getZoneColor(hardware.id),
      equipmentLocationName: getEquipmentLocationForHardware(hardware.id),
    );
  }

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get location name from listeningAreaId
  String? getLocationName(String? listeningAreaId) {
    if (listeningAreaId == null) return null;

    final ListeningArea area = _projectViewModel.getListeningArea(areaId: listeningAreaId);

    return area.name;
  }

  /// Get zone data from hardwareId
  String? getZoneName(String hardwareId) {
    final ProjectViewModel projectViewModel = _projectViewModel;

    String? zoneName = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.name;
    if (zoneName?.trim().isEmpty ?? true) {
      zoneName = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId)?.name;
    }
    return zoneName;
  }

  Color? getZoneColor(String hardwareId) {
    final ProjectViewModel projectViewModel = _projectViewModel;
    Color? zoneColor = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.color;
    if (zoneColor == null) {
      final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId);
      if (subZone != null) zoneColor = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.color;
    }
    return zoneColor;
  }

  String? getEquipmentLocationForHardware(String hardwareId) {
    final ProjectViewModel projectViewModel = _projectViewModel;
    return projectViewModel.getEquipLocationForHardware(hardwareId: hardwareId)?.name;
  }
}
