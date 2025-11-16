import 'package:fusion_lib/fusion_lib.dart';

extension ZoneFunctionService on ProjectService {
  void addFunctionToZone({required ZoneFunctions function, required String zoneId}) {
    zoneFunctions.add(function.id, function);

    //unlink previous function
    final currentZoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (currentZoneFunctions.isNotEmpty) {
      //remove old function
      removeFunction(functionId: currentZoneFunctions.first);
    }

    relationships.link(RelationshipType.zoneFunctions, zoneId, function.id);
  }

  void removeFunction({required String functionId}) {
    zoneFunctions.remove(functionId);
    relationships.removeAllRelationships(functionId);
  }

  ZoneFunctions? getZoneFunction({required String zoneId}) {
    final zoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (zoneFunctions.isEmpty) {
      return null;
    }
    return getZoneFunctionById(functionId: zoneFunctions.first);
  }

  ZoneFunctions? getZoneFunctionById({required String functionId}) {
    return zoneFunctions.get(functionId);
  }

  void updateZoneGain({required String zoneId, required double gain}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(gain: gain);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(gain: gain);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  void muteZone({required String zoneId, required bool isMuted}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(muted: isMuted);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(muted: isMuted);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  void updateSourceGain({required String sourceId, required double gain}) {
    if (hardware.exists(sourceId)) {
      final source = hardware.get(sourceId)! as Source;
      final updatedSource = source.copyWith(gain: gain);
      hardware.add(sourceId, updatedSource);
    }
  }

  void muteSource({required String sourceId, required bool isMuted}) {
    if (hardware.exists(sourceId)) {
      final source = hardware.get(sourceId)! as Source;
      final updatedSource = source.copyWith(muted: isMuted);
      hardware.add(sourceId, updatedSource);
    }
  }

  void updateSourceMix({
    required String sourceId,
    required double leftMix,
    required double rightMix,
  }) {
    if (hardware.exists(sourceId)) {
      final source = hardware.get(sourceId)! as Source;
      final updatedSource = source.copyWith(
        leftMix: leftMix,
        rightMix: rightMix,
      );
      hardware.add(sourceId, updatedSource);
    }
  }
}
